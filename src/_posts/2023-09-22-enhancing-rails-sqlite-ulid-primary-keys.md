---
title: Enhancing your Rails app with SQLite
subtitle: ULID primary keys
date: 2023-09-22
tags:
  - code
  - ruby
  - rails
  - sqlite
published: true
---

When using [SQLite](https://www.sqlite.org/index.html) as our [Ruby on Rails](https://rubyonrails.org) database, you might wonder how to use something like [<abbr title="Universally Unique Identifiers">UUIDs</abbr>](https://en.wikipedia.org/wiki/Universally_unique_identifier) or [<abbr title="Universally Unique Lexicographically Sortable Identifiers">ULIDs</abbr>](https://github.com/ulid/spec) as primary keys.

<!--/summary-->

- - -

I got this question on Twitter, and it merits its own post to answer:

> Any resources about using UUIDs (or ULIDs) as primary keys in Rails?
> I’ve gotten used to that with PostgreSQL but it seems a little wonky with SQLite3.
>
> — <cite><a href="https://x.com/claytonlz/status/1702390021377106412?s=20">@claytonlz</a></cite>

Let's start with how we configure Rails to use a custom primary key type. [Paweł Urbanek](https://pawelurbanek.com) has an [excellent blog post](https://pawelurbanek.com/uuid-order-rails) laying out the steps for using [Postgres' native UUID data type](https://www.postgresql.org/docs/current/datatype-uuid.html) as the primary key for tables. You should give the entire article a read, but for our purposes the two key details are:

1. how to set the primary key type in a migration, and
2. how to configure Rails to use UUIDs as primary keys for generators

In a migration, we simply pass `id: :uuid` as an option to the `create_table` method:

```ruby
create_table :comments, id: :uuid  do |t|
  t.string :content
  t.uuid :user_id
  t.timestamps
end
```

In order to have all generated migrations set this option automatically, we can configure Rails:

```ruby
# config/initializers/generators.rb
Rails.application.config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
```

These are the foundational changes you will need to make to your Rails application to enable custom primary keys. How could we do this in SQLite though?

- - -

To be honest, custom primary keys weren't possible when using SQLite with Rails up to today. In order to support this feature, I opened a [pull request](https://github.com/rails/rails/pull/49290) to add support for `RETURNING` non-`id` columns for SQLite. And, luckily for all of us SQLite lovers, it has been merged! This means that if you use the `main` Rails branch for your application, you can get access to custom primary keys _today_. So, let's dig into **how**.

Personally, I prefer [<abbr title="Universally Unique Lexicographically Sortable Identifiers">ULIDs</abbr>](https://github.com/ulid/spec) to [<abbr title="Universally Unique Identifiers">UUIDs</abbr>](https://en.wikipedia.org/wiki/Universally_unique_identifier), since they are shorter, easier to select and copy, and sortable. Plus, in SQLite-land Alex Garcia's [`sqlite-ulid`](https://github.com/asg017/sqlite-ulid) extension is available as a [Ruby gem](https://rubygems.org/gems/sqlite-ulid).

As detailed in a [past post on loading extensions]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %}), we can extend Rails' database adapter to support loading extensions. By loading the `sqlite-ulid` extension, we add the `ulid()` and `ulid_bytes()` functions to our SQLite database. We can then use one of these functions for our custom primary keys.

Since the SQLite adapter doesn't support a `ulid` data-type, we need to define our custom primary keys somewhat differently. Instead of passing the `id: :ulid` option to the `create_table` command, we should instead pass `id: false`. This will disable Rails' default primary key mechanism for your database engine. We can then define the `t.primary_key` macro to set the details of our custom primary key. In our case, using ULIDs, we could define the custom primary key like so:

```ruby
create_table :posts, force: true, id: false do |t|
  t.primary_key :id, :string, default: -> { "ULID()" }
end
```

Running this migration will create a table with a ULID primary key:

```sql
CREATE TABLE "posts" (
  "id" varchar DEFAULT (ULID()) NOT NULL PRIMARY KEY
)
```

Now, calling `Post.create!` will return a model instance like this `#<Post id: "01hayj8d41d5e4hx0fdfbvja76">`.

Unfortunately, we can't setup the Rails generators to auto-create migrations like this, since we don't have a custom `ulid` data-type. But, a bit of manual effort isn't a bad thing.

- - -

Once we have custom primary keys, we need to ensure that our foreign keys are appropriately matched. In order to ensure our foreign keys are correctly bound to our custom primary keys, we need to tweak our migrations minorly:

```ruby
create_table :comments, force: true, id: false do |t|
  t.primary_key :id, :string, default: -> { "ULID()" }
  t.belongs_to :post, null: false, foreign_key: true, type: :string
end
```

Whatever the data-type we use for our primary keys, we need to set that type for our foreign keys. This is the only thing we need to ensure. Using the `belongs_to` or `references` method will automatically setup the rest of our foreign key with our custom primary key. A `create_table` like the one above will produce the following SQL:

```sql
CREATE TABLE "comments" (
  "id" varchar DEFAULT (ULID()) NOT NULL PRIMARY KEY,
  "post_id" varchar NOT NULL, CONSTRAINT "fk_rails_2fd19c0db7"
  FOREIGN KEY ("post_id") REFERENCES "posts" ("id")
)
```

That's it. That's everything you need to know to setup custom primary and foreign keys for your Rails application using SQLite as your database engine.

In the future, I will be investigating how to register a custom `ulid` data-type so that we can simplify this setup even further. So, keep your eyes out for that upcoming post.

In the meantime, I hope you enjoyed this exploration into one of the features unlocked by supporting `RETURNING` statements with the SQLite adapter.

- - -

## All posts in this series

* [Part 1 — branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %})
* [Part 2 — fine-tuning SQLite configuration]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %})
* [Part 3 — loading extensions]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %})
* [Part 4 — setting up `Litestream`]({% link _posts/2023-09-09-enhancing-rails-sqlite-setting-up-litestream.md %})
* [Part 5 — optimizing compilation]({% link _posts/2023-09-10-enhancing-rails-sqlite-optimizing-compilation.md %})
* [Part 6 — array columns]({% link _posts/2023-09-12-enhancing-rails-sqlite-array-columns.md %})
* [Part 7 — local snapshots]({% link _posts/2023-09-14-enhancing-rails-sqlite-local-snapshots.md %})
* [Part 8 — Rails improvements]({% link _posts/2023-09-15-enhancing-rails-sqlite-activerecord-adapter-improvements.md %})
* [Part 9 — performance metrics]({% link _posts/2023-09-21-enhancing-rails-sqlite-performance-metrics.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Part 10 — custom primary keys]({% link _posts/2023-09-22-enhancing-rails-sqlite-ulid-primary-keys.md %})
* [Part 11 — more Rails improvements]({% link _posts/2023-09-26-enhancing-rails-sqlite-more-activerecord-adapter-improvements.md %})
* [Part 12 — table schema and metadata]({% link _posts/2023-11-13-enhancing-rails-sqlite-table-schema-and-metadata.md %})
* [Part 13 — prefixed ULID keys]({% link _posts/2023-12-13-enhancing-rails-sqlite-prefixed-ulids.md %})
* [Part 14 — installing extensions]({% link _posts/2023-12-24-enhancing-rails-installing-extensions.md %})
