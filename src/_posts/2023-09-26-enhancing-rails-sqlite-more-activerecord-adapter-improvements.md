---
title: Enhancing your Rails app with SQLite
subtitle: More ActiveRecord adapter improvements
date: 2023-09-26
tags:
  - code
  - ruby
  - rails
  - sqlite
---

After opening [my first few ActiveRecord PRs]({% link _posts/2023-09-15-enhancing-rails-sqlite-activerecord-adapter-improvements.md %}) last week, I kept going and opened 4 more to bring more key improvements to the [SQLite](https://www.sqlite.org/index.html) adapter.

<!--/summary-->

- - -

All in all, I have opened 3 pull requests to bring larger, existing ActiveRecord features to the `SQLite3Adapter`:

* [support auto-populating columns and custom primary keys](https://github.com/rails/rails/pull/49290)
* [support generated columns](https://github.com/rails/rails/pull/49346)
* [support deferred foreign keys](https://github.com/rails/rails/pull/49376)

In addition, I have also opened 3 additional pull requests to add some new, `SQLite`-specific features:

* [support `||` concatenation in default functions](https://github.com/rails/rails/pull/49287)
* [performance tune default connection configurations](https://github.com/rails/rails/pull/49349)
* [add `retries` option as alternative to `timeout`](https://github.com/rails/rails/pull/49352)

I am chatting with the Core team and _trying_ to get all of this work into the upcoming 7.1 release, but nothing is set in stone yet.

Regardless, I thought it would be useful to take the next few posts and dive into the details and use-cases for each of these features in turn. I already started this by writing up how to setup [custom primary keys]({% link _posts/2023-09-22-enhancing-rails-sqlite-ulid-primary-keys.md %}) in your Rails app.

Up next, I will write up how to use generated columns in your Rails app. So, keep your eyes out 👀

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
* {:.bg-[var(--tw-prose-bullets)]}[Part 11 — more Rails improvements]({% link _posts/2023-09-26-enhancing-rails-sqlite-more-activerecord-adapter-improvements.md %})
* [Part 12 — table schema and metadata]({% link _posts/2023-11-13-enhancing-rails-sqlite-table-schema-and-metadata.md %})
