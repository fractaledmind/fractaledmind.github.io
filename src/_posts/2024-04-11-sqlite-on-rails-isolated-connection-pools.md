---
title: SQLite on Rails
subtitle: Isolated connection pools
date: 2024-04-11
tags:
  - code
  - ruby
  - rails
  - sqlite
---

If you want to squeeze as much performance out of your SQLite on Rails application, at some point you will need to confront the problem of writes saturating your connection pool. Let's dig into this problem and how to solve it with some clever usage of Rails' multi-database support.

<!--/summary-->

- - -

So, what exactly does it mean for writes to saturate your connection pool? Most people know that SQLite only supports linear writes; this means only one write query from one connection can be running at any time. When ran in WAL mode, this is in contrast to read queries, where multiple connections can be running read queries concurrently. It is a common myth that [SQLite's linear writes do not scale]({% link _posts/2023-12-05-sqlite-myths-linear-writes-do-not-scale.md %}). You can read that post to see the numbers demonstrating that the speed that comes from having your data right next to your application and your engine running inside of your application makes linear writes a non-issue when compared to running a separate database process on a separate machine.

But, linear writes can apply back-pressure on your web application if you are using a connection pool. Imagine you have a connection pool of three connections, but you have five application threads that can process incoming web requests. Imagine you have five web requests come in at basically the same time, and that leads to five SQLite queries — two reads and three writes. What would happen if the three write queries are just ahead of the two reads and acquire the three connections in your pool? Even though SQLite supports concurrent reads, those two read queries have no connection to SQLite and so have to wait for a connection to open up. And since the write queries can only resolve in linear order, those connections will only open up one at a time as well. This is the problem of a saturated connection pool.

Given that SQLite running in WAL journal mode (and this is the default in Rails since [version 7.1.0](https://github.com/rails/rails/pull/49349)) can handle multiple concurrent reads even as a write is occurring, it would be ideal if our application ensured that writes could never fully saturate the thread pool and block reads. Our application needs separate connection pools for reading and writing.

In the last couple of weeks, I have been experimenting with Rails' [multiple database support](https://guides.rubyonrails.org/active_record_multiple_databases.html), and I have found a way to use standard Rails features to produce this exact result! Let's walk through the details together.

- - -

Everything starts in the `config/database.yml` configuration file. As the [Rails docs explain](https://guides.rubyonrails.org/active_record_multiple_databases.html#setting-up-your-application), we can use a 3-tier configuration to configure multiple database connections within an environment. The standard example is a primary database with one or more replicas. In such a primary/replica setup, those separate database configurations are pointing to physically separate, but logically identical databases. We only need separate database configurations for physically identical databases. This is easy enough as we can simply use the same `database` path value:

```yaml
production:
  reader:
    <<: *default
    database: storage/production.sqlite3
  writer:
    <<: *default
    database: storage/production.sqlite3
```

We have just setup two separate yet identical configurations. As it stands, this doesn't seem particularly useful, since the configurations are themselves identical, but the core insight is that these separate configurations will create two separate connection pools. Rails doesn't introspect these configurations; it doesn't know that they are identical and point at the same physical database. It simply sees that we have two configurations defined and will thus create a connection pool for each configuration.

But, since we have separate configurations, we can actually fine-tune each configuration for their respective use-case. We can ensure that every connection in the `reader` pool is a readonly connection. We can likewise ensure that the `writer` pool only contains one connection. This latter change is nice because it will move write contention from the SQLite level to the application level, which means that linearizing writes can use an in-memory lock via the connection pool instead of SQLite's more expensive file-based lock.
These enhancements are easy to add to our configurations:

```yaml
production:
  reader:
    <<: *default
    database: storage/production.sqlite3
    readonly: true
  writer:
    <<: *default
    database: storage/production.sqlite3
    pool: 1
```

As simply as that, our Rails app now has a `reader` connection pool with however many readonly connections we have defined in our `default` configuration and a `writer` connection pool with a single connection.

The next step is to ensure that our application can use these pools. As you will see if you follow the [Rails guide on using multiple databases](https://guides.rubyonrails.org/active_record_multiple_databases.html#setting-up-your-application), you need to configure your `ApplicationRecord` with a `#connects_to` definition, mapping your configurations to the `reading` and `writing` Active Record roles:

```ruby
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  connects_to database: {
    writing: :writer,
    reading: :reader
  }
end
```

Now Active Record knows which connection pool to use for which role. But, by default, your Rails application *will not* do anything magical or automatic with this knowledge. In order to use these connection pools, you need to manually wrap Active Record invocations in [`connected_to` blocks](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionHandling.html#method-i-connected_to) to tell Active Record which connection pool to use for that operation:

```ruby
ActiveRecord::Base.connected_to(role: ActiveRecord.writing_role) do
  Post.create(...)
end
```

In order to avoid needing to litter `connected_to` blocks all around your application, we need to find a way to have every web request automatically use the `reader` pool (i.e. the "reading" role) and every Active Record write operation automatically use the `writer` pool (i.e. the "writing" role). For the former we will use Rails' built-in support for [automatic role switching](https://guides.rubyonrails.org/active_record_multiple_databases.html#activating-automatic-role-switching), and for the latter we are going to need to patch Active Record itself 😬. Don't worry though, we will keep our patch small.

Let's start with automatic role-switching. The Rails guide reminds us that we can scaffold the needed initializer with this generator:

```bash
bin/rails g active_record:multi_db
```

This creates a `config/initializers/multi_db.rb` file with some commented code. The generated code includes configuration for automatic role switching as well as automatic shard switching. We only need the role switching code, so you can either delete or ignore the shard switching portion. If you uncomment the role switching code, you will find this block adding configuration to Rails:

```ruby
Rails.application.configure do
  config.active_record.database_selector = { delay: 2.seconds }
  config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
end
```

This default configuration will use the session to store information used to determine which connection pool to automatically switch to (like the last write timestamp). The default resolver switches to the "reading" role connection pool on `HEAD` or `GET` requests that do not occur within the `delay` window; that is, if you make a `POST` request and within 2 seconds make a `GET` request, that `GET` request will use the "writing" role connection pool and not the "reading" role pool. This delay window is to help ensure that you always "read your own write" when accessing physically separate databases. Since we are using separate connection pools to the same physical database, we don't need to worry about this. We also want *every* request to use the "reading" role connection pool by default and only switch to the "writing" role pool for specific write operations. This means we need a custom resolver. Let's update this initializer like so:

```ruby
class AlwaysReadingResolver < ActiveRecord::Middleware::DatabaseSelector::Resolver
  def reading_request?(request)
    true
  end
end

Rails.application.configure do
  config.active_record.database_selector = { delay: 0 }
  config.active_record.database_resolver = AlwaysReadingResolver
  config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
end
```

We have no delay window and use a custom resolver that marks every request as a reading request, and thus a request that should using the "reading" role connection pool. This will guarantee that every incoming web request will use our `reader` connection pool. So, how do we ensure that write operations switch to use the `writer` pool?

This is going to require patching Active Record, unfortunately. I don't love patching Rails internals, but sometimes there is no other way to achieve our desired result. I hope that through community experimentation and validation, we might be able to find a way to adapt Active Record to make this use-case not require a patch, but for now this is our only option.

Luckily, I believe we can patch a single Active Record method in a very low-touch way and get the results we are after. Because Active Record wraps every write operation in a database transaction, we can simply patch the `#transaction` method to use a `connected_to` block:

```ruby
def transaction(...)
  ActiveRecord::Base.connected_to(role: ActiveRecord.writing_role) do
    super(...)
  end
end
```

Ruby's new argument forwarding syntax ensures that our `#transaction` patch will work with any present or future method signatures for the method and we only wrap the `super` call in a `connected_to` block, so there is no abstraction leaking here. As patches go, I am pretty ok with this one.

As you can see from my [`activerecord-enhancedsqlite3-adapter` gem](https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter), the simplest and most resilient way to patch Active Record is to use the Active Support `on_load` callback and `prepend` a module:

```ruby
module EnhancedSQLite3Adapter
  def transaction(...)
    ActiveRecord::Base.connected_to(role: ActiveRecord.writing_role) do
      super(...)
    end
  end
end

ActiveSupport.on_load(:active_record_sqlite3adapter) do
  prepend EnhancedSQLite3Adapter
end
```

If you add this code to your `multi_db.rb` initializer file, you should have everything you need.

You have defined two separate database configurations that will spin up two separate connection pools. The `reader` connection pool will have multiple readonly connections; the `writer` pool with have a single connection. Those configurations are mapped to their appropriate "reading" and "writing" roles in the `ApplicationRecord` class. Then, we activate Rails' built-in automatic role switching middleware, using a custom resolver to connect Active Record to the "reading" role connection pool by default. Finally, we patch Active Record's `#transaction` method to ensure that any write operation (including the `BEGIN TRANSACTION` and `COMMIT` queries) switches to using the "writing" connection pool. This should be everything you need to isolate reading and writing connection pools for your SQLite database.

There is one additional nice-to-have that I personally add, though. Currently, Rails' logger does not log the configuration name being used for a particular query. So, if looking at your logs you can't actually tell if all of this setup is *working*. Obviously, when experimenting with all of this, I *needed* to know what queries where being sent to which configuration. To achieve this, I needed to patch Active Record one more time 😅. But, I kept it super small and direct again:

```ruby
def log(...)
  db_connection_name = ActiveRecord::Base.connection_db_config.name
  if Rails.logger.formatter.current_tags.include? db_connection_name
    super
  else
    Rails.logger.tagged(db_connection_name) { super }
  end
end
```

And yes, the `if` condition is necessary. I consistently saw `BEGIN TRANSACTION` queries double logging the connection name.

- - -

With these 5 parts, I believe we have a pretty robust solution for isolated connection pools. I wanted to walk you through all of the details so that you can put this together manually in your Rails app and understand what everything is doing. But, I of course want the enhanced adapter gem to simply package this up and inject into your app automatically, just as it does for immediate transactions and a non-GVL-blocking busy timeout. So, as of version 0.6.0 of the [`activerecord-enhancedsqlite3-adapter` gem](https://github.com/fractaledmind/activerecord-enhancedsqlite3-adapter), you can opt into using this functionality by setting the `isolate_connection_pools` configuration option to `true` in your `config/environments/*.rb` file or `config/application.rb` file:

```ruby
config.enhanced_sqlite3.isolate_connection_pools = true
```

I have put this feature behind an opt-in configuration because it is still technically experimental. I haven't personally deployed this to production in an app of mine, and all of my testing and experimentation has been done locally. I have tested it thoroughly locally, but local tests done by one person can only be so strong. If you want to try this out and boost your SQLite on Rails app performance, please do let me know if you bump into any rough edges or bugs. I'll get them fixed ASAP.

As I said, I would love to find a way to make this setup more natural and not require any patches in newer versions of Rails, so the more that we all try this out and validate both the utility and resiliency of this idea, the easier that conversation will be in the future.

- - -

I hope you have enjoyed this exploration of how to bring a more advanced performance optimization to your Rails app. As always, if you have questions or just want to connect and chat, hit me up on Twitter [@fractaledmind](http://twitter.com/fractaledmind?ref=fractaledmind.github.io).

- - -

## All posts in this series

* [SQLite on Rails — September State of the Union]({% link _posts/2023-09-27-sqlite-on-rails-september-state-of-the-union.md %})
* [SQLite on Rails — Introducing the enhanced adapter gem]({% link _posts/2023-10-09-sqlite-on-rails-enhanced-sqlite3-adapter.md %})
* [SQLite on Rails — Improving the enhanced adapter gem]({% link _posts/2023-12-06-sqlite-on-rails-improving-the-enhanced-sqlite3-adapter.md %})
* [SQLite on Rails — Improving concurrency]({% link _posts/2023-12-11-sqlite-on-rails-improving-concurrency.md %})
* [SQLite on Rails — Introducing `litestream-ruby`]({% link _posts/2023-12-12-sqlite-on-rails-litestream-ruby.md %})
* {:.bg-[var(--tw-prose-bullets)]}[SQLite on Rails — Isolated connection pools]({% link _posts/2024-04-11-sqlite-on-rails-isolated-connection-pools.md %})