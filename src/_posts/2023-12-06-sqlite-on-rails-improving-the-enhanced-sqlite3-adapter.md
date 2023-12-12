---
title: SQLite on Rails
subtitle: Improving the enhanced SQLite3 adapter
date: 2023-12-06
tags:
  - code
  - ruby
  - rails
  - sqlite
---

Two months ago I released the [`activerecord-enhancedsqlite3-adapter`](https://rubygems.org/gems/activerecord-enhancedsqlite3-adapter) gem, which adds a number of enhancements to the `SQLite3Adapter` for ActiveRecord. Today I am releasing version 0.3.0 of the gem, which adds an improved implemenation to handle `timeout`s.

<!--/summary-->

- - -

The [`activerecord-enhancedsqlite3-adapter`](https://rubygems.org/gems/activerecord-enhancedsqlite3-adapter) gem allows the community to push forward with enhancements to the `SQLite3Adapter` for ActiveRecord without the slower cadence of Rails releases. The gem is a stop-gap until the enhancements are merged into Rails. The gem is also a place to experiment with new features that may or may not make it into Rails.

As of version `0.2.0` this gem enhances the `SQLite3Adapter` by providing these 4 additional features:

* generated columns,
* deferred foreign keys,
* `PRAGMA` tuning,
* and extension loading

Today I am releasing version `0.3.0` of the gem, which adds an improved implemenation to handle `timeout`s. You can find the pull request for this feature [here](https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter/pull/3).

So, what was the issue and how does this improve things?

In Rails 7.1, there is a new `retries` option available in the `config/database.yml` file. This option allows you to specify the number of times to retry a query before a `SQLite3::BusyException` is raised. This is an alternative to the `timeout` option.

We added the `retries` option becaues the backoff algorithm used by SQLite with the `timeout` option is not ideal. In fact, it can be quite slow. SQLite will wait 1 millisecond, then 2, then 5, 10, 15, 20, 25, 25, 25, 50, 50, and then 100ms for each retry thereafter until the timeout is reached and the `Busy` exception is thrown. The biggest issue here is that these backoffs are handled by the SQLite C code, and the way that the `sqlite3-ruby` gem integrates with the SQLite C code means that the Ruby GIL (global interpreter lock) is not released during these backoff periods. This means that other Ruby threads that are waiting on the same database will not be able to advance.

The `retries` option is a better alternative because it does allow the Ruby GIL to be released between retries. However, the `retries` option is not without its own issues. The biggest issue is that it is difficult to determine what the correct limit is. If you set the limit too low, then you will get `SQLite3::BusyException`s when you don't want it. If you set the limit too high, then you will have to wait longer than necessary for the query to complete. The other issue is that it can be slow in a multi-thread environment, as you will execute the Ruby `busy_handler` proc many, many, many times (can be up to 1 million times 🤯) from within a C control frames.

So, what can be an alternative?

In this pull request, I have implemented a new `timeout` mechanism that is similar to the `retries` option, in that it implements a Ruby `busy_handler` proc. This means that the Ruby GIL is released between retries. However, it still uses the `timeout` option and will throw a `Busy` exception if the database takes longer than the `timeout` amount to connect. This also means that the `timeout` option can be used in a multi-thread environment without the performance issues of the `retries` option.

This provides a superior alternative which still respects a timeout, but it allows for other threads/fibers to take control while the current context is blocked on a write lock.

For the curious, here is the implementation:

```ruby
timeout = self.class.type_cast_config_to_integer(@config[:timeout])
@raw_connection.busy_handler do |count|
  timed_out = false
  # capture the start time of this blocked write
  @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) if count == 0
  # keep track of elapsed time every 100 iterations (to lower load)
  if count % 100 == 0
    @elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time
    # fail if we exceed the timeout value (captured from the timeout config option, converted to seconds)
    timed_out = @elapsed_time > timeout
  end
  if timed_out
    false # this will cause the BusyException to be raised
  else
    sleep 0.001 # sleep 1 millisecond (or whatever)
  end
end
```

Of course, this isn't as performant as having the backoff in C, but releasing the GIL between retries is a big win.

Go and download the latest version of the gem and give it a try. You can also find the source code on [GitHub](https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter).

- - -

## All posts in this series

* [SQLite on Rails — September State of the Union]({% link _posts/2023-09-27-sqlite-on-rails-september-state-of-the-union.md %})
* [SQLite on Rails — Introducing the enhanced adapter gem]({% link _posts/2023-10-09-sqlite-on-rails-enhanced-sqlite3-adapter.md %})
* {:.bg-[var(--tw-prose-bullets)]}[SQLite on Rails — Improving the enhanced adapter gem]({% link _posts/2023-12-06-sqlite-on-rails-improving-the-enhanced-sqlite3-adapter.md %})
* [SQLite on Rails — Improving concurrency]({% link _posts/2023-12-11-sqlite-on-rails-improving-concurrency.md %})
* [SQLite on Rails — Introducing `litestream-ruby`]({% link _posts/2023-12-12-sqlite-on-rails-litestream-ruby.md %})
