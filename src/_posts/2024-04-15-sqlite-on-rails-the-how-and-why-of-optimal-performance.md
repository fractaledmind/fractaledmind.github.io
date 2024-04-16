---
title: SQLite on Rails
subtitle: The how and why of optimal performance
date: 2024-04-15
tags:
  - code
  - ruby
  - rails
  - sqlite
---

<img src="{{ '/images/wrocloverb-2024/001-alt.png' | relative_url }}" alt="" />

Over the last year or so, I have found myself on a journey to deeply understand how to run Rails applications backed by SQLite performantly and resiliently. In that time, [I]({% link _posts/2024-04-11-sqlite-on-rails-isolated-connection-pools.md %}) [have]({% link _posts/2023-12-11-sqlite-on-rails-improving-concurrency.md %}) [learned]({% link _posts/2024-01-02-sqlite-quick-tip-multiple-databases.md %}) [various]({% link _posts/2023-09-10-enhancing-rails-sqlite-optimizing-compilation.md %}) [lessons]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %}) that I want to share with you all now. I want to walk through where the problems lie, why they exist, and how to resolve them.

And to start, we have to start with the reality that…

<img src="{{ '/images/wrocloverb-2024/022.png' | relative_url }}" alt="" />

Unfortunately, running SQLite on Rails out-of-the-box isn’t viable today. But, with a bit of tweaking and fine-tuning, you can ship a very performant, resilient Rails application with SQLite. And my personal goal for [Rails 8](https://github.com/rails/rails/milestone/87) is to make the out-of-the-box experience fully production-ready.

And so, I have spent the last year digging into the details to uncover what the issues are with SQLite on Rails applications as they exist today and how to resolve those issues. So, let me show you everything you need to build a production-ready SQLite-driven Rails application today…

<img src="{{ '/images/wrocloverb-2024/023.png' | relative_url }}" alt="" />

… Yeah, not too bad, huh? These three commands will set your app up for production success. You will get massive performance improvements, additional SQL features, and point-in-time backups. This is how you build a production-ready SQLite on Rails application today.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/024.png' | relative_url }}" alt="" />

… And that’s all you need. Thank you. And I could genuinely stop the talk here. You know how and why to run SQLite in production with Rails. Those two gems truly are the headline, and if you take-away only 1 thing from this talk, let it be that slide.

But, given that this is a space for diving deep into complex topics, I want to walk through the exact problems and solutions that these gems package up.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/025.png' | relative_url }}" alt="" />

To keep this journey practical and concrete, we will be working on [a demo app](http://github.com/fractaledmind/wrocloverb-2024) called “Lorem News”. It is a basic Hacker News clone with posts and comments made by users but all of the content is Lorem Ipsum. This codebase will be the foundation for all of our examples and benchmarks.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/026.png' | relative_url }}" alt="" />

Let’s observe how our demo application performs. We can use the [`oha` load testing CLI](https://github.com/hatoo/oha) and the [benchmarking routes](https://github.com/fractaledmind/wrocloverb-2024/blob/main/app/controllers/benchmarking_controller.rb) built into the app to simulate user activity in our app. Let’s start with a simple test where we sent 1 request after another for 5 seconds to our `post#create` endpoint.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/027.png' | relative_url }}" alt="" />

Not bad. We see solid RPS and every request is successful. The slowest request is many times slower than the average, which isn't great, but even that request isn't above 1 second. I've certainly seen worse. Maybe I was wrong to say that the out-of-the-box experience with Rails and SQLite isn't production-ready as of today.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/028.png' | relative_url }}" alt="" />

Let’s try the same load test but send 4 concurrent requests in waves for 5 seconds.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/029.png' | relative_url }}" alt="" />

All of a sudden things aren’t looking as good any more. We see a percentage of our requests are returning 500 error code responses.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/030.png' | relative_url }}" alt="" />

If we look at our logs, we will see the first major problem that SQLite on Rails applications need to tackle …

<img loading="lazy" src="{{ '/images/wrocloverb-2024/031.png' | relative_url }}" alt="" />

… the [`SQLITE_BUSY` exception](https://www.sqlite.org/rescode.html#busy).

In order to ensure only one write operation occurs at a time, SQLite uses a write lock on the database. Only one connection can hold the write lock at a time. If you have multiple connections open to the database, this is the exception that is thrown when one connection attempts to acquire the write lock but another connection still holds it. Without any configuration, a web app with a connection pool to a SQLite database will have numerous errors in trying to respond to requests.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/032.png' | relative_url }}" alt="" />

As your Rails application is put under more and more concurrent load, you will see a steady increase in the percentage of requests that error with the `SQLITE_BUSY` exception. What we need is a way to allow write queries to queue up and resolve linearly without immediately throwing an exception.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/033.png' | relative_url }}" alt="" />

Enter [immediate transactions](https://www.sqlite.org/lang_transaction.html#immediate). Because of the global write lock, SQLite needs different transaction modes for different possible behaviors.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/034.png' | relative_url }}" alt="" />

Let’s consider this transaction.

By default, SQLite uses a deferred transaction mode. This means that SQLite will not acquire the lock until a write operation is made inside the transaction. For this transaction, this means that the write lock won’t attempt to be acquired until …

<img loading="lazy" src="{{ '/images/wrocloverb-2024/035.png' | relative_url }}" alt="" />

… this line here, the third operation within the transaction.

In a context where you only have one connection or you have a large amount of transactions that only do read operations, this is great for performance, because it means that SQLite doesn’t have to acquire a lock on the database for every transaction, only for transactions that actually write to the database. The problem is that this is not the context Rails apps are in.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/036.png' | relative_url }}" alt="" />

In a production Rails application, not only will you have multiple connections to the database from multiple threads, Rails will only wrap database queries that write to the database in a transaction. And, when we write our own explicit transactions, it is essentially a guarantee that we will include a write operation. So, in a production Rails application, SQLite will be working with multiple connections and every transaction will include a write operation. This is the opposite of the context that SQLite’s default deferred transaction mode is optimized for.

Our `SQLITE_BUSY` exceptions are arising from the fact that when SQLite attempts to acquire the write lock in the middle of a transaction and there is another connection holding the lock, SQLite cannot safely retry that transaction-bound query. Retrying in the middle of a transaction could break the serializable isolation that SQLite guarantees. Thus, when SQLite hits a busy exception when trying to upgrade a transaction, it can’t queue that query to retry acquiring the write lock later; it immediately throws the error and halts that transaction.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/037.png' | relative_url }}" alt="" />

If we instead begin the transaction by explicitly declaring this an immediate transaction, SQLite will be able to queue this query to retry acquiring the write lock again later. This gives SQLite the ability to serialize the concurrent queries coming in by relying on a basic queuing system, even when some of those queries are wrapped in transactions.

So, how do we ensure that our Rails application makes all transactions immediate? …

<img loading="lazy" src="{{ '/images/wrocloverb-2024/038.png' | relative_url }}" alt="" />

… As of [version 1.6.9](https://github.com/sparklemotion/sqlite3-ruby/releases/tag/v1.6.9), the [`sqlite3-ruby` gem](https://github.com/sparklemotion/sqlite3-ruby) allows you to configure the default transaction mode. Since Rails passes any top-level keys in your `database.yml` configuration directly to the `sqlite3-ruby` database initializer, you can easily ensure that Rails’ SQLite transactions are all run in IMMEDIATE mode.

Let’s make this change in our demo app and re-run our simple load test.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/039.png' | relative_url }}" alt="" />

With one simple configuration change, our Rails app now handle concurrent load without throwing nearly any 500 errors! Though we do see some errors start to creep in at 16 concurrent requests. This is a signal that something is still amiss.

If we look now at the latency results from our load tests, we will see that this new problem quickly jumps out.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/040.png' | relative_url }}" alt="" />

As the number of concurrent requests approaches and then surpasses the number of Puma workers our application has, our p99 latency skyrockets. But, interestingly, the actual request time stays stable, even under 3 times the concurrent load of our Puma workers. We will also see that once we start getting some requests taking approximately 5 seconds, we also start getting some 500 `SQLITE_BUSY` responses as well.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/041.png' | relative_url }}" alt="" />

If that 5 seconds is ringing a bell, it is because that is precisely what our timeout is set to. It seems that as our application is put under more concurrent load than the number of Puma workers it has, more and more database queries are timing out. This is our next problem to solve.

This timeout option in our `database.yml` configuration file will be mapped to one of SQLite’s configuration pragmas…

<img loading="lazy" src="{{ '/images/wrocloverb-2024/042.png' | relative_url }}" alt="" />

SQLite’s [`busy_timeout` configuration option](https://www.sqlite.org/pragma.html#pragma_busy_timeout). Instead of throwing the `BUSY` exception immediately, you can tell SQLite to wait up to the timeout number of milliseconds. SQLite will attempt to re-acquire the write lock using a kind of exponential backoff, and if it cannot acquire the write lock within the timeout window, then and only then will the `BUSY` exception be thrown. This allows a web application to use a connection pool, with multiple connections open to the database, but not need to resolve the order of write operations itself. You can simply push queries to SQLite and allow SQLite to determine the linear order that write operations will occur in. The process will look something like this:

<img loading="lazy" src="{{ '/images/wrocloverb-2024/043.png' | relative_url }}" alt="" />

Imagine our application sends 4 write queries to the database at the same moment.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/044.png' | relative_url }}" alt="" />

One of those four will acquire the write lock first and run. The other three will be queued, running the backoff re-acquire logic. Once the first write query completes, …

<img loading="lazy" src="{{ '/images/wrocloverb-2024/045.png' | relative_url }}" alt="" />

… one of the queued queries will attempt to re-acquire the lock and successfully acquire the lock and start running. The other two queries will continue to stay queued and keep running the backoff re-acquire logic. Again, when the second write query completes, …

<img loading="lazy" src="{{ '/images/wrocloverb-2024/046.png' | relative_url }}" alt="" />

… another query will have its backoff re-acquire logic succeed and will start running. Our last query is still queued and still running its backoff re-acquire logic.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/047.png' | relative_url }}" alt="" />

Once the third query completes, our final query can acquire the write lock and run. So long as no query is forced to wait for longer than the timeout duration, SQLite will resolve the linear order of write operations on its own. This queuing mechanism is essential to avoiding `SQLITE_BUSY` exceptions. But, there is a major performance bottleneck lurking in the details of this feature for Rails applications.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/048.png' | relative_url }}" alt="" />

Because SQLite is embedded within your Ruby process and the thread that spawns it, care must be taken to release Ruby's global VM lock (GVL) when the Ruby-to-SQLite bindings execute SQLite’s C code. [By design](https://github.com/sparklemotion/sqlite3-ruby/issues/287#issuecomment-615346313), the `sqlite3-ruby` gem does not release the GVL when calling SQLite. For the most part, this is a reasonable decision, but for the `busy_timeout`, it greatly hampers throughput.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/049.png' | relative_url }}" alt="" />

Instead of allowing another Puma worker to acquire Ruby’s GVL while one Puma worker is waiting for the database query to return, that first Puma worker will continue to hold the GVL even while the Ruby operations are completely idle waiting for the database query to resolve and run. This means that concurrent Puma workers won’t even be able to send concurrent write queries to the SQLite database and SQLite’s linear writes will force our Rails app to process web requests somewhat linearly as well. This radically slows down the throughput of our Rails app.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/050.png' | relative_url }}" alt="" />

What we want is to allow our Puma workers to be able to process requests concurrently, passing the GVL amongst themselves as they wait on I/O. So, for Rails app using SQLite, this means that we need to unlock the GVL whenever a write query gets queued and is waiting to acquire the SQLite write lock.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/051.png' | relative_url }}" alt="" />

Luckily, in addition to the `busy_timeout`, SQLite also provides the lower-level [`busy_handler` hook](https://www.sqlite.org/c3ref/busy_handler.html). The `busy_timeout` is nothing more than a specific `busy_handler` implementation provided by SQLite. Any application using SQLite can provide its own custom `busy_handler`. The `sqlite3-ruby` gem is a SQLite driver, meaning that it provides Ruby bindings for the C API that SQLite exposes. Since it provides [a binding for the `sqlite3_busy_handler` C function](https://github.com/sparklemotion/sqlite3-ruby/blob/055da734dafdbb01bb8cf59dbcdb475ea822683f/ext/sqlite3/database.c#L209-L220), we can write a Ruby callback that will be called whenever a query is queued.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/052.png' | relative_url }}" alt="" />

Here is a Ruby implementation of the logic you will find in SQLite’s C source for its `busy_timeout`. Every time this callback is called, it is passed the count of the number of times this query has called this callback. That count is used to determine how long this query should wait to try again to acquire the write lock and how long it has already waited. By using [Ruby’s `sleep`](https://docs.ruby-lang.org/en/master/Kernel.html#method-i-sleep), we can ensure that the GVL is released while a query is waiting to retry acquiring the lock.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/053.png' | relative_url }}" alt="" />

By ensuring that the GVL is released while queries wait to retry acquiring the lock, we have massively improved our p99 latency even when under concurrent load.

But, there are still some outliers. If we look instead at the p99.99 latency, we will find another steadily increasing graph.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/054.png' | relative_url }}" alt="" />

Our slowest queries get steadily slower the more concurrent load our application is under. This is another growth curve that we would like to flatten. But, in order to flatten it, we must understand why it is occurring.

The issue is that our Ruby re-implementation of SQLite’s `busy_timeout` logic penalizes “older queries”. This is going to kill our long-tail performance, as responses will get naturally segmented into the batch that had “young” queries and those that had “old” queries, because SQLite will naturally segment queries into such batches. To explain more clearly what I mean, let’s step through our Ruby `busy_timeout` logic a couple times.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/055.png' | relative_url }}" alt="" />

The first time a query is queued and calls this timeout callback, the count is zero.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/056.png' | relative_url }}" alt="" />

And since 0 is less than 12, we enter the `if` block.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/057.png' | relative_url }}" alt="" />

We get the zero-th element in the delays array as our delay, which is 1.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/058.png' | relative_url }}" alt="" />

We then take the first 0 elements of the delays array, which is an empty array, and sum those numbers together, which in this case sums to 0. This is how long the query has been delayed for already,

<img loading="lazy" src="{{ '/images/wrocloverb-2024/059.png' | relative_url }}" alt="" />

With our timeout as 5000, 0 + 1 is not greater than 5000, so we fall through to the `else` block.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/060.png' | relative_url }}" alt="" />

And we sleep for 1 millisecond before this callback is called again.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/061.png' | relative_url }}" alt="" />

The tenth time this query calls this timeout callback, the count is, well, 10.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/062.png' | relative_url }}" alt="" />

10 is still less than 12, so we enter the `if` block.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/063.png' | relative_url }}" alt="" />

We get the tenth element in the delays array as our delay, which is 50.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/064.png' | relative_url }}" alt="" />

We then take the first 10 elements of the delays array, that is the everything in the array up to but not including the tenth element, and sum those numbers together, which in this case sums to 178. This is how long the query has been delayed for already.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/065.png' | relative_url }}" alt="" />

50 + 178 is still not greater than 5000, so we fall through to the `else` block.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/066.png' | relative_url }}" alt="" />

And now we sleep for 50 milliseconds before this callback is called again.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/067.png' | relative_url }}" alt="" />

Let’s consider the 58th time this query calls this timeout callback.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/068.png' | relative_url }}" alt="" />

58 is greater than 12, so we fall through to the `else` block.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/069.png' | relative_url }}" alt="" />

Once we are past the 12th call to this callback, we will always delay 100 milliseconds.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/070.png' | relative_url }}" alt="" />

In order to calculate how long this query has already been delayed, we get the sum of the entire delays array and add the 100 milliseconds times however many times beyond 12 the query has retried. In this case, the sum of the entire delays array is 328, 58 minus 12 is 46 and 46 times 100 is 4600. So 4600 plus 328 is 4928. Up to this point, our query has been delayed for 4928 milliseconds.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/071.png' | relative_url }}" alt="" />

100 + 4928 is 5028, which is indeed greater than 5000, so we enter the `if` block.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/072.png' | relative_url }}" alt="" />

And finally we raise the exception.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/073.png' | relative_url }}" alt="" />

I know that stepping through this code might be a bit tedious, but we all need to be on the same page understanding how SQLite’s `busy_timeout` mechanism handles queued queries. When I say it penalizes old queries, I mean that it makes them much more likely to become timed out queries under consistent load. To understand why, let’s go back to our queued queries…

<img loading="lazy" src="{{ '/images/wrocloverb-2024/074.png' | relative_url }}" alt="" />

Let’s track how many retries each query makes from our simple example above.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/075.png' | relative_url }}" alt="" />

Our three remaining queries have retried once…

<img loading="lazy" src="{{ '/images/wrocloverb-2024/076.png' | relative_url }}" alt="" />

… and now the remaining two queries are, at best, on their second retry.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/077.png' | relative_url }}" alt="" />

And our third query is, again at best, on its third retry. On the third retry, the delay is already 10 milliseconds. Let’s imagine that at this moment a new write query is sent to the database.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/078.png' | relative_url }}" alt="" />

This new query immediately attempts to acquire the write lock, is denied and makes its zeroth call to the `busy_timeout` callback. It will be told to wait 1 millisecond. Our original query is waiting for 10 milliseconds, so this new query will get to retry again before our older query.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/079.png' | relative_url }}" alt="" />

While the write lock is still held, our new query is only asked to wait 2 milliseconds next.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/080.png' | relative_url }}" alt="" />

Even when the count is 2, it is only asked to wait 5 milliseconds. This new query will be allowed to retry to acquire the write lock **three times** before the original query is allowed to retry *once*.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/081.png' | relative_url }}" alt="" />

These increasing backoffs greatly penalize older queries, such that any query that has to wait even just 3 retries is now much more likely to never acquire the write lock if there is a steady stream of write queries coming in.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/082.png' | relative_url }}" alt="" />

So, what if instead of incrementally backing off our retries, we simply had every query retry at the same frequency, regardless of age? Doing so would also mean that we could do away with our `delays` array and re-think our `busy_handler` function altogether.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/083.png' | relative_url }}" alt="" />

And that is precisely [what we have done](https://github.com/sparklemotion/sqlite3-ruby/pull/456) in the `main` branch of the `sqlite3-ruby` gem. Unfortunately, as of today, this feature is not in a tagged release of the gem, but it should be released relatively soon. This Ruby callback releases the GVL while waiting for a connection using the `sleep` operation and always sleeps 1 millisecond. These 10 lines of code make a massive difference in the performance of your SQLite on Rails application.

Let’s re-run our benchmarking scripts and see how our p99.99 latency looks now…

<img loading="lazy" src="{{ '/images/wrocloverb-2024/084.png' | relative_url }}" alt="" />

Voila! We have flattened out the curve. There is still a jump with currency more than half the number of Puma workers we have, but after that jump our long-tail latency flatlines at around half a second.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/085.png' | relative_url }}" alt="" />

So, when it comes to performance, there are 4 keys that you need to ensure are true of your next SQLite on Rails application…

<img loading="lazy" src="{{ '/images/wrocloverb-2024/086.png' | relative_url }}" alt="" />

We have covered the first three, but not the last. The [write-ahead-log](https://www.sqlite.org/wal.html) allows SQLite to support multiple concurrent readers. The default [rollback journal mode](https://www.sqlite.org/lockingv3.html) only allows for one query at a time, regardless of whether it is a read or a write. WAL mode allows for concurrent readers but only one writer at a time.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/087.png' | relative_url }}" alt="" />

Luckily, [starting with Rails 7.1](https://github.com/rails/rails/pull/49349), Rails applies a better default configuration for your SQLite database. These changes are central to making SQLite work well in the context of a web application. If you’d like to learn more about what each of these configuration options are, why we use the values we do, and how this specific collection of configuration details improve things, I have [a blog post]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %}) that digs into these details.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/088.png' | relative_url }}" alt="" />

Now, while this isn’t a requirement, there is a fifth lever we can pull to improve the performance of our application. Since we know that SQLite in WAL mode supports multiple concurrent reading connections but only one writing connection at a time, we can recognize that it is possible for the Active Record connection pool to be saturated with writing connections and thus block concurrent reading operations.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/089.png' | relative_url }}" alt="" />

If your connection pool only has 3 connections, and you receive 5 concurrent queries, what happens if the 3 connections get picked up by three write queries?

<img loading="lazy" src="{{ '/images/wrocloverb-2024/090.png' | relative_url }}" alt="" />

The remaining read queries have to wait until one of the write queries releases a connection. Ideally, since we are using SQLite in WAL mode, read queries should never need to wait on write queries. In order to ensure this, we will need to create two distinct connection pools—one for reading operation and one for writing operations.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/091.png' | relative_url }}" alt="" />

We can leverage [Rails’ support for multiple databases](https://guides.rubyonrails.org/active_record_multiple_databases.html) to achieve this result. Instead of pointing the reader and writer database configurations to separate databases, we point them at the same single database, and thus simply create two distinct and isolated connection pools with distinct connection configurations.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/092.png' | relative_url }}" alt="" />

The reader connection pool will only consist of readonly connections…

<img loading="lazy" src="{{ '/images/wrocloverb-2024/093.png' | relative_url }}" alt="" />

And the writer connection pool will only have one connection.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/094.png' | relative_url }}" alt="" />

We can then configure our Active Records models to connect to the appropriate connection pool depending on the role.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/095.png' | relative_url }}" alt="" />

What we want, conceptually, is for our requests to behave essentially like SQLite deferred transactions. Every request should default to using the reader connection pool, but whenever we need to write to the database, we switch to using the writer pool for just that operation. To set that up, we will use Rails’ [automatic role switching feature](https://guides.rubyonrails.org/active_record_multiple_databases.html#activating-automatic-role-switching).

<img loading="lazy" src="{{ '/images/wrocloverb-2024/096.png' | relative_url }}" alt="" />

By putting this code in an initializer, we will force Rails to set the default database connection for all web requests to be the reading connection pool. We also tweak the delay configuration since we aren't actually using separate databases, only separate connections, we don't need to ensure that requests "read your own writes" with a `delay`.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/097.png' | relative_url }}" alt="" />

We can then patch the `transaction` method of the ActiveRecord adapter to force it to connection to the writing database.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/098.png' | relative_url }}" alt="" />

Taken together, these changes enable our “deferred requests” utilizing isolated connection pools. And when testing against the comment create endpoint, we do see a performance improvement when looking at simple requests per second.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/099.png' | relative_url }}" alt="" />

So, these are the 5 levels of performance improvement that you should make to your SQLite on Rails application.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/100.png' | relative_url }}" alt="" />

But, you don’t need to walk through all of these enhancements in your Rails app. As I said at the beginning, you can simply install [the enhanced adapter gem](https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter).

<img loading="lazy" src="{{ '/images/wrocloverb-2024/101.png' | relative_url }}" alt="" />

And if you want to use the isolated connection pools, you can simply add this configuration to your application. This is a newer experimental feature, which is why you have to opt into it.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/110.png' | relative_url }}" alt="" />

And, after all that, we are now done with how to make your SQLite on Rails application performant.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/115.png' | relative_url }}" alt="" />

In the end, I hope that this exploration of the tools, techniques, and defaults for SQLite on Rails applications has shown you how powerful, performant, and flexible this approach is. Rails is legitimately the best web application framework for working with SQLite today. The community’s growing ecosystem of tools and gems is unparalleled. And today is absolutely the right time to start a SQLite on Rails application and explore these things for yourself.

<img loading="lazy" src="{{ '/images/wrocloverb-2024/116.png' | relative_url }}" alt="" />

I hope that you now feel confident in the hows (and whys) of optimal performance when running SQLite in production with Rails.

Thank you.