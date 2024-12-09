---
series: SQLite on Rails
title: September State of the Union
date: 2023-09-27
tags:
  - code
  - ruby
  - rails
  - sqlite
---

I wrote my first blog post [about SQLite and Rails]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %}) on September 6<sup>th</sup>. Today is September 27<sup>th</sup>; that is 3 weeks. A lot has happened in the last 3 weeks. Let's recap.

<!--/summary-->

- - -

If you haven't considered running your Rails application in production with SQLite, be prepared to start hearing a lot more about it:

> As machines get ever more powerful, the scope of work that SQLite can handle grows. Cutting out the complexity of running a DB process is a major step forward. We are betting on SQLite in production with our upcoming ONCE product line at @37signals.

— [DHH](https://twitter.com/dhh/status/1705271515997143168)

If you haven't noticed yet, the momentum has been growing for a while, sparked by projects like [`Litestream`](https://litestream.io) and [`Litestack`](http://github.com/oldmoe/litestack). People are embracing the power and simplicity of SQLite and looking for how to leverage that. Check out how full-featured your Rails app can be, while still only running on a single VPS: [An Introduction to LiteStack for Ruby on Rails](https://blog.appsignal.com/2023/09/27/an-introduction-to-litestack-for-ruby-on-rails.html)

This future excites me. I love Ruby on Rails; I love SQLite; And I love win-wins that come with cutting complexity without having to cut power. So, for the last 3 weeks, I have been writing and working nearly exclusively on pushing this vision forward and bringing this vision to life.

## Timeline

* September 6
  - blog post on [branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %})
* September 7
  - blog post on [fine-tuning SQLite configuration]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %})
* September 8
  - blog post on [loading extensions]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %})
  - pull request opened [to allow users to set compile-time flags](https://github.com/sparklemotion/sqlite3-ruby/pull/402)
* September 9
  - a [v1.6.5](https://github.com/sparklemotion/sqlite3-ruby/releases/tag/v1.6.5) of the `sqlite3-ruby` gem was released with this feature
  - blog post on [setting up `Litestream`]({% link _posts/2023-09-09-enhancing-rails-sqlite-setting-up-litestream.md %})
* September 10
  - blog post on [optimizing compilation]({% link _posts/2023-09-10-enhancing-rails-sqlite-optimizing-compilation.md %})
* September 12
  - blog post on [array columns]({% link _posts/2023-09-12-enhancing-rails-sqlite-array-columns.md %})
* September 14
  - blog post on [local snapshots]({% link _posts/2023-09-14-enhancing-rails-sqlite-local-snapshots.md %})
* September 15
  - pull request ([#49290](https://github.com/rails/rails/pull/49290)) opened to support auto-populating columns and custom primary keys
  - pull request ([#49287](https://github.com/rails/rails/pull/49287)) opened to support concatenation in default functions
  - blog post on [Rails improvements]({% link _posts/2023-09-15-enhancing-rails-sqlite-activerecord-adapter-improvements.md %})
* September 16
  - [another pull request](https://github.com/sparklemotion/sqlite3-ruby/pull/408)
 opened ensuring that all SQLite installations made via the gem were configured to use the `WAL` journal mode and `NORMAL` synchronous setting
* September 20
  - pull request ([#49287](https://github.com/rails/rails/pull/49287)) merged
* September 21
  - pull request ([#49290](https://github.com/rails/rails/pull/49290)) merged
  - pull request ([#49346](https://github.com/rails/rails/pull/49346)) opened to support generated columns
  - blog post on [performance metrics]({% link _posts/2023-09-21-enhancing-rails-sqlite-performance-metrics.md %})
* September 22
  - pull request ([#49352](https://github.com/rails/rails/pull/49352)) opened to support `retries` configuration option
  - pull request ([#49349](https://github.com/rails/rails/pull/49349)) opened to improve Rails' default SQLite run-time configuration
  - blog post on [custom primary keys]({% link _posts/2023-09-22-enhancing-rails-sqlite-ulid-primary-keys.md %})
* September 24
  - pull request ([#49349](https://github.com/rails/rails/pull/49349)) merged
  - pull request ([#49352](https://github.com/rails/rails/pull/49352)) merged
* September 25
  - pull request ([#49376](https://github.com/rails/rails/pull/49376)) opened to support deferred foreign keys
* September 26
  - blog post on [more Rails improvements]({% link _posts/2023-09-26-enhancing-rails-sqlite-more-activerecord-adapter-improvements.md %})

Read on for the breakdown on what all has happened in _#SQLiteOnRails_ land in the last month&hellip;

- - -

## Performance Tuning

I began investigating how best to configure a SQLite database for the typical usage expected with a web application. As I wrote [on September 7<sup>th</sup>]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %}), there are 6 `PRAGMA`s (run-time options) that will make a big difference to your web application. I setup a benchmark on September 21<sup>st</sup> and compared a SQLite database with the default configuration to one with our recommended configuration, and [we saw a **2×** speed improvement]({% link _posts/2023-09-21-enhancing-rails-sqlite-performance-metrics.md %}).

In addition to run-time performance tuning, I wanted to investigate compile-time tuning as well. I was spurred on by [a tweet](https://twitter.com/hopsoft/status/1699795147050061839) from [Nate Hopkins](https://twitter.com/hopsoft?ref=fractaledmind.github.io) showing a `Dockerfile` that was compiling SQLite from source with certain flags to optimize performance. Compile-time optimization is worth investigating, as even the SQLite documentation notes that its default compilation setup is [unsuited for many use-cases](https://www.sqlite.org/compile.html#recommended_compile_time_options). After investigating and experimenting, I found 9 compile-time flags worth setting for Ruby on Rails applications. After opening [a new discussion](https://github.com/sparklemotion/sqlite3-ruby/discussions/400) on the GitHub repo, [Mike Dalessio](https://twitter.com/flavorjones?ref=fractaledmind.github.io), one of the project's primary maintainers, reached out and we hopped on a call to discuss how the [`sqlite3-ruby` gem](https://github.com/sparklemotion/sqlite3-ruby) might enable Ruby developers to manage compile-time flags. On September 8<sup>th</sup>, Mike opened a new [pull request](https://github.com/sparklemotion/sqlite3-ruby/pull/402) to allow users to set compile-time flags that the `sqlite3-ruby` gem will use when installing and compiling SQLite. The next day, a [v1.6.5](https://github.com/sparklemotion/sqlite3-ruby/releases/tag/v1.6.5) of the `sqlite3-ruby` gem was released, enabling users to pass compile-time options.

This allowed me to write up a [new blog post]({% link _posts/2023-09-10-enhancing-rails-sqlite-optimizing-compilation.md %}) on September 10<sup>th</sup> detailing how to use this feature in a Rails application to set the recommended compile-time flags.

This blog post then inspired Mike to improve the default compile-time configuration of SQLite installed via the `sqlite3-ruby` gem. So, on September 16<sup>th</sup>, Mike opened [another pull request](https://github.com/sparklemotion/sqlite3-ruby/pull/408) which ensured that all SQLite installations made via the gem were configured to use the `WAL` journal mode and `NORMAL` synchronous setting. This is amazing, because [academic research](https://www.cs.utexas.edu/~vijay/papers/apsys17-sqlite.pdf)[^1] shows that even just changing these two options can lead to a 10× performance improvement. When the next version of the `sqlite3-ruby` gem is released, every user will get a better tuned SQLite installation. 🎉

Following on with this momentum, and wanting to bring this modern, performant default configuration to every SQLite database used by Rails applications, I opened [a PR (#49349)](https://github.com/rails/rails/pull/49349) on September 22<sup>nd</sup> to make this the default configuration for all Rails applications using SQLite. This pull request was _merged_ on September 24<sup>th</sup> and is now a part of `v7.1.0.rc1`. 🎉

All in all, within only a couple weeks, the Ruby and Rails communities were able to provide noticeably improved default configurations for both SQLite installations and database connections. I want to give a big shout-out to Mohamed Hassan ([@oldmoe]((https://twitter.com/oldmoe?ref=fractaledmind.github.io))), Mike Dalessio ([@flavorjones](https://twitter.com/flavorjones?ref=fractaledmind.github.io)), Guillermo Iguaran ([@guilleiguaran](https://twitter.com/guilleiguaran?ref=fractaledmind.github.io)), Hartley McGuire ([@skipkayhil](https://github.com/skipkayhil?ref=fractaledmind.github.io)), and Nate Hopkins ([@hopsoft]((https://twitter.com/hopsoft?ref=fractaledmind.github.io))) for taking part in this amazing push to improve the default performance of SQLite in the Ruby and Rails ecosystems. Isn't it amazing what can happen in a couple short weeks?

- - -

## Rails Feature Parity

In addition to improving the default configuration of SQLite, I found myself working on improving Rails' `SQLite3` Active Record adapter as well.

On September 14<sup>th</sup>, [Clayton](https://twitter.com/claytonlz?ref=fractaledmind.github.io) asked a question about custom primary keys with Rails and SQLite:

> Any resources about using UUIDs (or ULIDs) as primary keys in Rails?
> I’ve gotten used to that with PostgreSQL but it seems a little wonky with SQLite3.

— [Clayton LZ](https://x.com/claytonlz/status/1702390021377106412)

In working on a blog post detailing an answer, I realized that the Rails `SQLite3` adapter didn't support the Active Record feature that the `PostgreSQL` adapter was using to make this feature possible. So, I decided to jump in and see if I could bring that behavior over to the SQLite adapter. Thus started my journey into bring the `SQLite3` adapter up to available feature parity with the other database adapters in Active Record.

### Auto-populating columns and custom primary keys

That first feature ended up being implementing the full contract for `supports_insert_returning?` in the SQLite adapter. I opened the [PR (#49290)](https://github.com/rails/rails/pull/49290) on September 15<sup>th</sup>, and it was merged on September 21<sup>st</sup>. It is now a part of the release candidate for Rails version 7.1.0. 🎉

This feature allows Rails applications using SQLite as their Active Record database engine to define custom primary keys for their tables:

```ruby
# db/migrate/20230928000000_create_posts.rb
create_table :posts, force: true, id: false do |t|
  t.primary_key :id, :string, default: -> { "ULID()" }
end
```

and the database-generated value will be provided to the instantiated Ruby object:

```ruby
Post.create!
# => #<Post id: "01hayj8d41d5e4hx0fdfbvja76">
```

### Generated columns

Next, I realized that the SQLite adapter could and should implement the `supports_virtual_columns?` contract. So, on the same day that the previous PR was merged (September 21<sup>st</sup>), I opened a second [pull request (#49346)](https://github.com/rails/rails/pull/49346) to add this behavior.

This PR allows you to construct "virtual" columns on your tables with an expression to define them. A generated column can be either dynamic or stored:

```ruby
# db/migrate/20230928000000_create_users.rb
create_table :users do |t|
  t.string :name
  t.virtual :name_upper, type: :string, as: 'UPPER(name)'
  t.virtual :name_lower, type: :string, as: 'LOWER(name)', stored: true
end
```

and the database-generated values will be provided to the instantiated Ruby object:

```ruby
User.create!(name: "Stephen")
# => #<User id: 1, name: "Stephen", name_upper: "STEPHEN", name_lower: "stephen">
```

{:.notice}
Yes, this feature relies on the `supports_insert_returning?` feature to ensure that virtual column database values are provided back to the instantiated Ruby model instance object.

As of today, September 27<sup>th</sup>, this pull request has been _reviewed_, but is not yet merged. This means that it won't be in the 7.1 release. 😢

### Deferred foreign keys

The third [PR (#49376)](https://github.com/rails/rails/pull/49376), which I opened recently on September 25<sup>th</sup>, implements the full `supports_deferrable_constraints?` contract for the SQLite adapter.

This feature allows you to define a foreign key as `deferred` (defaults to `immediate`) in a migration:

```ruby
# db/migrate/20230928000000_add_foreign_key_to_reviews.rb
add_foreign_key :reviews, :products, deferrable: :deferred
```

then create inter-related records in the same transaction without error:

```ruby
Product.transaction do
  review = Review.create!(product_id: 11, comment: "amazing product")
  product = Product.create!(id: 11, title: "Hand Sanitizer", description: "new sanitizer in town")
end
# TRANSACTION (1.2ms)  BEGIN
# Review Create (1.7ms)  INSERT INTO "reviews" ("comment", "created_at", "updated_at", "product_id") VALUES ($1, $2, $3, $4) RETURNING "id"  [["comment", "amazing product"], ["created_at", "2022-03-22 07:44:17.296514"], ["updated_at", "2022-03-22 07:44:17.296514"], ["product_id", 11]]
# Product Create (1.5ms)  INSERT INTO "products" ("id", "title", "description", "created_at", "updated_at") VALUES ($1, $2, $3, $4, $5) RETURNING "id"  [["id", 11], ["title", "Hand Sanitizer"], ["description", "new sanitizer in town"], ["created_at", "2022-03-22 07:44:17.306941"], ["updated_at", "2022-03-22 07:44:17.306941"]]
# TRANSACTION (2.4ms)  COMMIT
```

For those of us that have struggled with atomic transactions that need to write inter-dependent records, this is truly a God-send.

Unfortunately, as of today, September 27<sup>th</sup>, this pull request has been _reviewed_, but is not yet merged. This means that it won't be in the 7.1 release. 😢

### Future plans

There is one additional Active Record contract that SQLite supports: `supports_unique_keys?`. I have already started working on bringing this feature to the SQLite adapter, so be on the lookout for that pull request in October.

Also, since some of the key features didn't make it into Rails 7.1, I will be creating a gem that will back-port these features and provide all of the features to any Rails application on any (sufficiently modern) version. Of course, I will let you know when that is released.

- - -

## Rails Feature Improvements

In addition to these larger Active Record features, I also opened some pull requests for smaller features to improve the experience of using SQLite with Active Record.

### Concatenation in default functions

First up, my very first PR for Active Record actually, was a small addition to make using the `||` concatenation operator possible in default functions. I opened this [pull request (#49287)](https://github.com/rails/rails/pull/49287) on September 15<sup>th</sup>, and it was merged on September 20<sup>th</sup>. So, this feature will be a part of the 7.1 Rails release. 🎉

```ruby
# db/migrate/20230928000000_create_posts.rb
change_column_default "test", "ruby_on_rails", -> { "('Ruby ' || 'on ' || 'Rails')" }
```

### Retry busy connections faster

Next, on September 22<sup>nd</sup>, I opened a small [PR (#49352)](https://github.com/rails/rails/pull/49352) to provide an alternative to the `timeout` option for a SQLite database configuration. Because SQLite doesn't allow for concurrent writes, you will hit busy connections when working in the multi-threaded Rails environment. The default configuration of using a `timeout` tells SQLite to incrementally backoff while retrying busy connections. This is a sane default. But, for those applications looking to squeeze every millisecond of performance out of their SQLite backends, it will eat up some unnecessary milliseconds. So, I provided the alternative `retries` configuration option:

```yaml
# config/database.yml
default: &default
  adapter: sqlite3
  retries: 1000
```

When the `retries` option is set, the SQLite database will retry busy connections as quickly as possible up to that max number of `retries`. This means that as soon as the connection is no longer busy, you can make your query.

This pull request was merged on September 24<sup>th</sup>, and so it too will be a part of the Rails 7.1 release. 🎉

### Future Plans

We will see what the Rails Core team has the appetite to support, but I will be proposing a few more features in October.

Up first, I want to allow developers to manage the `PRAGMA` run-time configuration of their SQLite connection via the `database.yml` file. This will allow developers who want or need to change the (now improved) default configuration to do so easily and explicitly.

Next, I would love to also allow developers to manage loading SQLite extensions into their database via the `database.yml` file as well. This would centralize and make explicit all of the key configuration of your database setup.

Ideally, I would then also like to make it possible for developers to define custom Active Record types, like `:ulid`.

For any and all of these features that aren't accepted into Rails itself, I will still provide them via the gem that I described previously.

- - -

## Fun Use-Cases

Aside from all of this coding, I have also had the opportunity in the last 3 weeks to explore and write about some of the fun and exciting use-cases that SQLite makes possible or simple.

### Schema branching

The first, and truly one of my very favorite, tips was about how to setup [branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %}) for your Rails application. In 2 lines of code, you get a massive DX improvement by allowing every Git branch to have its own, isolated database file. This was my very first blog post in this series, on September 6<sup>th</sup>.

```yaml
# config/database.yml
development:
  <<: *default
  database: storage/<%= `git branch --show-current`.chomp || 'development' %>.sqlite3
```

```ruby
# config/environments/development.rb
# Ensure that our branch-specific SQLite database is prepared for our application to use
config.after_initialize do
  ActiveRecord::Tasks::DatabaseTasks.prepare_all
end
```

### Automatic backups

I also had the time to write up how to install and configure [`Litestream`](https://litestream.io) to provide automatic backups for your SQLite database. This kind of disaster recovery plan is a must-have for those of us using SQLite for our web application. I [wrote about this]({% link _posts/2023-09-09-enhancing-rails-sqlite-setting-up-litestream.md %}) early on in this process, on September 9<sup>th</sup>.

```yaml
# /etc/litestream.yml
dbs:
  - path: /home/deploy/application-name/current/storage/production.sqlite3
    replicas:
      - url: s3://bucket-name.litestream.region.digitaloceanspaces.com/production
        access-key-id: xxxxxxxxxxxxxxxxxxxx
        secret-access-key: xxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Postgres-style array columns

I then wrote about how even though SQLite doesn't provide all of the fancy features of PostgreSQL or MySQL, there are often ways we can use the tools that SQLite does provide to enable similar experiences. Specifically, on September 12<sup>th</sup>, I wrote a full tutorial on how to replicate Postgres' [array columns]({% link _posts/2023-09-12-enhancing-rails-sqlite-array-columns.md %}) feature:

```ruby
create_table :posts, force: true do |t|
  t.json :tags, null: false, default: []
  t.check_constraint "JSON_TYPE(tags) = 'array'", name: 'post_tags_is_array'
end
```

I also provided the Ruby code to take advantage of such a database feature to make a tagging system:

```ruby
Model.unique_column_name()
Model.column_name_cloud()
Model.with_column_name()
Model.without_column_name()
Model.with_any_column_name(*items)
Model.with_all_column_name(*items)
Model.without_any_column_name(*items)
Model.without_all_column_name(*items)

model.has_any_column_name(*items)
model.has_all_column_name(*items)
model.has_column_name(*items)
```

### Simple snapshots

A couple days later, on September 14<sup>th</sup>, I explored how easy it can be to setup a [local snapshotting utility]({% link _posts/2023-09-14-enhancing-rails-sqlite-local-snapshots.md %}) via `Rake` tasks. Since your database is simply a file, snapshotting your database is as simple as:

```ruby
# lib/tasks/snap.rake
namespace :snap do
  task :create do
    @snapshot_dir = Rails.root.join('storage/snapshots')
    @db_path = ActiveRecord::Base.connection_db_config.database
    @db_name = @db_path.rpartition('/').last.remove('.sqlite3')

    timestamp = DateTime.now.to_formatted_s(:number)
    snap_name = "#{@db_name}-#{timestamp}.backup"
    snap_path = Pathname(@snapshot_dir).join(snap_name)

    FileUtils.copy_file(@db_path, snap_path)
  end
end
```

And restoring:

```ruby
# lib/tasks/snap.rake
namespace :snap do
  task :restore do
    @snapshot_dir = Rails.root.join('storage/snapshots')
    @db_path = ActiveRecord::Base.connection_db_config.database
    @db_name = @db_path.rpartition('/').last.remove('.sqlite3')
    @snaps = Pathname(@snapshot_dir)
      .children
      .select do |path|
        path.extname == ".backup" &&
        path.basename.to_s.include?(@db_name)
      end
      .sort
      .reverse

    latest_snapshot = @snaps.first

    FileUtils.remove_file(@db_path)
    FileUtils.copy_file(latest_snapshot, @db_path)
  end
end
```

### Future plans

I want to keep exploring what possibilities SQLite makes uniquely possible, or how we can provide similar behaviors and features as Postgres and MySQL. There are so many possible topics, and I don't have a firm roadmap set yet. So, if you have any particular questions or interests, definitely let me know. You can reach out on Twitter. I'm [@fractaledmind](https://twitter.com/fractaledmind).

I also want to start digging into the philosophy and technical details of the [`Litestack`](http://github.com/oldmoe/litestack) project. By providing a Rails backend for all of the I/O-bound Rails components, it offers a remarkably simple application setup that doesn't skimp on power, features, or performance.

I think there is also a lot of work to be done to bust some of the myths that still persist around running SQLite in production. I know it is the default thought of most developers that it simply doesn't make sense and wouldn't work or "scale". There is a lot to say on what myths lead developers to believe this, and why they are myths and not truths.

Plus, with [37signals](https://37signals.com) soon launching their first [ONCE](https://once.com) product, I am expecting an increased surge of interest in running SQLite in production with Rails applications. So, there is no shortage of topics to write about, features to build, and experiments to run.

I'm curious to see what October will hold!

- - -

## All posts in this series

* {:.bg-[var(--tw-prose-bullets)]}[SQLite on Rails — September State of the Union]({% link _posts/2023-09-27-sqlite-on-rails-september-state-of-the-union.md %})
* [SQLite on Rails — Introducing the enhanced adapter gem]({% link _posts/2023-10-09-sqlite-on-rails-enhanced-sqlite3-adapter.md %})
* [SQLite on Rails — Improving the enhanced adapter gem]({% link _posts/2023-12-06-sqlite-on-rails-improving-the-enhanced-sqlite3-adapter.md %})
* [SQLite on Rails — Improving concurrency]({% link _posts/2023-12-11-sqlite-on-rails-improving-concurrency.md %})
* [SQLite on Rails — Introducing `litestream-ruby`]({% link _posts/2023-12-12-sqlite-on-rails-litestream-ruby.md %})
* [SQLite on Rails — Isolated connection pools]({% link _posts/2024-04-11-sqlite-on-rails-isolated-connection-pools.md %})
* [SQLite on Rails — Loading extensions]({% link _posts/2024-12-09-sqlite-on-rails-loading-extensions.md %})

- - -

[^1]: Purohith, Mohan, and Chidambaram detail their findings in "[The Dangers and Complexities of SQLite Benchmarking](https://www.cs.utexas.edu/~vijay/papers/apsys17-sqlite.pdf)", showing that benchmarking results without this context are insufficient to both reproduce the result and place it in the larger context of benchmarks. This is particularly true of SQLite, as even a single configuration change can lead to more than a 10× performance improvement.
