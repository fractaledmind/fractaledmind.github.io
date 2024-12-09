---
series: SQLite on Rails
title: Loading extensions
date: 2024-12-09
tags:
  - code
  - ruby
  - rails
  - sqlite
---

Rails continues to expand its lead as the single best platform for building web applications backed by SQLite! You can now load extensions directly from the `database.yml` file. This now means you have quick and easy access to the full range of SQLite extensions. This is a major step forward from [the previous way]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %}), which required writing a custom initializer or using the enhanced adapter.

<!--/summary-->

- - -

The [PR](https://github.com/rails/rails/pull/53827) that was recently merged for this feature was implemented by the one and only Mike Dalessio (aka [@flavorjones](https://x.com/flavorjones)).

It builds on the work that [Mike did](https://github.com/sparklemotion/sqlite3-ruby/pull/586) in the `sqlite3-ruby` driver to make loading extensions much easier.

These two features together allow your `config/database.yml` to look like:

```yaml
development:
  adapter: sqlite3
  extensions:
    - SQLean::UUID # module name responding to `.to_path`
    - .sqlpkg/nalgeon/crypto/crypto.so # or a filesystem path
    - <%= AppExtensions.location %> # or ruby code returning a path
```

Also, if you are using the SQLite3 gem directly, you can load extensions when you initialize your database connection:

```ruby
db = SQLite3::Database.new(
  ":memory:",
  extensions: [
    "/path/to/extension",
    SQLean::Crypto
  ]
)
```

To work with SQLite extensions in Ruby, you have two great gems to lean on. The first packages up [the `sqlean` collection of extenions](https://antonz.org/sqlean/) gathered by [Anton Zhiyanov](https://x.com/ohmypy) into a simple to download gem—[`sqlean-ruby`](https://github.com/flavorjones/sqlean-ruby) (this gem is built and maintained by none other than Mike)

The other—[`sqlpkg-ruby`](https://github.com/fractaledmind/sqlpkg-ruby)—makes [the `sqlpkg` package manager](https://sqlpkg.org) (another project by [Anton Zhiyanov](https://x.com/ohmypy)) available to Rails apps and Ruby projects.

Both gems are now properly setup to take advantage of this new feature. So, jump onto Rails `main` and start taking advantage of the added power of SQLite extensions.

To use an extension from the `sqlean` collection, simply pass the appropriate constant name, e.g.:

```yaml
development:
  adapter: sqlite3
  extensions:
    - SQLean::UUID
```

To use an extension installed via the `sqlpkg` utility, call the `.path_for` method with the extension name, e.g.:

```yaml
development:
  adapter: sqlite3
  extensions:
    - <%= Sqlpkg.path_for("asg017/ulid") %>
```

- - -

## All posts in this series

* [SQLite on Rails — September State of the Union]({% link _posts/2023-09-27-sqlite-on-rails-september-state-of-the-union.md %})
* [SQLite on Rails — Introducing the enhanced adapter gem]({% link _posts/2023-10-09-sqlite-on-rails-enhanced-sqlite3-adapter.md %})
* [SQLite on Rails — Improving the enhanced adapter gem]({% link _posts/2023-12-06-sqlite-on-rails-improving-the-enhanced-sqlite3-adapter.md %})
* [SQLite on Rails — Improving concurrency]({% link _posts/2023-12-11-sqlite-on-rails-improving-concurrency.md %})
* [SQLite on Rails — Introducing `litestream-ruby`]({% link _posts/2023-12-12-sqlite-on-rails-litestream-ruby.md %})
* [SQLite on Rails — Isolated connection pools]({% link _posts/2024-04-11-sqlite-on-rails-isolated-connection-pools.md %})
* {:.bg-[var(--tw-prose-bullets)]}[SQLite on Rails — Loading extensions]({% link _posts/2024-12-09-sqlite-on-rails-loading-extensions.md %})