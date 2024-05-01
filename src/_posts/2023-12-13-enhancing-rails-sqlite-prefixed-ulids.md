---
series: Enhancing your Rails app with SQLite
title: Prefixed ULID keys
date: 2023-12-13
tags:
  - code
  - ruby
  - rails
  - sqlite
---

I have written previously about [using custom primary keys]({% link _posts/2023-09-22-enhancing-rails-sqlite-ulid-primary-keys.md %}) for your Rails app when using SQLite. In this post, I want to show how you can use the same [`sqlite-ulid`](https://github.com/asg017/sqlite-ulid) extension to create prefixed ULIDs. Shout-out to [Andy Stewart](https://github.com/airblade) who [suggested this](https://github.com/asg017/sqlite-ulid/issues/5#issuecomment-1761619264).

<!--/summary-->

- - -

In that [previous post]({% link _posts/2023-09-22-enhancing-rails-sqlite-ulid-primary-keys.md %}), we saw that the [new feature](https://github.com/rails/rails/pull/49290) to add support for custom primary keys to SQLite for Rails applications allowed us to wire up Alex Garcia's [`sqlite-ulid`](https://github.com/asg017/sqlite-ulid) extension (via the [Ruby gem](https://rubygems.org/gems/sqlite-ulid)) to have [<abbr title="Universally Unique Lexicographically Sortable Identifiers">ULIDs</abbr>](https://github.com/ulid/spec) as primary keys.

[Andy Stewart](https://github.com/airblade) pointed out that the `sqlite-ulid` extension also supports [prefixed ULIDs](https://github.com/asg017/sqlite-ulid/blob/main/docs.md#ulid_with_prefix) and thus we could use this function to mimic the behavior of [Chris Oliver](https://twitter.com/excid3?ref=fractaledmind.github.io)'s [`prefixed_ids`](https://github.com/excid3/prefixed_ids) gem.

Here is Andy's approach:

> * I started with a Rails 7.1 application.
> * I installed your [activerecord-enhancedsqlite3-adapter](https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter) gem.
> * I installed this repo's sqlite-ulid gem and updated my database config, exactly as [described here](https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter#extension-loading).
> * I wrote migrations as outlined above:
>
> ```ruby
> create_table :things, id: false do |t|
>   t.primary_key :id, :string, default: -> { "ULID_WITH_PREFIX('thing')" }
>   t.belongs_to :widget, null: false, foreign_key: true, type: :string
> end
> ```
>
> All in all, a straightforward and painless process :)
>
> My only previous experience with prefixed IDs was using @excid's [prefixed_ids](https://github.com/excid3/prefixed_ids) gem on a Rails app with postgresql. That worked well, though it needs to inject code into your models, and your application code needs to be at least slightly aware of it, e.g. special finders.
>
> Comparing the two approaches, I much prefer having the database, rather than the model, handle ID generation. My application code doesn't have to know anything about the models' IDs. It's much simpler. (And ULIDs seem at least as good as hashids, if not better, for my purposes.)

— [source](https://github.com/asg017/sqlite-ulid/issues/5#issuecomment-1761619264)

I agree with Andy's assessment. I also prefer having the database handle the ID generation. It's simpler and more performant. And this is a wonderful example of the kind of flexibility that comes when you embrace SQLite, its extension ecosystem, and the new features that Rails is adding to support SQLite (or that are currently only added in the [`activerecord-enhancedsqlite3-adapter`](https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter) gem).

Thanks Andy for such a great write-up of an excellent approach to using prefixed ULIDs with Rails and SQLite!

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
* {: .bg-[var(--tw-prose-bullets)]}[Part 13 — prefixed ULID keys]({% link _posts/2023-12-13-enhancing-rails-sqlite-prefixed-ulids.md %})
* [Part 14 — installing extensions]({% link _posts/2023-12-24-enhancing-rails-installing-extensions.md %})
