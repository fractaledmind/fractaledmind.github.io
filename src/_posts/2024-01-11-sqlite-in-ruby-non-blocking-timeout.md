---
series: SQLite in Ruby
title: Non-blocking timeout
date: 2024-01-11
tags:
  - code
  - ruby
  - sqlite
---

Last month I released version 0.4.0 of the [`activerecord-enhancedsqlite3-adapter`](https://rubygems.org/gems/activerecord-enhancedsqlite3-adapter) gem, which added support for a non-blocking `busy_timeout` to the SQLite adapter in Rails. As with all of my lower-level SQLite work, the goal is always to push these solutions into the foundations of the ecosystem so that everyone can benefit from them. In this case, I'm happy that the `busy_timeout` feature has made its way into the [`sqlite3`](https://github.com/sparklemotion/sqlite3-ruby) gem, which is the most popular SQLite gem for Ruby.

<!--/summary-->

- - -

I wrote last month about why [SQLite needs a non-blocking `busy_timeout` to improve concurrency]({% link _posts/2023-12-11-sqlite-on-rails-improving-concurrency.md %}). The problem with the [`sqlite3`](https://github.com/sparklemotion/sqlite3-ruby) gem lies in the interaction between SQLite's C code and Ruby code. While SQLite is running the `busy_timeout` function in its C code, our Ruby code that triggered the `busy_timeout` function is still running, and so still holding the lock to Ruby's GVL (Global VM Lock). That means that no other Ruby code can run while SQLite is running the `busy_timeout` function. This negates the concurrency coordination that the `busy_timeout` function is trying to achieve.

Since changing the nature of the interaction between SQLite's C code and Ruby code is a major undertaking, I wanted to find a way to solve this problem without changing the nature of the interaction. I was able to do this by implementing a `busy_handler` in Ruby that respects a timeout value but also releases the GVL between retry attempts. This allows other Ruby code to run while SQLite is waiting for the connection.

You can read the full details of the implementation in the [pull request](https://github.com/sparklemotion/sqlite3-ruby/pull/456) that added the feature to the `sqlite3` gem. But here is the method itself:

```ruby
def busy_handler_timeout=( milliseconds )
  timeout_seconds = milliseconds.fdiv(1000)

  busy_handler do |count|
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    if count.zero?
      @timeout_deadline = now + timeout_seconds
    elsif now > @timeout_deadline
      next false
    else
      sleep(0.001)
    end
  end
end
```

The idea, as you might have guessed, is to offer an alternative to the `busy_timeout` which utilizes a custom `busy_handler`. Thus, the new method is named `busy_handler_timeout`—creative, right?

This feature is now in `main`, but a new feature of the `sqlite3` gem has not yet been released (as of the time I am writing this). I will definitely let you know which version of the `sqlite3` gem includes this feature. In the meantime, you can use the `activerecord-enhancedsqlite3-adapter` gem to get this feature in your Rails app.

The next step is to use this feature in Rails. Once a new version of the `sqlite3` gem is released, I'll open a pull request that wires up the `timeout` value in the `config/database.yml` file to this new `busy_handler_timeout` feature. This will allow you to set a timeout value in your Rails app as you have always done, but connection retries won't block concurrent threads.

I'm happy to see this feature make its way into the `sqlite3` gem, and I'm looking forward to seeing it in Rails soon. I hope you find it useful in your apps!
