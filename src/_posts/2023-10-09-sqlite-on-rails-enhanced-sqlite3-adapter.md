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

* [SQLite on Rails — September State of the Union]({% link _posts/2023-09-27-sqlite-on-rails-september-state-of-the-union.md %})
* {:.bg-[var(--tw-prose-bullets)]}[SQLite on Rails — Introducing the enhanced adapter gem]({% link _posts/2023-10-09-sqlite-on-rails-enhanced-sqlite3-adapter.md %})
* [SQLite on Rails — Improving the enhanced adapter gem]({% link _posts/2023-12-06-sqlite-on-rails-improving-the-enhanced-sqlite3-adapter.md %})
* [SQLite on Rails — Improving concurrency]({% link _posts/2023-12-11-sqlite-on-rails-improving-concurrency.md %})
