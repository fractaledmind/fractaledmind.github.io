---
series: SQLite on Rails
title: Improving concurrency
date: 2023-12-11
tags:
  - code
  - ruby
  - rails
  - sqlite
---

Two months ago I released the [`activerecord-enhancedsqlite3-adapter`](https://rubygems.org/gems/activerecord-enhancedsqlite3-adapter) gem, which adds a number of enhancements to the `SQLite3Adapter` for ActiveRecord. Today I am releasing version 0.4.0 of the gem, which allows your Rails application to work in Puma's clustered mode with multiple workers without getting those dreaded database deadlock errors.

<!--/summary-->

- - -

If you have used SQLite in a production Rails application, you have probably run into the following error:

```shell
ActiveRecord::StatementInvalid (SQLite3::BusyException: database is locked)
```

You will also likely have struggled to resolve this issue, because you can't reproduce locally. If you search for information about this error, you might find posts [like this](https://www.beekeeperstudio.io/blog/how-to-solve-sqlite-database-is-locked-error), which don't provide any guidance at all relavant to a web application running in production. Nor do they explain why this occurs in production but not in development.

After bumping into this issue a few too many times myself, I decided to dig in, determine precisely what is happening here, and find a solution. And, as of version 0.4.0 of the [`activerecord-enhancedsqlite3-adapter`](https://rubygems.org/gems/activerecord-enhancedsqlite3-adapter) gem, I have integrated that solution into the gem so that your Rails application can seamlessly and automatically resolve this issue.

So, what is happening here? Why does this error occur in production but not in development? And, how does the gem resolve this issue? Let's dig in.

- - -

As I have written [about]({% link _posts/2023-12-05-sqlite-myths-linear-writes-do-not-scale.md %}) [before]({% link _posts/2023-10-13-sqlite-myths-concurrent-writes-can-corrupt-the-database.md %}), SQLite does not allow for concurrent writes. That means that if two processes, threads, or fibers try to write to the database at the same time, one of them will fail and throw the `SQLite3::BusyException: database is locked` error.

But, SQLite is flexible and resilient software, so it doesn't simply throw an exception and halt if a connection tries to write to the database while another connection holds a lock. Instead, it leans on the `busy_handler` callback to determine what to do. The `busy_handler` callback is a function that you can register with SQLite that will be called whenever a connection tries to write to the database while another connection holds a lock. The `busy_handler` callback can then decide what to do, including throwing an exception, retrying the write, or waiting for the lock to be released.

SQLite itself comes with a default `busy_handler` callback function called `busy_timeout`, which you can pass a timeout value to. If a connection tries to write to the database while another connection holds a lock, the `busy_timeout` function will retry with a kind of exponential backoff, waiting for the lock to be released. If it can't connect within the timeout period, it will then throw the busy exception.

When you set the `timeout` option in your `config/database.yml` file, Rails will pass that value to SQLite's `busy_timeout` function. So, if you set the `timeout` value to 5000 milliseconds, then SQLite will wait for 5000 milliseconds before throwing the busy exception.

This _should_ allow multiple processes/threads/fibers to coordinate the linear order that they will write to the database without throwing any busy exceptions. But, it doesn't. Why not?

The issue lies in the interaction between SQLite's C code and our Ruby code.[^1] While SQLite is running the `busy_timeout` function in its C code, our Ruby code that triggered the `busy_timeout` function is still running, and so still holding the lock to Ruby's GVL (Global VM Lock). That means that no other Ruby code can run while SQLite is running the `busy_timeout` function. This negates the concurrency coordination that the `busy_timeout` function is trying to achieve.

This is why, in version 0.3.0, I added [a custom `busy_handler` function]({% link _posts/2023-12-06-sqlite-on-rails-improving-the-enhanced-sqlite3-adapter.md %}) defined in Ruby. Since this `busy_handler` is executed in the context of Ruby code and not C code, we can release the GVL while waiting for the lock to be released. This allows other Ruby code to run while SQLite is waiting for the lock to be released. This solves one half of the issue that leads to those pesky busy exceptions.

The other half of the issue is what led to version 0.4.0. And a shout-out to Mohammad A. Ali ([@oldmoe](https://twitter.com/oldmoe?ref=fractaledmind.github.io)) for helping me to understand this issue and how to resolve it. The other issue has to do with the default way that SQLite handles transactions.

By default, SQLite uses a deferred transaction mode. This means that SQLite will not acquire a lock on the database until the first write operation in a transaction. In a context where you only have one connection and transactions regularly mix reading and writing, this is great for performance, because it means that SQLite doesn't have to acquire a lock on the database for every transaction, only for transactions that actually write to the database. The problem is that this is not the context Rails apps are in.

In production Rails application, you will have multiple connections to the database from multiple threads/fibers. Moreover, Rails will only wrap database queries that _write_ to the database in a transaction. And, when we write our own explicit transactions, it is essentially a guarantee that this transaction will include a write operation. So, in a production Rails application, SQLite will be working with multiple connections and every transaction will include a write operation. This is the opposite of the context that SQLite's default deferred transaction mode is optimized for.

Luckily, again, SQLite is flexible and resilient software. So, it allows you to change the transaction mode. In addition to deferred, SQLite also supports immediate transaction modes. In immediate transaction mode, SQLite will acquire a lock on the database as soon as a transaction is started. But why does it make such a difference to acquire a lock on the database as soon as a transaction is started vs waiting until the first write operation?

The answer is where experience and experimentation comes in, because the SQLite docs do not make this explicitly clear (though it does make sense once you understand what is happening). The issue is that when SQLite attempts to acquire a lock _in the middle_ of a transaction and there is another connection with a lock, SQLite **cannot retry** the transaction. Retrying in the middle of a transaction _could_ break the serializable isolation that SQLite guarantees. Thus, when SQLite hits a busy exception when trying to upgrade a transaction, it doesn't fallback to the `busy_handler`, it immediately throws the error and halts that transaction.

So, even when we have a custom Ruby `busy_handler` that will release the GVL while waiting for SQLite's lock to be released, SQLite will ignore it if it hits a busy exception when trying to upgrade a transaction's lock.

So, in order to resolve this second core issue that leads to "database locked" errors in production, we need to set SQLite's default transaction mode to immediate for our Rails application.

And, in version 0.4.0 of the `activerecord-enhancedsqlite3-adapter` gem, I have done just that. The gem automatically configures ActiveRecord's SQLite to use `IMMEDIATE` transactions. And because every transaction will attempt to acquire the lock at the start of the transaction, if a connection attempts to start a transaction while another connection is holding the lock, it will  invoke the `busy_handler` callback instead of simply erroring and halting. And, because the `busy_handler` callback is defined in Ruby, it will release the GVL while waiting for the lock to be released. This allows other Ruby code to run while SQLite is waiting for the lock to be released.

And, with that, we have resolved the two core issues that lead to "database locked" errors in production. Clearly, this is a complex issue, and while I'm happy that Rails applications can now properly configure and work with SQLite to achieve concurrency bliss with this gem, I also strongly believe that these features should be built into Rails itself.

After the holiday break, I will be opening pull requests to Rails to add these features. Once we get these features into Rails itself, we can rest easy knowing that _every_ Rails application that uses SQLite will be able to achieve concurrency bliss.

- - -

## All posts in this series

* [SQLite on Rails — September State of the Union]({% link _posts/2023-09-27-sqlite-on-rails-september-state-of-the-union.md %})
* [SQLite on Rails — Introducing the enhanced adapter gem]({% link _posts/2023-10-09-sqlite-on-rails-enhanced-sqlite3-adapter.md %})
* [SQLite on Rails — Improving the enhanced adapter gem]({% link _posts/2023-12-06-sqlite-on-rails-improving-the-enhanced-sqlite3-adapter.md %})
* {:.bg-[var(--tw-prose-bullets)]}[SQLite on Rails — Improving concurrency]({% link _posts/2023-12-11-sqlite-on-rails-improving-concurrency.md %})
* [SQLite on Rails — Introducing `litestream-ruby`]({% link _posts/2023-12-12-sqlite-on-rails-litestream-ruby.md %})
* [SQLite on Rails — Isolated connection pools]({% link _posts/2024-04-11-sqlite-on-rails-isolated-connection-pools.md %})
* [SQLite on Rails — Loading extensions]({% link _posts/2024-12-09-sqlite-on-rails-loading-extensions.md %})

- - -

[^1]: This limitation of relying on SQLite's `busy_timeout` was first (to my knowledge) [written about](http://nerdjusttyped.blogspot.com/2014/11/threaded-sqlite-access-and-ruby-sqlite.html) in 2014 by Timur Alperovich.
