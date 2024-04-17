---
title: Update to Litestream gem
date: 2024-04-17
tags:
  - code
  - ruby
  - rails
  - gem
---

Version 0.5.0 of the [Litestream](https://github.com/fractaledmind/litestream-ruby) is out. The 0.5.x versions of the gem adds a new `restore` command, making it simple to restore a database from a remote backup. This is a huge feature that makes Litestream even more useful.

<!--/summary-->

- - -

You can find the full changelog [here](https://github.com/fractaledmind/litestream-ruby/blob/main/CHANGELOG.md). The gem is available on [RubyGems](https://rubygems.org/gems/litestream) and the source code is on [GitHub](https://github.com/fractaledmind/litestream-ruby).

You can restore any replicated database at any point using the gem's provided `litestream:restore` rake task. This rake task requires that you specify which specific database you want to restore. As with the `litestream:replicate` task, you pass arguments to the rake task via argument forwarding. For example, to restore the production database, you would run:

```shell
bin/rails litestream:restore -- --database=storage/production.sqlite3
# or
bundle exec rake litestream:restore -- --database=storage/production.sqlite3
```

You can restore any of the databases specified in your `config/litestream.yml` file. The `--database` argument should be the path to the database file you want to restore and must match the value for the `path` key of one of your configured databases. The `litestream:restore` rake task will automatically load the configuration file and set the environment variables before calling the Litestream executable.

If you need to pass arguments through the rake task to the underlying `litestream` command, that can be done with additional forwarded arguments:

```shell
bin/rails litestream:replicate -- --database=storage/production.sqlite3 --if-db-not-exists
```

You can forward arguments in whatever order you like, you simply need to ensure that the `--database` argument is present. You can also use either a single-dash `-database` or double-dash `--database` argument format. The Litestream `restore` command supports the following options, which can be passed through the rake task:

```
-o PATH
    Output path of the restored database.
    Defaults to original DB path.

-if-db-not-exists
    Returns exit code of 0 if the database already exists.

-if-replica-exists
    Returns exit code of 0 if no backups found.

-parallelism NUM
    Determines the number of WAL files downloaded in parallel.
    Defaults to 8

-replica NAME
    Restore from a specific replica.
    Defaults to replica with latest data.

-generation NAME
    Restore from a specific generation.
    Defaults to generation with latest data.

-index NUM
    Restore up to a specific WAL index (inclusive).
    Defaults to use the highest available index.

-timestamp TIMESTAMP
    Restore to a specific point-in-time.
    Defaults to use the latest available backup.

-config PATH
    Specifies the configuration file.
    Defaults to /etc/litestream.yml

-no-expand-env
    Disables environment variable expansion in configuration file.
```

Whether you need to restore a copy of the production database locally to debug an issue on your development machine, or you need to spin up a new production machine with the latest data, the `litestream:restore` rake task makes it easy to restore a database from a remote backup.

- - -

If you bump into any problem, please don't hesitate to [open an issue](https://github.com/fractaledmind/litestream-ruby/issues/new).
