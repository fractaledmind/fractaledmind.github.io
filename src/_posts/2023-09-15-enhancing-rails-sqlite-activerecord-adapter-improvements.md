---
series: Enhancing your Rails app with SQLite
title: ActiveRecord adapter improvements
date: 2023-09-15
tags:
  - code
  - ruby
  - rails
  - sqlite
---

[Ruby on Rails](https://rubyonrails.org) continues to be a lively and thriving framework. Unfortunately, when it comes to the database adapters, a vast majority of the attention and effort has been focused on the MySQL and PosgreSQL adapters. [SQLite](https://www.sqlite.org/index.html) supports a large percentage of the database features that Rails has added support for in the recent past. So, today I am starting to do my part to make the developer experience of using Rails with SQLite as seamless and powerful as possible. Maybe you'll join me?

<!--/summary-->

- - -

Today I opened my first two pull requests to begin improving Rails' `SQLite3Adapter`:

* [support `||` concatenation in default functions](https://github.com/rails/rails/pull/49287)
* [support `RETURNING` values on `INSERT`](https://github.com/rails/rails/pull/49290)

And this blog post is my personal declaration of intent—I am going to do my part in bringing as many of the newer ActiveRecord features to the SQLite adapter. From [composite foreign keys](https://www.sqlite.org/foreignkeys.html#fk_composite) to [virtual columns](https://www.sqlite.org/gencol.html), with [auto-populated columns](https://github.com/rails/rails/pull/48241) thrown in, SQLite will no longer lag behind PostgreSQL and MySQL.

But, this is no simple task, and I'm certain there are many more features beyond the ones I have bumped into. So, this post is also a call to action. If you are a SQLite and Rails enthusiast, join me! Let's start leveling up the `SQLite3Adapter` together. Because one step at a time, we can help surge the tide of SQLite in production usage for Rails applications.

- - -

That's it for today. But be on the lookout for a post on how supporting Rails' `RETURNING` feature opens up the possibility for [<abbr title="Universally Unique Identifiers">UUIDs</abbr>](https://en.wikipedia.org/wiki/Universally_unique_identifier) or [<abbr title="Universally Unique Lexicographically Sortable Identifiers">ULIDs</abbr>](https://github.com/ulid/spec) as primary keys.

- - -

## All posts in this series

* [Part 1 — branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %})
* [Part 2 — fine-tuning SQLite configuration]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %})
* [Part 3 — loading extensions]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %})
* [Part 4 — setting up `Litestream`]({% link _posts/2023-09-09-enhancing-rails-sqlite-setting-up-litestream.md %})
* [Part 5 — optimizing compilation]({% link _posts/2023-09-10-enhancing-rails-sqlite-optimizing-compilation.md %})
* [Part 6 — array columns]({% link _posts/2023-09-12-enhancing-rails-sqlite-array-columns.md %})
* [Part 7 — local snapshots]({% link _posts/2023-09-14-enhancing-rails-sqlite-local-snapshots.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Part 8 — Rails improvements]({% link _posts/2023-09-15-enhancing-rails-sqlite-activerecord-adapter-improvements.md %})
* [Part 9 — performance metrics]({% link _posts/2023-09-21-enhancing-rails-sqlite-performance-metrics.md %})
* [Part 10 — custom primary keys]({% link _posts/2023-09-22-enhancing-rails-sqlite-ulid-primary-keys.md %})
* [Part 11 — more Rails improvements]({% link _posts/2023-09-26-enhancing-rails-sqlite-more-activerecord-adapter-improvements.md %})
* [Part 12 — table schema and metadata]({% link _posts/2023-11-13-enhancing-rails-sqlite-table-schema-and-metadata.md %})
* [Part 13 — prefixed ULID keys]({% link _posts/2023-12-13-enhancing-rails-sqlite-prefixed-ulids.md %})
* [Part 14 — installing extensions]({% link _posts/2023-12-24-enhancing-rails-installing-extensions.md %})
