---
title: SQLite Quick Tip
subtitle: Multiple Databases
date: 2024-01-02
tags:
  - code
  - ruby
  - rails
  - sqlite
---

When building a full-featured Rails application, you will want not just a database to store your model data; you will want a job queue backend, a cache backend, maybe even a pubsub backend. When building a Rails app leveraging the power and simplicity of SQLite, you will likely wonder how best to architect these various services? [37signals](https://37signals.com) has been releasing new gems to use solid-state storage via relational databases. They default to using one database to back all of these services, but they use MySQL. How should we handle this with SQLite?

<!--/summary-->

- - -

The short answer is that you should use separate database files for each service. This is what [Litestack](https://github.com/oldmoe/litestack) does, and for good reason. You notably increase your concurrency throughput by isolating each service to its own database. While it is a myth that [linear writes do not scale]({% link _posts/2023-12-05-sqlite-myths-linear-writes-do-not-scale.md %}), serializing all of your writes across each of these services is very likely to produce noticeable performance effects.

So, how do we setup our separate databases for each service? Here is my `config/database.yml` file for a recent project that uses [`SolidQueue`](https://github.com/basecamp/solid_queue) as the job backend:[^1]

```yaml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

primary: &primary
  <<: *default
  database: storage/<%= ENV.fetch("RAILS_ENV") %>.sqlite3

queue: &queue
  <<: *default
  migrations_paths: db/queue_migrate
  database: storage/queue.sqlite3

development:
  primary:
    <<: *primary
    database: storage/<%= `git branch --show-current`.chomp || 'development' %>.sqlite3
  queue: *queue

test:
  <<: *primary
  database: db/test.sqlite3

production:
  primary: *primary
  queue: *queue
```

Then, in my `config/application.rb` file, I simply have this:

```ruby
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue, reading: :queue } }
```

This approach can be extended when using [`SolidCache`](https://github.com/rails/solid_cache) as well. When I add `SolidCache` to my application, I will report back on precisely what my `database.yml` and `application.rb` files look like to wire up this separate database.

I will be writing up a larger post on my first impressions of working with `SolidQueue` in a SQLite on Rails application, but hopefully for now this quick tip is useful.

- - -

[^1]: Yes, I am also using [branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %}) in this app 😇.
