---
title: Enhancing your Rails app with SQLite
subtitle: ULID primary keys
date: 2023-09-14
tags:
  - code
  - ruby
  - rails
  - sqlite
published: false
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



https://github.com/nalgeon/sqlean/blob/main/docs/uuid.md
https://github.com/asg017/sqlite-ulid
