---
title: Enhancing your Rails app with SQLite
subtitle: Loading extensions
date: 2023-09-08
tags:
  - code
  - ruby
  - rails
  - sqlite
---

Once again we are enhancing our [Ruby on Rails](https://rubyonrails.org) applications to power up [SQLite](https://www.sqlite.org/index.html). In this post, we dig into how to load extensions into our SQLite database.

<!--/summary-->

- - -

Personally, I find SQLite to be essentially feature complete, but sometimes you have specific needs for your database that SQLite doesn't support. Luckily, SQLite offers a rich extension ecosystem. There is an [(unofficial) package manager](https://sqlpkg.org)—`sqlpkg`, an [(unofficial) standard library](https://github.com/nalgeon/sqlean)—`sqlean`, and a rich collection of [Alex Garcia extensions](https://github.com/asg017/sqlite-ecosystem). For a general introduction to installing SQLite extensions, read [this post](https://antonz.org/install-sqlite-extension/).

We want, however, a simple way to install and load SQLite extensions in a Rails application. Unfortunately, at the moment the `sqlpkg` and `sqlean` extension collections do not provide Ruby gem releases. Fortunately though, Alex Garcia _does_ release each of his extensions as a Ruby gem. You can find all of his extensions under his [RubyGems' profile](https://rubygems.org/profiles/asg017). Let's focus on how to make it easy to install and load one of _these_ extensions.

The installation is simple, as these are Ruby gems. We can simply use `bundle add {extension-name}`. Loading is the tricky part.

Before extensions are loaded, we have to first enable extension loading for the SQLite database. The [`SQLite3` Ruby adapter](https://github.com/sparklemotion/sqlite3-ruby) provides a `#enable_load_extension` method for this purpose. Alex Garcia's extensions then provide a `.load` method on the Ruby extension class that will load the extension. So, in full we would need to do the following to load an extension in Ruby:

```ruby
@raw_connection.enable_load_extension(true)
SqliteExtension.load(@raw_connection)
@raw_connection.enable_load_extension(false)
```

- - -

We want to enhance Rails, though, to make the developer experience clean. So, how can we expose this functionality more elegantly? Luckily, in our [previous post]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %}) we introduced an enhancement to the `SQLite3` adapter which provides a hook for configuring the database from options set in the `/config/database.yml` file. We can add support for an `extensions` section, which will accept an array of extension names. We can then add to our `configure_connection` method to iterate over these extension names and load them:

```ruby
module RailsExt
  module SQLite3Adapter
    def configure_connection
      # ...
      
      @raw_connection.enable_load_extension(true)
      @config[:extensions].each do |extension_name|
        require extension_name
        extension_classname = extension_name.camelize
        extension_class = extension_classname.constantize
        extension_class.load(@raw_connection)
      rescue LoadError
        Rails.logger.error("Failed to find the SQLite extension gem: #{extension_name}. Skipping...")
      rescue NameError
        Rails.logger.error("Failed to find the SQLite extension class: #{extension_classname}. Skipping...")
      end
      @raw_connection.enable_load_extension(false)
    end
  end
end
```

After `bundle add {extension-name}`, we can simply add the extension to the `extensions` section in the `/config/database.yml` file. Our `RailsExt::SQLite3Adapter` will then handle the rest, dealing with possible errors as well. This means we can have a `default` section like so to load [an extension](https://github.com/asg017/sqlite-ulid) for supporting [<abbr title="Universally Unique Lexicographically Sortable Identifiers">ULIDs</abbr>](https://github.com/ulid/spec):

```yaml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  # connection attempts to make immediately before throwing a BUSY exception
  retries: 1000
  extensions:
    - sqlite_ulid
```

What I love about this approach to loading SQLite extensions is that extensions are _explicitly_ installed (in the `Gemfile`) and loaded (in the `database.yml` file), plus it naturally builds on top of our existing enhancement to the SQLite adapter. In total, our enhanced adapter now supports [pragma configuration]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %}) as well as extension loading. Plus, our database configuration powers a [Git branch-bound database branching approach]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %}).

This provides a rich and powerful set of functionality for local development. In the next post, we will dig into how to install and setup [`Litestream`](https://litestream.io) so that our production database will have point-in-time backups and recovery. Exiting things ahead!

> You can find the files we have written throughout this post in [this Gist](https://gist.github.com/fractaledmind/3565e12db7e59ab46f839025d26b5715/266030cb6053f05f234509c39fd07ed3d59f09c0)


- - -

## All posts in this series

* [Part 1 — branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %})
* [Part 2 — fine-tuning SQLite configuration]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Part 3 — loading extensions]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %})
* [Part 4 — setting up `Litestream`]({% link _posts/2023-09-09-enhancing-rails-sqlite-setting-up-litestream.md %})
* [Part 5 — optimizing compilation]({% link _posts/2023-09-10-enhancing-rails-sqlite-optimizing-compilation.md %})