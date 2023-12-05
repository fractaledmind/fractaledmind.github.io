---
title: Enhancing your Rails app with SQLite
subtitle: Local snapshots
date: 2023-09-14
tags:
  - code
  - ruby
  - rails
  - sqlite
---

Today we consider how [SQLite](https://www.sqlite.org/index.html) can enhance working with our database in our [Ruby on Rails](https://rubyonrails.org) applications. The the database is simply a file, snapshots and clones are both simple and powerful.

<!--/summary-->

- - -

When working on a web application, there are various tasks you will have _at some point_ that involve your database. You will want to take a snapshot of your database. You will want to restore your database to a previously saved snapshot. You will want to clone your production database locally. You will want to merge your production data into your existing local database. You will want to merge data from [another, branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %}) into your current branch's database. You get the idea. When working with database engines that run in a separate process, often on a separate computer, these tasks can be somewhat cumbersome, if not practically impossible. Sure [PostgreSQL](https://www.postgresql.org) has [`pg_dump`](https://www.postgresql.org/docs/current/app-pgdump.html) and [`pg_restore`](https://www.postgresql.org/docs/15/app-pgrestore.html), but I wouldn't call this straight-forward:[^1]

```shell
pg_dump -U postgres -h localhost -p 5432 -F c -b -v -f /dev/null DB_NAME 2>&1
```

With SQLite, each of these actions is, in my opinion, quite straight-forward. So, let's walk through them one by one and see for ourselves.

{:.notice}
**Note:** All code will be in a Rake namespace, as we will eventually be preparing a task file to put in our Rails application's `/lib/tasks` directory so that we can quickly and easily accomplish these tasks on a day-to-day basis within our apps.

## Snapshotting your database

A database snapshot is just a copy of your data at a particular moment in time. When your entire database is simply a file on your filesystem, taking a snapshot is as simple as:

```ruby
namespace :snap do
  task :create do
    @snapshot_dir = Rails.root.join('storage/snapshots')
    @db_path = ActiveRecord::Base.connection_db_config.database
    @db_name = @db_path.rpartition('/').last.remove('.sqlite3')

    timestamp = DateTime.now.to_formatted_s(:number)
    snap_name = "#{@db_name}-#{timestamp}.backup"
    snap_path = Pathname(@snapshot_dir).join(snap_name)

    FileUtils.copy_file(@db_path, snap_path)
  end
end
```

There is some boilerplate here, but the core is simply a `cp` call to copy the database file. We get the current ActiveRecord database path, prepare a timestamped snapshot file name, and just copy the database file over.

Snapshots are useful as they give you the ability to create save points with your schema and data that are easy to jump back to later.

## Restoring a snapshot

Once you have a snapshot, you may need to restore your database to that point in time. Typically, you will take a snapshot before you begin an experiment that will require altering your database schema or data or both. You want to be able to revert your changes if needed, so you take a snapshot first and revert later. With simple SQLite files, you can probably guess how snapshot restoring is going to go:

```ruby
namespace :snap do
  task :restore do
    @snapshot_dir = Rails.root.join('storage/snapshots')
    @db_path = ActiveRecord::Base.connection_db_config.database
    @db_name = @db_path.rpartition('/').last.remove('.sqlite3')
    @snaps = Pathname(@snapshot_dir)
      .children
      .select do |path|
        path.extname == ".backup" &&
        path.basename.to_s.include?(@db_name)
      end
      .sort
      .reverse

    latest_snapshot = @snaps.first

    FileUtils.remove_file(@db_path)
    FileUtils.copy_file(latest_snapshot, @db_path)
  end
end
```

Restoring a snapshot itself is straight-forward. We take the most recent snapshot of our current database. Then, we delete the current database file and copy the snapshot file into the current database file's place. Again, because we are working with simple files, we are fundamentally just putting some nice boilerplate around `cp` copy commands.

- - -

Because our database is just a file on the file system, working with our production data can also be simplified. I will write about that in a future post. For now, I think that this exploration of how we can snapshot and restore local databases is sufficient for one post. With a bit of cleanup and polish, we can create a `/lib/tasks/dbspan.rake` file that provides the following usage:

```shell
bin/rails db:snap:list
bin/rails db:snap:create
bin/rails db:snap:restore
```

This will set the foundation that will then allow us to add on the ability to work with our production database as well.

{:.notice}
You can find the full code for the model concern detailed in [this Gist](https://gist.github.com/fractaledmind/4fe00d226715e8ce7209a525f3d9d98e).

- - -

## All posts in this series

* [Part 1 — branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %})
* [Part 2 — fine-tuning SQLite configuration]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %})
* [Part 3 — loading extensions]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %})
* [Part 4 — setting up `Litestream`]({% link _posts/2023-09-09-enhancing-rails-sqlite-setting-up-litestream.md %})
* [Part 5 — optimizing compilation]({% link _posts/2023-09-10-enhancing-rails-sqlite-optimizing-compilation.md %})
* [Part 6 — array columns]({% link _posts/2023-09-12-enhancing-rails-sqlite-array-columns.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Part 7 — local snapshots]({% link _posts/2023-09-14-enhancing-rails-sqlite-local-snapshots.md %})
* [Part 8 — Rails improvements]({% link _posts/2023-09-15-enhancing-rails-sqlite-activerecord-adapter-improvements.md %})
* [Part 9 — performance metrics]({% link _posts/2023-09-21-enhancing-rails-sqlite-performance-metrics.md %})
* [Part 10 — custom primary keys]({% link _posts/2023-09-22-enhancing-rails-sqlite-ulid-primary-keys.md %})
* [Part 11 — more Rails improvements]({% link _posts/2023-09-26-enhancing-rails-sqlite-more-activerecord-adapter-improvements.md %})
* [Part 12 — table schema and metadata]({% link _posts/2023-11-13-enhancing-rails-sqlite-table-schema-and-metadata.md %})

- - -

[^1]: This command is taken from the [`pg-snap`](https://github.com/iseth/pg-snap/) repository, which provides a simpler CLI utility for working with Postgres snapshots.
