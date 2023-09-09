---
title: Enhancing your Rails app with SQLite
subtitle: Branch-specific databases
date: 2023-09-06
tags:
  - code
  - ruby
  - rails
  - sqlite
---

This is the first in a collection of posts where I want to highlight ways we can enhance our [Ruby on Rails](https://rubyonrails.org) applications. Specifically, in this first series, I want to dig into the ways that we can take advantage of and empower using [SQLite](https://www.sqlite.org/index.html) as the database engine for our Rails applications. In this inaugural post, let's dig into how using SQLite as our database engine opens up powerful new possibilities for our local development workflow; specifically, allowing us to have and use **branch-specific databases**.

<!--/summary-->

- - -

There has been a [surge](https://tailscale.com/blog/database-for-2022/) [of](https://pretalx.com/djangocon-europe-2023/talk/J98ZTN/#:~:text=SQLite%20is%20a%20popular%20option,running%20your%20app%20in%20production.) [interest](https://news.ycombinator.com/item?id=20367679) [in](https://litestream.io/blog/why-i-built-litestream/#moving-to-sqlite) using SQLite in production for web applications in the last few years. I readily confess that I am fully onboard as well. SQLite removes network latency, simplifies operations, and makes automated testing against your production stack easy.

Over the course of this series, I want to lay out some of the key tweaks we can make to our Rails applications to make working with SQLite more powerful and pleasurable. To start, I want to focus on a developer experience (<abbr>DX</abbr>) improvement for local development.

As anyone who has worked on a Rails application within a team of developers knows, managing your database schema can be tricky. Each developer's branches might include some migrations, which update the schema, but locally you only have the one single development database. Switching between branches becomes a pain, running migrations becomes a pain, and sometimes bugs sneak into production as schema changes are merged that shouldn't have been a part of that release.

One of my favorite features from [PlanetScale](https://planetscale.com) is their [branching](https://planetscale.com/docs/onboarding/branching-and-deploy-requests) feature:

> Branches are copies of your database schema that live in a completely separate environment from each other. Making changes in one branch does not affect other branches until you merge them, just like you manage code branches in your projects.

This is lovely, and it solves the pain points laid out above. However, this isn't quite _perfect_ in my opinion. Because we now have two different kinds of "branches" for our app. We have our Git branches, which isolate our code (including migrations), and our database branches, which isolate our schema. Having two separate branches now creates syncing issues. How do Git branches and database branches relate? How do we tie git branch merging to database branch merging to production deployment? etc.

This is a necessary trade-off that PlanetScale needs to make, because their serverless database platform can't be deeply integrated with every single user's codebase. However, as Rails developers using SQLite, we have unique opportunities available to us.

- - -

Let's describe our ideal scenario, and then dig into how to implement it. What we want is to have a single branch (a Git branch) which isolates _both_ our code and our schema. We want switching Git branches to **automatically** switch schema branches. We want production deployment driven by Git branch merging that also **automatically** ensures a predictable and stable production schema. Sounds nice, doesn't it? Well, luckily for us, Rails and SQLite make such a setup remarkably easy to create.

Let's start with our last feature, as this is something that Rails gives us, regardless of our database engine. This feature is precisely the value of our `/migrations` directory and the `/db/schema.rb` or `/db/structure.sql` file. By integrating our database schema management into our Rails application codebase, and ensuring that all schema changes are implemented via Rails migrations, we can bind our production schema to simple Git branch merging, while also ensuring that our production schema is predictable and stable.

To be honest, the other two features are also possible with any of Rails' supported database adapters, but SQLite fits most nicely with the approach. And the approach is simple. Fundamentally, all we need to do is tell Rails to use a dynamic database name, tied to the Git branch name, for local development. Rails makes this easy through the `/config/database.yml` file, which is where we configure the core details of our database. By default, when using SQLite, Rails will generate a `/config/database.yml` that looks like this:

```yaml
# SQLite. Versions 3.8.0 and up are supported.
#   gem install sqlite3
#
#   Ensure the SQLite 3 gem is defined in your Gemfile
#   gem "sqlite3"
#
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  <<: *default
  database: storage/development.sqlite3

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *default
  database: storage/test.sqlite3

production:
  <<: *default
  database: storage/production.sqlite3
```

Simple and reasonable. Each Rails environment gets its own database file. Every database file is stored in the `/storage` directory (where most hosting providers ensure that contents are persisted across deployments). And each database file has a fixed file name. What we want is to have our `development` environment use a _dynamic_ file name for the database, and we want that file name to be based on the current Git branch. A quick Google search leads to a [StackOverflow answer](https://stackoverflow.com/a/6245587/2884386) that provides the `git` command for getting the current branch name:

```shell
git branch --show-current
```

> **Note:** If you are using a Git version less than 2.22 (when the `--show-current` option was added), you can use `git rev-parse --abbrev-ref HEAD` instead.

So, how do we use this in our `/config/database.yml` file? Well, Rails makes this easy as it allows for ERB. Adding a tiny bit of resilience to the code, we can replace our `development` section with this:

```yaml
development:
  <<: *default
  database: storage/<%= `git branch --show-current`.chomp || 'development' %>.sqlite3
```

Now, instead of always using `storage/development.sqlite3` as our database file name, we provide a dynamic file name that will name the database file whatever our current Git branch name is. With this single line change we have implemented the first of our ideal features—we have a single branch (a Git branch) which isolates _both_ our code and our schema.

Next, how can we configure Rails to **automatically** switch "schema branches" when our Git branch changes? Well, here we need to articulate with a bit more clarity what exactly we need, given our solution above. The change to the `/config/database.yml` file already ensures that when we switch Git branches, our Rails app will talk to an isolated development database. However, this change alone doesn't ensure that once we have switched Git branches that our isolated development database is ready for use. Imagine that a colleague has created a branch which adds two new database migrations. You pull down that branch to do some code review and local manual testing. When you switch your local Git repo to checkout your colleague's branch for the first time, our dynamic `/config/database.yml` configuration will ensure that a new SQLite database file is created in our `/storage` directory. However, this new SQLite database file doesn't yet have anything in it, and it doesn't have the schema setup either. So, how can we ensure that Rails automatically prepares this new database file whenever we switch database branches?

Well, again, luckily for us Rails makes this pretty easy. Rails provides the [`ActiveRecord::Tasks::DatabaseTasks` utility class](https://api.rubyonrails.org/classes/ActiveRecord/Tasks/DatabaseTasks.html), which "encapsulates logic behind common tasks used to manage database and migrations." For our needs, we can turn to the [`.prepare_all` method](https://api.rubyonrails.org/classes/ActiveRecord/Tasks/DatabaseTasks.html#method-i-prepare_all), which is the programmatic equivalent to the [`db:prepare` Rake command](https://github.com/rails/rails/pull/35768) added [in Rails 6](https://www.bigbinary.com/blog/rails-6-adds-rails-db-prepare-to-migrate-or-setup-a-database). Preparing a database means, simply, running migrations if the database already exists or creating the database and loading the schema if not. All we need is to tell Rails to run this command in development every time we boot up the app. This will ensure that our dynamic database is always ready for use by our Rails app (whether running the server or jumping into a console).

In order to have Rails run this command in development when we boot that app, we can simply add this to our `/config/environments/development.rb` file:

```ruby
# Ensure that our branch-specific SQLite database is prepared for our application to use
config.after_initialize do
  ActiveRecord::Tasks::DatabaseTasks.prepare_all
end
```

We simply configure our `development` environment to run the `.prepare_all` command after the app has been initialized.

Which this simple configuration added, we now have our ideal setup. Every Git branch has its own, isolated database file. That database is **automatically** prepared for usage on-demand when we boot our Rails app. And production deploys driven by Git branch merging continues to produce stable and predictable production schemas, by using migrations exclusively to alter our schema.

- - -

I can say, I have been using this setup in a few different Rails applications and I _absolutely love it_! And I love how easy Rails and SQLite make such a feature to setup. This was a grand total of **_four_** lines (and could easily be _two_ if we used an inline block for `after_initialize`) to provide a similar (and in some key ways improved) feature to a fancy platform like PlanetScale.

It is precisely these kinds of enhancements—simple, small, but powerful—that I want to explore in the coming weeks and months. So, stay tuned. And, if you enjoyed this tip, please do reach out on Twitter [@fractaledmind](http://twitter.com/fractaledmind?ref=fractaledmind.github.io).

- - -

## All posts in this series

* {:.bg-[var(--tw-prose-bullets)]}[Part 1 — branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %})
* [Part 2 — fine-tuning SQLite configuration]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %})
* [Part 3 — loading extensions]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %})
* [Part 4 — setting up `Litestream`]({% link _posts/2023-09-09-enhancing-rails-sqlite-setting-up-litestream.md %})
