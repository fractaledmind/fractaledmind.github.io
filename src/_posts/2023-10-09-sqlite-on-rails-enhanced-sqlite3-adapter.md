---
title: SQLite on Rails
subtitle: Rails 7.1 and enhanced SQLite3 adapter
date: 2023-10-09
tags:
  - code
  - ruby
  - rails
  - sqlite
---

Rails version 7.1 was [released recently](https://rubyonrails.org/2023/10/5/Rails-7-1-0-has-been-released) and it includes a number of enhancements to the [SQLite](https://www.sqlite.org/index.html) ActiveRecord adapter. There are a few enhancements that didn't quite make it into the 7.1 release though, so today I am releasing the [`activerecord-enhancedsqlite3-adapter`](https://rubygems.org/gems/activerecord-enhancedsqlite3-adapter) gem.

<!--/summary-->

- - -

As a part of the [Rails 7.1 release](https://edgeguides.rubyonrails.org/7_1_release_notes.html), I was able to ship a number of enhancements to the `SQLite3Adapter` for ActiveRecord:

* [support auto-populating columns and custom primary keys](https://github.com/rails/rails/pull/49290)
* [support `||` concatenation in default functions](https://github.com/rails/rails/pull/49287)
* [performance tune default connection configurations](https://github.com/rails/rails/pull/49349)
* [add `retries` option as alternative to `timeout`](https://github.com/rails/rails/pull/49352)

These enhancements come in addition to the improvements made to the `sqlite3-ruby` gem:

* [allow users to set compile-time flags](https://github.com/sparklemotion/sqlite3-ruby/pull/402)
* [ensure all installations use the `WAL` journal mode and `NORMAL` synchronous setting](https://github.com/sparklemotion/sqlite3-ruby/pull/408)

These improvements to Ruby's ecosystem give Ruby and Rails one of the very best out-of-the-box SQLite experiences. But, this is only the beginning.

I have two additional pull requests for Rails that add additional ActiveRecord features to the `SQLite3Adapter`:

* [support generated columns](https://github.com/rails/rails/pull/49346)
* [support deferred foreign keys](https://github.com/rails/rails/pull/49376)

Both will be in a future release of Rails, but I wanted to make these features available for any and all Rails 7.1 applications today. So, today I am releasing the initial version of the [`activerecord-enhancedsqlite3-adapter`](https://rubygems.org/gems/activerecord-enhancedsqlite3-adapter) gem. This gems patches the `SQLite3Adapter` to add these features plus a couple small others. You can find the source code on [my GitHub](https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter).

In addition to the new Rails 7.1 features, this gem enhances the `SQLite3Adapter` by providing these 4 additional features:

* generated columns,
* deferred foreign keys,
* `PRAGMA` tuning,
* and extension loading

This gem hooks into your Rails application to enhance the `SQLite3Adapter` automatically. No setup required!

Once installed, you can take advantage of the added features.

### Generated columns

You can now create `virtual` columns, both stored and dynamic. The [SQLite docs](https://www.sqlite.org/gencol.html) explain the difference:

> Generated columns can be either VIRTUAL or STORED. The value of a VIRTUAL column is computed when read, whereas the value of a STORED column is computed when the row is written. STORED columns take up space in the database file, whereas VIRTUAL columns use more CPU cycles when being read.

The default is to create dynamic/virtual columns.

```ruby
create_table :virtual_columns, force: true do |t|
  t.string :name
  t.virtual :upper_name, type: :string, as: "UPPER(name)", stored: true
  t.virtual :lower_name, type: :string, as: "LOWER(name)", stored: false
  t.virtual :octet_name, type: :integer, as: "LENGTH(name)"
end
```

### Deferred foreign keys

You can now specify whether or not a foreign key should be deferrable, whether `:deferred` or `:immediate`.

`:deferred` foreign keys mean that the constraint check will be done once the transaction is committed and allows the constraint behavior to change within transaction. `:immediate` means that constraint check is immediate and allows the constraint behavior to change within transaction. The default is `:immediate`.

```ruby
add_reference :person, :alias, foreign_key: { deferrable: :deferred }
add_reference :alias, :person, foreign_key: { deferrable: :deferred }
```

### `PRAGMA` tuning

Pass any [`PRAGMA` key-value pair](https://www.sqlite.org/pragma.html) under a `pragmas` list in your `config/database.yml` file to ensure that these configuration settings are applied to all database connections.

```yaml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  pragmas:
    # level of database durability, 2 = "FULL" (sync on every write), other values include 1 = "NORMAL" (sync every 1000 written pages) and 0 = "NONE"
    # https://www.sqlite.org/pragma.html#pragma_synchronous
    synchronous: "FULL"
```

### Extension loading

There are a number of [SQLite extensions available as Ruby gems](https://github.com/asg017/sqlite-ecosystem). In order to load the extensions, you need to install the gem (`bundle add {extension-name}`) and then load it into the database connections. In order to support the latter, this gem enhances the `config/database.yml` file to support an `extensions` array. For example, to install and load [an extension](https://github.com/asg017/sqlite-ulid) for supporting [<abbr title="Universally Unique Lexicographically Sortable Identifiers">ULIDs</abbr>](https://github.com/ulid/spec), we would do:

```shell
$ bundle add sqlite_ulid
```

then

```yaml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  extensions:
    - sqlite_ulid
```

- - -

All in all, there has never been a better time to start a new Rails application using SQLite.

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
* [Part 10 — custom primary keys]({% link _posts/2023-09-22-enhancing-rails-sqlite-ulid-primary-keys.md %})
* [Part 11 — more Rails improvements]({% link _posts/2023-09-26-enhancing-rails-sqlite-more-activerecord-adapter-improvements.md %})
* [Part 12 — table schema and metadata]({% link _posts/2023-11-13-enhancing-rails-sqlite-table-schema-and-metadata.md %})
