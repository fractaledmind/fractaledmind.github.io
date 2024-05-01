---
series: Enhancing your Rails app with SQLite
title: Installing extensions
date: 2023-12-24
tags:
  - code
  - ruby
  - rails
  - sqlite
---

In a [previous post]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %}), we discussed how to load SQLite extensions distributed as Ruby gems into a Ruby on Rails application. Unfortunately, there aren't many SQLite extensions that are distributed as Ruby gems. So, in this post, we dig into how to install a wider range of SQLite extensions into our apps.

<!--/summary-->

- - -

While SQLite is essentially feature complete when it comes to the SQL standard, there are still some times when you have specific needs for your database that SQLite doesn't support. Luckily, SQLite offers a rich extension ecosystem. And even luckier still, there is an [(unofficial) package manager](https://github.com/nalgeon/sqlpkg-cli)—`sqlpkg`—and a corresponding [(unofficial) package registry](https://sqlpkg.org). As of today, there are **62** extensions available in the registry. So, how can we install and load any of these extensions into our Rails app?[^1]

The `sqlpkg` package manager handles installing the appropriate executable file for the operating system it is running on. The stumbling block was installing the `sqlpkg` executable itself for the appropriate operating system. Having used the [webi](https://webinstall.dev) installer for other projects, I decided to try and add a webi installer for `sqlpkg`. After reading the source for a number of other webi installers, I cobbled together a working installer for `sqlpkg`. You can see the [pull request here](https://github.com/webinstall/webi-installers/pull/651). This made it simpler to install the `sqlpkg` executable into your host machine, but it still recalled a manual step to install the extension into your app. My goal is always to embed as much of the configuration of my app into the app itself, so I wanted to find a way to install the extension into the app itself.

While stewing on this problem for weeks, I started pursuing other projects. One of those projects was providing a RubyGems wrapper for the [Litestream](https://litestream.io) utility. I used that project as a learning opportunity to learn how to bundle an executable into a Ruby gem that Bundler would naturally install correctly for the operating system of the host machine. I wrote more about that process and that gem [previously]({% link _posts/2023-12-12-sqlite-on-rails-litestream-ruby.md %}), but that basic approach was precisely what I wanted for the `sqlpkg` executable. So, I set out to create a Ruby gem that would install the `sqlpkg` executable into your Rails app and released the [`sqlpkg-ruby` gem](https://github.com/fractaledmind/sqlpkg-ruby) a couple of days ago.

Now it is possible to install the `sqlpkg` package manager CLI into your application. The only requisite next step it to ensure that SQLite extensions installed via `sqlpkg` are similarly installed and embedded into your application and then properly loaded into your app's SQLite database.

So, I added a Railtie to the `sqlpkg-ruby` gem that exposes a `rails generate sqlpkg:install` generator. The installer does three things:

1. creates an empty `.sqlpkg/` directory, which ensures that `sqlpkg` will run in "project scope" and not "global scope" (see [the `sqlpkg-cli` README](https://github.com/nalgeon/sqlpkg-cli#project-vs-global-scope) for more information)
2. creates an empty `sqlpkg.lock` file, which `sqlpkg` will use to store information about the installed packages (see [the `sqlpkg-cli` README](https://github.com/nalgeon/sqlpkg-cli#lockfile) for more information)
3. creates an initializer file at `config/initializers/sqlpkg.rb` which will patch the `SQLite3Adapter` to automatically load the extensions installed in the `.sqlpkg/` directory whenever the database is opened

That initializer is the key to making this all work. It looks like this:

```ruby
module SqlpkgLoader
  def configure_connection
    super

    @raw_connection.enable_load_extension(true)
    Dir.glob(".sqlpkg/**/*.{dll,so,dylib}") do |extension_path|
      @raw_connection.load_extension(extension_path)
    end
    @raw_connection.enable_load_extension(false)
  end
end

ActiveSupport.on_load(:active_record_sqlite3adapter) do
  prepend SqlpkgLoader
end
```

Taken together, these three steps make it possible to install SQLite extensions into your Rails app. Once properly integrated into your Rails application, you can install any extension listed on the `sqlpkg` registry by executing:

```shell
$ bundle exec sqlpkg install PACKAGE_IDENTIFIER
```

When exploring the the `sqlpkg` registry, the `PACKAGE_IDENTIFIER` needed to install an extension is the title found in the cards, always in owner/name format. For example, to install the [`sqlite-vss` extension](https://github.com/asg017/sqlite-vss), which provides support for vector similarity search, you would find this package card on the [sqlpkg.org](https://sqlpkg.org) site:

<img loading="lazy" src="{{ '/images/sqlpkg-package-example.png' | relative_url }}" alt="" style="width: 100%" />

You would then install the extension into your Rails app by executing:

```shell
$ bundle exec sqlpkg install asg017/vss
```

You will see output similar to the following in your terminal:

```shell
(project scope)
> installing asg017/vss...
✓ installed package asg017/vss to .sqlpkg/asg017/vss
```

In addition to the new files in the `.sqlpkg/` directory, you will also see a new entry in your `sqlpkg.lock` file:

```json
{
    "packages": {
        "asg017/vss": {
            "owner": "asg017",
            "name": "vss",
            "version": "v0.1.2",
            "specfile": "https://github.com/nalgeon/sqlpkg/raw/main/pkg/asg017/vss.json",
            "assets": {} -- # removed for brevity
        }
    }
}
```

And that's it. You can now use the `sqlite-vss` extension in your Rails app. You can do the same with any of the 62 SQLite extensions available on the [`sqlpkg` registry](https://sqlpkg.org). Any downloaded extensions will automatically be loaded into your app's SQLite database when it is opened and thus available for use.

I think this is another big step forward for SQLite on Rails. I hope you find it useful. If you have any questions or comments, please feel free to reach out to me on [Twitter](https://twitter.com/fractaledmind) or in the [GitHub repo](https://github.com/fractaledmind/sqlpkg-ruby).

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
* [Part 13 — prefixed ULID keys]({% link _posts/2023-12-13-enhancing-rails-sqlite-prefixed-ulids.md %})
* {: .bg-[var(--tw-prose-bullets)]}[Part 14 — installing extensions]({% link _posts/2023-12-24-enhancing-rails-installing-extensions.md %})

- - -

[^1]: For a general introduction to installing SQLite extensions, read [this post](https://antonz.org/install-sqlite-extension/).
