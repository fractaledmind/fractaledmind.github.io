---
title: Enhancing your Rails app with SQLite
subtitle: Array columns
date: 2023-09-12
tags:
  - code
  - ruby
  - rails
  - sqlite
---

One of the reasons people hesitate to use [SQLite](https://www.sqlite.org/index.html) in their [Ruby on Rails](https://rubyonrails.org) applications, in my opinion, is a fear that they will miss certain features they are accustomed to from [PostgeSQL](https://www.postgresql.org) or [MySQL](https://www.mysql.com). As discussed in an [earlier post]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %}), we can load SQLite extensions into our Rails applications to enhance the functionality of SQLite. Moreover, today I want to show you that it is possible to build on top of SQLite's primitives to provide matching behavior for one of my favorite features of Postgres—[array columns](https://www.postgresql.org/docs/current/arrays.html).

<!--/summary-->

- - -

When working with relational data, you often come across one particular dilemma: what do I do with this small amount of associated data? Do I build a whole new table with a foreign key, which keeps my schema highly [normalized](https://en.wikipedia.org/wiki/Database_normalization) but also means I have to accept a `JOIN` everytime I need to access this data. Do I simply stuff the data into a `JSON` column on my primary table, which removes the need for the `JOIN` but also bloats my primary table and opens up a possibility for stuffing unstructured data into that column.

Postgres offers a nice compromise here with their implementation of [array columns](https://www.postgresql.org/docs/current/arrays.html). Instead of an amorphous JSON blob, your column is and will always simply be an array of values. This matches the effective behavior of a simple two-column associated table (foreign key plus value column), without the need for the `JOIN`.

For my favorite example of the utility of this tool, consider [Nate Hopkin's](https://twitter.com/hopsoft?ref=fractaledmind.github.io) implementation of [a tagging system](https://github.com/hopsoft/tag_columns), built on top of Postgres' array columns. To save you a click and demonstrate just how elegant this solution is, I will provide the code examples from the `README` here:

```ruby
# db/migrate/TIMESTAMP_add_groups_to_user.rb
class AddGroupsToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :groups, :string, array: true, default: [], null: false
    add_index :users, :groups, using: "gin"
  end
end
```
```ruby
# app/models/user.rb
class User < ApplicationRecord
  include TagColumns
  tag_columns :groups
end
```
```ruby
user = User.find(1)

# assigning tags
user.groups << :reader
user.groups << :writer
user.save

# checking tags
is_writer            = user.has_group?(:writer)
is_reader_or_writer  = user.has_any_groups?(:reader, :writer)
is_reader_and_writer = user.has_all_groups?(:reader, :writer)

# finding tagged records
assigned                = User.with_groups
unassigned              = User.without_groups
writers                 = User.with_any_groups(:writer)
non_writers             = User.without_any_groups(:writer)
readers_or_writers      = User.with_any_groups(:reader, :writer)
readers_and_writers     = User.with_all_groups(:reader, :writer)
non_readers_and_writers = User.without_all_groups(:reader, :writer)

# find unique tags across all users
User.unique_groups

# find unique tags for users with the last name 'Smith'
User.unique_groups(last_name: "Smith")
```

With one array column on your model, you get a full suite of the core "tagging-style" functionality. I love solutions like this. The entire gem is no more than one file that defines the `TagColumns` concern, and that file is only 105 lines (89 lines of code). Elegance and simplicity are what SQLite is all about, so, how can we accomplish the same result without an array column primitive?

- - -

Let's start with how we can add a column to a table that can only be an array. SQLite does support a [wide variety](https://www.sqlite.org/json1.html) of JSON functionality. It also supports standard column [check constraints](https://www.sqlite.org/lang_createtable.html#check_constraints). This gives us everything we need. We will define a `JSON` column and then add a constraint to ensure that the column is only an `array` JSON type. With Rails' migration DSL, if you are creating the column as you create the table it looks like:

```ruby
create_table :posts, force: true do |t|
  t.json :tags, null: false, default: []
  t.check_constraint "JSON_TYPE(tags) = 'array'", name: 'post_tags_is_array'
end
```

If you are simply adding the column to an existing table, the migration would look like:

```ruby
add_column :posts, :tags, :json, default: [], null: false
add_check_constraint "JSON_TYPE(tags) = 'array'", name: 'post_tags_is_array'
```

{:.notice}
**Note:** SQLite does not support `GIN` indexes. In order to provide an index for a `JSON` column, the recommended pattern in SQLite is to define a [generated column](https://www.sqlite.org/gencol.html) and then index that column. This [blog post](https://antonz.org/json-virtual-columns/) provides a good overview of the approach. Unfortunately for us Rails developers, the `ActiveRecord` adapter for SQLite doesn't yet support generated attributes, so we would have to drop down to running raw SQL. Support for Postgres generated columns was [recently added](https://github.com/rails/rails/pull/41856), and I plan to open a similar pull request for the SQLite adapter in the near future. For the time being, therefore, I will not dig into indexing an "array" column in our SQLite database. Since SQLite doesn't need to eat the network latency cost of a query, even unindexed queries can be sufficiently fast. However, of course, we would prefer to be able to ensure our SQLite implementation of "array columns" can be indexed. Once I have improved Rails' support, I will write a new post detailing how to work with SQLite generated columns and indexing them.


This gives us a `JSON` column that will only ever be an array of values. Without a schema setup, let's turn to the "taggable" functionality that we want to support. `tag_columns` supports 11 methods:[^1]

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

We need SQL queries to back each one, and then the ActiveRecord method calls to generate those queries. As I don't want to derail this post with the process of coming up with each query and ActiveRecord method, I will summarize. At the heart of our implementation is the use of the [`JSON_EACH`](https://www.sqlite.org/json1.html#jeach) function that SQLite provides, which will treat each value in our array as if it were a row in a table. Each virtual row will have a `value` column that you can select from. So, to get the unique set of values for the `tags` column in our example `posts` table, we simply need this SQL query:

```sql
SELECT DISTINCT value
FROM "posts",
     JSON_EACH("posts"."tags");
```

Readable and succinct. Similarly, in order to find those `posts` that are tagged with `draft`, we could use this query:

```sql
SELECT "posts".*
FROM "posts"
WHERE EXISTS (
  SELECT 1
  FROM JSON_EACH("posts"."tags")
  WHERE value IN ('draft')
  LIMIT 1
)
```

This query gets more complicated. In order to find all of the `posts` with the tag, we need to isolate our query for selecting the posts and all of their attributes from the query to check for whether the tag is present or not. This is a perfect use-case for a nested query. Our inner query does a check for whether or not the specific tag is present.[^2] We use `SELECT 1` because we only need to return a boolean for the `WHERE EXISTS` check in the outer query; we use `LIMIT 1` to optimize the inner query a bit, as we only need to know if `draft` is present in the `tags` array _at least once_, we don't care about duplicates. This shape of a query will drive all of the `any_*` methods.

In order to support the `all_*` methods, we need a query that ensures that returned `posts` included each of the provided values. For example, `Post.with_all_tags('draft', 'sqlite')` must only return those `posts` who are tagged with both the `draft` tag and the `sqlite` tag; any post only tagged with `draft` is ignored. Here is the shape for that query:

```sql
SELECT "posts".*
FROM "posts"
WHERE (
  SELECT COUNT(DISTINCT value)
  FROM JSON_EACH("posts"."tags")
  WHERE value IN ('draft', 'sqlite')
) = 2;
```

Instead of a basic `WHERE EXISTS` check, our outer query is now checking whether the number of matching tags for the post matches the number of queried tags. Remember that `JSON_EACH` effectively converts our array column into a virtual table with rows; so, `SELECT COUNT(*) FROM JSON_EACH() WHERE ...` will count the number of entries in our array column that match the where condition, returning that as an integer. We can use that integer returned from the inner query to ensure that the outer query only returns `posts` with the total number of tags provided. In order to handle the possibilities of duplicate `tags`, we ensure that we `COUNT` only `DISTINCT value`s. Were we to use `SELECT COUNT(*)` or `SELECT COUNT(value)`, our integer returned from the inner query _could be_ **larger** than 2 (the size of the array of tags we are querying against). To ensure that the inner query only ever returns an integer as large or smaller than the array of tags, we need to count only distinct values.

However, those three basic queries form the foundation of our entire implementation. `with_*` scopes use `=`, while `without_*` use `!=`, but the shapes are all the same. So, the final piece to our puzzle is generating these queries in ActiveRecord.

- - -

Again, I'm not going to get bogged down in process. We don't want to use raw SQL strings if we can avoid it. Raw SQL strings are brittle in ActiveRecord usage. And we want to provide a model concern, so robustness is of particular value. This means we need to dip down and use [`Arel`](https://github.com/rails/rails/tree/main/activerecord/lib/arel). This is the relational algebra library that sits at the foundation of ActiveRecord, with [ActiveRecord's query interface](https://guides.rubyonrails.org/active_record_querying.html) built on top of Arel. For a good intro on working with `Arel` directly, check out [this post](https://jpospisil.com/2014/06/16/the-definitive-guide-to-arel-the-sql-manager-for-ruby). I won't review those details in this post.

As we stated earlier, every single query we need uses `JSON_EACH` at its heart. So, we need to be able to generate this function in Ruby. `Arel` provides an interface for functions that we can use like so:

```ruby
# JSON_EACH("{table}"."{column}")
json_each = Arel::Nodes::NamedFunction.new("JSON_EACH", [arel_table[column_name]])
```

{:.notice}
**Note:** `arel_table` is available to us as we will be executing this code in the context of an ActiveRecord model concern.

With our `json_each` expression object ready, we could built the `.unique_tags` method like so:

```ruby
# SELECT DISTINCT value FROM "{table}", JSON_EACH("{table}"."{column}")
define_singleton_method :"unique_#{method_name}" do |conditions = "true"|
  select('value')
    .from([arel_table, json_each])
    .distinct
    .pluck('value')
    .sort
end
```

In order to setup our `.with_any_tags` scope, we simply need a method builder like this:

```ruby
# SELECT "{table}".* FROM "{table}" WHERE EXISTS (SELECT 1 FROM JSON_EACH("{table}"."{column}") WHERE value IN ({values}) LIMIT 1)
scope :"with_any_#{method_name}", ->(*items) {
  values = array_columns_sanitize_list(items)
  overlap = Arel::SelectManager.new(json_each)
    .project(1)
    .where(Arel.sql('value').in(values))
    .take(1)
    .exists
  
  where overlap
}
```

And the corresponding `.with_all_tags` scope looks like this:

```ruby
# SELECT "{table}".* FROM "{table}" WHERE (SELECT COUNT(DISTINCT value) FROM JSON_EACH("{table}"."{column}") WHERE value IN ({values})) = {values.size};
scope :"with_all_#{method_name}", ->(*items) {
  values = array_columns_sanitize_list(items)
  count = Arel::SelectManager.new(json_each)
    .project(Arel.sql('value').count(distinct = true))
    .where(Arel.sql('value').in(values))
  contains = Arel::Nodes::Equality.new(count, values.size)
  
  where contains
}
```

I won't paste each method here. You can find them in [the Gist](https://gist.github.com/fractaledmind/af105bc2f102bfba50b3f83adef5283e) I have provided to accompany this post. The idea is to demonstrate how we can map the SQL queries we need to `Arel`-based Ruby code.

We wrap all of this in an `ArrayColumns` model concern and we are good to go. With a well-written schema migration and a single model concern, we have the ability to define "array column" types in our SQLite database, as well as query them as if they were an associated table, without the cost of a `JOIN`.

Hopefully, this demonstrates the power and flexibility available in SQLite. Even without all of the native features and data types provided by Postgres, a little bit of ingenuity can provide equivalent functionality.

{:.notice}
You can find the full code for the model concern detailed in [this Gist](https://gist.github.com/fractaledmind/af105bc2f102bfba50b3f83adef5283e). Check out the full script to see the full set of test cases as well.

- - -

## All posts in this series

* [Part 1 — branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %})
* [Part 2 — fine-tuning SQLite configuration]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %})
* [Part 3 — loading extensions]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %})
* [Part 4 — setting up `Litestream`]({% link _posts/2023-09-09-enhancing-rails-sqlite-setting-up-litestream.md %})
* [Part 5 — optimizing compilation]({% link _posts/2023-09-10-enhancing-rails-sqlite-optimizing-compilation.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Part 6 — array columns]({% link _posts/2023-09-12-enhancing-rails-sqlite-array-columns.md %})
* [Part 7 — local snapshots]({% link _posts/2023-09-14-enhancing-rails-sqlite-local-snapshots.md %})
* [Part 8 — Rails improvements]({% link _posts/2023-09-15-enhancing-rails-sqlite-activerecord-adapter-improvements.md %})


- - -

[^1]: To understand what each method does more precisely, consider the [test suite](https://gist.github.com/fractaledmind/af105bc2f102bfba50b3f83adef5283e#file-array_columns_test-rb) that I wrote.
[^2]: We use `IN`, even with a single value, to allow the query to accommodate both singular and plural values easily.