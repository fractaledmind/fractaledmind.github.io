---
series: SQLite on Rails
title: Introducing <code>litestream-ruby</code>
date: 2023-12-12
tags:
  - code
  - ruby
  - rails
  - sqlite
---

I have already detailed why [Litestream](https://litestream.io) is [essential for SQLite on Rails applications]({% link _posts/2023-09-09-enhancing-rails-sqlite-setting-up-litestream.md %}). But, as that original post makes clear, getting this utility setup and working in production requires some systems administration. Rails applications deserve better. Thus, [`litestream-ruby`](https://github.com/fractaledmind/litestream-ruby).

<!--/summary-->

- - -

One of my favorite qualities of using SQLite in my Rails application is that I can bundle the database file, database engine, and database configuration all directly into my application repository. This is a key tenet of the [12 Factor App](https://12factor.net) methodology, and it makes it easy to deploy my applications to and run on any environment, while also ensuring that my local development environment is as close to production as possible.

But, as I have [previously detailed]({% link _posts/2023-09-09-enhancing-rails-sqlite-setting-up-litestream.md %}), basically any production SQLite on Rails application _should_ setup a streaming replication solution like [Litestream](https://litestream.io) in order to ensure that the database file is backed up and can be restored in the event of a failure. But, Litestream is a standalone utility that must be installed and configured separately from the Rails application. This is a problem and it hinders the beautiful monolithic simplicity of SQLite on Rails applications.

So, I decided to see what could be done about it. I knew that it was possible for a Ruby gem to bundle together binary executables targeted at various platforms.[^1] After some research and experimentation, I was able to setup an automated process to grab the platform-specific executables that the upstream Litestream repository provides for each release and package them up into a Ruby gem. This became became version `0.1.0` of the [`litestream-ruby`](https://github.com/fractaledmind/litestream-ruby) gem, which you can find on [RubyGems](https://rubygems.org). as simply [`litestream`](https://rubygems.org/gems/litestream).

Next, I wanted to make it possible for Rails applications to get up and running with Litestream as quickly and easily as possible. So, I created a Rails generator that will create a `config/litestream.yml` configuration file, add a `config/initializers/litestream.rb` file, and create or add to a `Procfile` to run the Litestream replication process alongside your app. This became version `0.2.0` of [`litestream-ruby`](https://github.com/fractaledmind/litestream-ruby) and makes the default usage of Litestream as simple as:

```bash
bundle add litestream
bin/rails generate litestream:install
```

The "magic" that allows everything to work smoothly comes from the fact that the generated Litestream configuration file uses environment variables to define each of the configuration options. By exposing those same options via the Ruby configuration in the `config/initializers/litestream.rb` file, the gem can finally provide a `litestream:replicate` Rake task that will run the Litestream replication process with the necessary environment variables set from the Ruby configuration. This allows you to configure Litestream using your Rails application's encrypted credentials, for example.

However, if you need manual control over the Litestream configuration, you can manually edit the `config/litestream.yml` file. The full range of possible configurations are covered in Litestream's [configuration reference](https://litestream.io/reference/config/). Then, you can take full manual control over the replication process and simply run the `litestream replicate --config config/litestream.yml` command to start the Litestream process. Since the gem installs the native executable via Bundler, the `litestream` command will be available via `bundle exec litestream`. The full set of commands available to the `litestream` executable are covered in Litestream's [command reference](https://litestream.io/reference/). Currently, only the `replicate` command is provided as a rake task by the gem.

For this initial release, I have focused the gem on just getting a basic Litestream setup running. So, the generated Litestream YAML configuration file only supports a single database file. However, I have already started work on adding support for multiple databases to the gem. The generated gem configuration initializer also suggests using Rails' encrypted credentials to store and manage your storage bucket secrets. This is just an example; you can absolutely manage your secrets however you want, including just using the environment variables directly. If you have any suggestions for how to make the Rails integration more flexible or more useful, please open an issue on [GitHub](https://github.com/fractaledmind/litestream-ruby/issues).

This is only the beginning, but nonetheless, this is a major step forward for SQLite on Rails applications. Every single SQLite on Rails application can now quickly and easily ensure that their database(s) have streaming backups in production from day one. I hope that you will give it a try and let me know what you think. Open an issue on [GitHub](https://github.com/fractaledmind/litestream-ruby/issues) or reach out to me on [Twitter](https://twitter.com/fractaledmind) if you have any questions or feedback.

- - -

## All posts in this series

* [SQLite on Rails — September State of the Union]({% link _posts/2023-09-27-sqlite-on-rails-september-state-of-the-union.md %})
* [SQLite on Rails — Introducing the enhanced adapter gem]({% link _posts/2023-10-09-sqlite-on-rails-enhanced-sqlite3-adapter.md %})
* [SQLite on Rails — Improving the enhanced adapter gem]({% link _posts/2023-12-06-sqlite-on-rails-improving-the-enhanced-sqlite3-adapter.md %})
* [SQLite on Rails — Improving concurrency]({% link _posts/2023-12-11-sqlite-on-rails-improving-concurrency.md %})
* {:.bg-[var(--tw-prose-bullets)]}[SQLite on Rails — Introducing `litestream-ruby`]({% link _posts/2023-12-12-sqlite-on-rails-litestream-ruby.md %})
* [SQLite on Rails — Isolated connection pools]({% link _posts/2024-04-11-sqlite-on-rails-isolated-connection-pools.md %})
* [SQLite on Rails — Loading extensions]({% link _posts/2024-12-09-sqlite-on-rails-loading-extensions.md %})

- - -

[^1]: Thanks to [Mike Dalessio](https://twitter.com/flavorjones?ref=fractaledmind.github.io)'s work on both the [`sqlite3-ruby`](https://github.com/sparklemotion/sqlite3-ruby) gem and the [`tailwindcss-rails`](https://github.com/rails/tailwindcss-rails) gem. In fact, it was his [pull request](https://github.com/rails/tailwindcss-rails/pull/96) to the `tailwindcss-rails` gem that provided me with a clear enough path to do the same thing with `Litestream`.
