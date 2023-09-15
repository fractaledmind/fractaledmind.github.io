---
title: Enhancing your Rails app with SQLite
subtitle: Fine-tuning your database
date: 2023-09-07
tags:
  - code
  - ruby
  - rails
  - sqlite
---

This is the next in a collection of posts where I want to highlight ways we can enhance our [Ruby on Rails](https://rubyonrails.org) applications to take advantage of and empower using [SQLite](https://www.sqlite.org/index.html) as the database engine for our Rails applications. In this post, we dig into how to tune the SQLite configuration to better support production usage in a web application.

<!--/summary-->

- - -

Before jumping into the tuned configuration, let's step back and get familiar with how SQLite is configured. SQLite uses a custom SQL statement for configuration—the `PRAGMA` statement:

> The PRAGMA statement is an SQL extension specific to SQLite and used to modify the operation of the SQLite library or to query the SQLite library for internal (non-table) data.

As we can see from this definition, there are two basic kinds of `PRAGMA` statements:

1. those that "modify the operation of the SQLite library", and
2. those that "query the SQLite library for internal data"

For configuring SQLite, we are interested in the former, and not the latter. The SQLite documentation provides [a page with an overview of every `PRAGMA` statement](https://www.sqlite.org/pragma.html). Filtering out deprecated pragmas, specialized pragmas, and internal data pragmas, we are left with this list of 40 "configuration" pragmas:

```
analysis_limit
application_id
auto_vacuum
automatic_index
busy_timeout
cache_size
cache_spill
case_sensitive_like
cell_size_check
checkpoint_fullfsync
data_version
defer_foreign_keys
encoding
foreign_keys
freelist_count
fullfsync
hard_heap_limit
ignore_check_constraints
integrity_check
journal_mode
journal_size_limit
legacy_alter_table
locking_mode
max_page_count
mmap_size
page_count
page_size
query_only
quick_check
read_uncommitted
recursive_triggers
reverse_unordered_selects
secure_delete
soft_heap_limit
synchronous
temp_store
threads
trusted_schema
user_version
wal_autocheckpoint
```

I created a new Rails `7.0.7.2` application and checked the values for each of these pragmas to see how Rails and SQLite are setup by default in a new application:

```ruby
{"analysis_limit"=>0,
 "application_id"=>0,
 "auto_vacuum"=>0,
 "automatic_index"=>1,
 "timeout"=>5000,
 "cache_size"=>-2000,
 "cache_spill"=>483,
 "cell_size_check"=>0,
 "checkpoint_fullfsync"=>0,
 "data_version"=>1,
 "defer_foreign_keys"=>0,
 "encoding"=>"UTF-8",
 "foreign_keys"=>1,
 "freelist_count"=>0,
 "fullfsync"=>0,
 "hard_heap_limit"=>0,
 "ignore_check_constraints"=>0,
 "integrity_check"=>"ok",
 "journal_mode"=>"delete",
 "journal_size_limit"=>-1,
 "legacy_alter_table"=>0,
 "locking_mode"=>"normal",
 "max_page_count"=>1073741823,
 "mmap_size"=>0,
 "page_count"=>5,
 "page_size"=>4096,
 "query_only"=>0,
 "quick_check"=>"ok",
 "read_uncommitted"=>0,
 "recursive_triggers"=>0,
 "reverse_unordered_selects"=>0,
 "secure_delete"=>0,
 "soft_heap_limit"=>0,
 "synchronous"=>2,
 "temp_store"=>0,
 "threads"=>0,
 "trusted_schema"=>1,
 "user_version"=>0,
 "wal_autocheckpoint"=>1000}
```

<div class="notice" markdown="1">
**Note:** This output was achieved with this command:
```ruby
pragmas.reduce({}) do |memo, pragma|
  memo.merge!(ActiveRecord::Base.connection.execute("PRAGMA #{pragma}").first)
end
```
</div>

This is interesting, but of course not every pragma is equally important for tuning Rails/ActiveRecord. So, let's focus in on the most impactful pragmas. There are around _six_ pragmas that play a big role in performance, especially in the context of a web application:

* `journal_mode`
* `synchronous`
* `journal_size_limit`
* `mmap_size`
* `cache_size`
* `busy_timeout`/`busy_handler`

It is important that we understand what each of these pragmas does, and how best to tune them for our usage in Rails and ActiveRecord.[^1]

- - -

### The `journal_mode` pragma

The first and most important pragma to understand and tune is the [`journal_mode` pragma](https://www.sqlite.org/pragma.html#pragma_journal_mode). Since version 3.7.0 (2010-07-21) SQLite has offered two implementations to support the atomic transactions:

* the [Rollback journal](https://www.sqlite.org/lockingv3.html#rollback), and
* the [Write-Ahead log](https://www.sqlite.org/wal.html)

The rollback journal is the default and original implementation, while the write-ahead log is the newer implementation. The `journal_mode` pragma has _five_ options to tune how the **rollback journal** implementation behaves (`DELETE`, `TRUNCATE`, `PERSIST`, `MEMORY`, and `OFF`), and _one_ option that tells SQLite to simply use the write-ahead log implementation (`WAL`). By default, our new Rails app uses the rollback journal with the `DELETE` journal mode. This means that the rollback journal file will be deleted from disk after each transaction commits.

For web applications, the write-ahead log is the superior option. As the [SQLite documentation outlines](https://www.sqlite.org/wal.html), the write-ahead logs comes with a few advantages over the rollback journal that are especially important in the context of a web application:

> * WAL is significantly faster in most scenarios.
> * WAL provides more concurrency as readers do not block writers and a writer does not block readers. Reading and writing can proceed concurrently.

This is what we want in our application. We want faster queries and increased concurrency. So, the very first configuration change that we will need to make is to set the `journal_mode` pragma to `WAL` (we will get into the technical details of _how_ to do this in Rails [later]() in this post).

### The `synchronous` pragma

SQLite supports four different modes for the [`synchronous` pragma](https://www.sqlite.org/pragma.html#pragma_synchronous), which controls when and how SQLite flushes content to disk. The two common options are `FULL` and `NORMAL`, which map to "sync on every write" and "sync every 1000 written pages" respectively. Each mode has an integer value as well, so the `"synchronous"=>2` default value we see for our new Rails app maps to the `FULL` mode. This means that SQLite syncs data with the file on disk after every write. As they say in the documentation:

> This ensures that an operating system crash or power failure will not corrupt the database. FULL synchronous is very safe, but it is also slower.

Slow isn't what we want. And, it isn't what we need. As the SQLite documentation says:

> The synchronous=NORMAL setting is a good choice for most applications running in WAL mode.

In short, when `journal_mode` is `WAL`, simply set `synchronous` to `NORMAL`. These two go together like peanut butter and jelly.

But, what precisely is the `NORMAL` sync mode? It simply means that SQLite will flush to disk less often than after _every single_ write. SQLite has its own algorithm for determining the "most critical moments" to write to disk, where it syncs every `wal_autocheckpoint` pages (which defaults to 1000). So, if/when the `wal_autocheckpoint` pragma is changed, `NORMAL` mode syncs would occur after that many pages are written. So, we trade an aggressive approach to durability for speed. However, SQLite does a lot to mitigate the reduction in durability, and it is honestly an extreme edge-case. In fact, SQLite ensures that any potential data loss could only happen with OS or filesystem failure; any process crash won't affect data durability. So, we are optimizing for the 99% case and not the 1% case, which I think is appropriate for a Rails application.

### The `journal_size_limit` pragma

Next up we have the [`journal_size_limit` pragma](https://www.sqlite.org/pragma.html#pragma_journal_size_limit). This tells SQLite how much of the write-ahead log data (in our case) to keep in the on-disk file. The default of `-1` means that there is no limit, so this disk file will grow in size indefinitely. This is not what we want. Anyone who has experienced app downtime because log files filled up your disk space no that unlimited file size is just a massive headache waiting to happen. We need to ensure that the file size is capped at an appropriate size. But, what exactly is an appropriate size?

Well, we don't want it to be too small. The more data is in the journal file, the faster SQLite will be (generally). However, we also don't want it to be too big, as this can start to negatively impact read performance. Based on production usage and experimentation, I have landed on **64 megabytes** as a solid default for this setting.

### The `mmap_size` pragma

Next up, we have the abbreviated pragma [`mmap_size`](https://www.sqlite.org/pragma.html#pragma_mmap_size). This setting controls the "the maximum number of bytes of the database file that will be accessed using memory-mapped I/O." This is a mouth-full, but the gist is that when we enable memory-mapped I/O, we are allowing SQLite to share data among multiple processes. The memory map plays a similar role to Postgres' buffer pool, so instead of disabling it, we should set it to the same safe as the default Postgres buffer pool—**128MB**.

### The `cache_size` pragma

The [`cache_size` pragma](https://www.sqlite.org/pragma.html#pragma_cache_size) sets the "maximum number of database disk pages that SQLite will hold in memory at once per open database file." The default value of `-2000` is a negative number, which SQLite interprets as a byte limit. If we use a positive number, SQLite will interpret this as a page limit. The default limit is ~2MB (2,048,000 bytes) and is independent of the number of pages. We want to ensure that we have a large cache and that it doesn't split across pages, so let's use a positive number to set the cache limit to a page number. I recommend **2,000** pages as the `cache_size`, which, with the default page size of 4,096 bytes, means that the cache limit is ~8MB (8,192,000 bytes).

It is worth noting, for full understanding, that the page cache is private to each connection (even those in the same process), and it gets invalidated once another connection writes to the database file. It is nonetheless quite useful within the boundaries of a statement or a transaction to maximize concurrency speed.

### The `busy_timeout`/`busy_handler` pragma

The final pragma that is important to understand and tune is the [`busy_timeout` pragma](https://www.sqlite.org/pragma.html#pragma_busy_timeout). This tells SQLite how long to wait to successfully connect to the database when trying to establish a new connection. When you create a new Rails app with SQLite, Rails will set the `timeout` option in the `/config/database.yml` to `5000` milliseconds. SQLite uses an exponential backoff algorithm to retry connection attempts for as long as you specify the timeout (the backoff waits `1, 2, 5, 10, 15, 20, 25, 25, 25, 50, 50, 100` milliseconds between each attempt, retrying every 100 milliseconds once 12 retries have been attempted[^2]). This is a reasonable default, but for more aggressive performance tuning we could manually set [a `busy_handler`](https://www.sqlite.org/c3ref/busy_handler.html) instead. The `busy_timeout` provides a higher level interface for setting the `busy_handler` that SQLite will use. It is possible, however, to set a custom `busy_handler` function ourselves tho. A common approach is to eschew exponential backoff and simply retry the connection as quickly as possible to establish a connection as soon as possible. In order to prevent infinite retries, we can simply cap the maximum number of retry attempts. Using the [`SQLite3` Ruby adapter](https://github.com/sparklemotion/sqlite3-ruby), we can set a `busy_handler` by passing a proc, e.g.:

```ruby
@raw_connection.busy_handler do |count|
  count <= @config[:retries]
end
```

In the implementation section, we will discuss how to enable our Rails application to set a max retries instead of a max timeout. For now, let's suffice to say that whether you use a `busy_timeout` or a `busy_handler` comes down to how optimistic you are about how and when you might experience `BUSY` exceptions.[^3] For most Rails applications, I would recommend setting the `busy_handler` so that you can establish connections as quickly as possible.


### Pragmas summary

These six pragmas can be configured in SQLite using the following SQL:

```sql
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA journal_size_limit = 67108864 -- 64 megabytes;
PRAGMA mmap_size = 134217728 -- 128 megabytes;
PRAGMA cache_size = 2000;
PRAGMA busy_timeout = 5000;
```

This would provide a fine-tuned SQLite database for web application usage. In fact, this default configuration is precisely the default configuration used by [`Litestack`](https://github.com/oldmoe/litestack) for its [`Litedb` module](https://github.com/oldmoe/litestack/blob/master/lib/litestack/litedb.rb). So, I need to offer a big shout out to `Litestack` and [@oldmoe](https://twitter.com/oldmoe?ref=fractaledmind.github.io) for doing the hard work of forging the path to find an ideal default setup for Rails SQLite usage.

So, we have the six pragmas that we want to configure, and we have the values that we want to set. The only thing remaining is actually configuring our Rails application to consistently use these settings. As is the theme for this series, we want to **enhance** Rails, not override Rails. So, we need a mechanism that builds on top of Rails and provides similar flexibility as Rails.

- - -

### Fine-tuning your Rails application

There does appear to be a natural hook point for configuring Rails' database adapters; unfortunately, it isn't publicly exposed for extension yet—this is the [`configure_connection` method](https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/abstract_adapter.rb#L1210-L1218). As the comment explains, this method will

> [p]erform any necessary initialization upon the newly-established `@raw_connection` -- this is the place to modify the adapter's connection settings, run queries to configure any application-global "session" variables, etc.

This sounds like exactly what we need. We can't hook into it naturally yet, so let's responsibly monkey-patch the SQLite adapter instead. Right now, the SQLite adapter will set the `busy_timeout` pragma if the `timeout` option is set and turn on the `foreign_keys` pragma in its [`configure_connection` method](https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/sqlite3_adapter.rb#L691-L695). In order to extend this method, let's create an initializer file to extend the SQLite adapter.

We can use the `ActiveSupport.on_load(:active_record_sqlite3adapter)` hook to only extend the adapter when it is loaded. This block will be passed the `SQLite3Adapter`, so we can simply call `prepend` in the block. This means we can simply define a module that will extend the `configure_connection` method and then `prepend` that module into the adapter class. I put Rails extensions under the `RailsExt` module namespace, so let's create a `RailsExt::SQLite3Adapter` module:

```ruby
# /config/initializers/active_record_sqlite3adapter.rb
module RailsExt
  module SQLite3Adapter
    # Perform any necessary initialization upon the newly-established
    # @raw_connection -- this is the place to modify the adapter's
    # connection settings, run queries to configure any application-global
    # "session" variables, etc.
    #
    # Implementations may assume this method will only be called while
    # holding @lock (or from #initialize).
    #
    # extends https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/sqlite3_adapter.rb#L691
    def configure_connection
      super
      
      # ...
    end
  end
end
```

We want to provide an enhancement to the Rails database configuration setup. In my opinion, setting up a `pragmas` section in the default portion of the database configuration provides a clear and flexible developer experience. We can then iterate over the pragmas hash and make the SQLite calls to set the pragmas in our extension module. This is simple to implement:

```ruby
def configure_connection
  super
  
  @config[:pragmas].each do |key, value|
    raw_execute("PRAGMA #{key} = #{value}", "SCHEMA")
  end
end
```

This allows us to enhance our database configuration like so:

```yaml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  # time to wait (in milliseconds) to obtain a write lock before raising an exception
  # https://www.sqlite.org/pragma.html#pragma_busy_timeout
  timeout: 5000
  pragmas:
    # level of database durability, 2 = "FULL" (sync on every write), other values include 1 = "NORMAL" (sync every 1000 written pages) and 0 = "NONE"
    # https://www.sqlite.org/pragma.html#pragma_synchronous
    synchronous: "NORMAL"
    # Journal mode WAL allows for greater concurrency (many readers + one writer)
    # https://www.sqlite.org/pragma.html#pragma_journal_mode
    journal_mode: "WAL"
    # impose a limit on the WAL file to prevent unlimited growth (with a negative impact on read performance as well)
    # https://www.sqlite.org/pragma.html#pragma_journal_size_limit
    journal_size_limit: <%= 64.megabytes %>
    # set the global memory map so all processes can share data
    # https://www.sqlite.org/pragma.html#pragma_mmap_size
    # https://www.sqlite.org/mmap.html
    mmap_size: <%= 128.megabytes %>
    # increase the local connection cache to 2000 pages
    # https://www.sqlite.org/pragma.html#pragma_cache_size
    cache_size: 2000
```

And just like that, we have tuned our application's SQLite database to be better configured for web application usage, while also providing a clear and simple mechanism for setting additional SQLite pragmas as needed/desired.

- - -

As a capstone, let's talk about how to support a `retries` option as an alternative to the `timeout` option. There are two key details here. Firstly, it is important that `retries` and `timeout` option cannot both be set at the same time, as the `busy_handler` and `busy_timeout` are mutually exclusive. Secondly, it is important that this be the very first pragma that is set so that other pragma queries respect our busy handling logic. We can update our `configure_connection` method like so to support these features:

```ruby
def configure_connection
  if @config[:timeout] && @config[:retries]
    raise ArgumentError, "Cannot specify both timeout and retries arguments"
  elsif @config[:retries]
    # see: https://www.sqlite.org/c3ref/busy_handler.html
    @raw_connection.busy_handler do |count|
      count <= @config[:retries]
    end
  end
  
  super
  
  @config[:pragmas].each do |key, value|
    raw_execute("PRAGMA #{key} = #{value}", "SCHEMA")
  end
end
```

Now, we can replace the `timeout: 5000` setting with a `retries: 1000` setting instead, and the appropriate `busy_handler` will get setup.

- - - 

> You can find the files we have written throughout this post in [this Gist](https://gist.github.com/fractaledmind/3565e12db7e59ab46f839025d26b5715/645f2d2dde3a275c270eabc00ce3067583b1b530)

Moreover, [Nate Hopkins](https://twitter.com/hopsoft?ref=fractaledmind.github.io) shared [a Gist](https://gist.github.com/hopsoft/9a0bf00be2816cbe036fae5aa3d85b73) with a Dockerfile that manually downloads and compiles SQLite with some specific performance optimizations. The SQLite docs outline some [preferable compilation optimizations](https://www.sqlite.org/compile.html) to make if you are compiling SQLite yourself, which Nate integrates nicely into his Dockerfile. Some are redundant with `PRAGMA` statements we employ, but others are compilation optimizations only. In short, Nate passes these flags when compiling SQLite:

```shell
SQLITE_DEFAULT_MEMSTATUS=0 \
SQLITE_DEFAULT_PAGE_SIZE=16384 \
SQLITE_DEFAULT_WAL_SYNCHRONOUS=1 \
SQLITE_DQS=0 \
SQLITE_ENABLE_FTS5 \
SQLITE_LIKE_DOESNT_MATCH_BLOBS \
SQLITE_MAX_EXPR_DEPTH=0 \
SQLITE_OMIT_PROGRESS_CALLBACK \
SQLITE_OMIT_SHARED_CACHE \
SQLITE_USE_ALLOCA"
```

`SQLITE_DEFAULT_WAL_SYNCHRONOUS` is redundant with our `PRAGMA journal_mode = WAL;` and `PRAGMA synchronous = NORMAL;` settings, but disabling memory tracking and `LIKE` working with `BLOB` fields are compilation-only optimizations.

As always, if you can, you absolutely should learn how to tune your database to better fit your needs. Read through the SQLite docs page on [recommended compile-time options](https://www.sqlite.org/compile.html#recommended_compile_time_options) and [Nate's Dockerfile](https://gist.github.com/hopsoft/9a0bf00be2816cbe036fae5aa3d85b73) and study how you can squeeze those extra cycles out of your SQLite installation to make your Rails app really hum.

- - -

## All posts in this series

* [Part 1 — branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Part 2 — fine-tuning SQLite configuration]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %})
* [Part 3 — loading extensions]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %})
* [Part 4 — setting up `Litestream`]({% link _posts/2023-09-09-enhancing-rails-sqlite-setting-up-litestream.md %})
* [Part 5 — optimizing compilation]({% link _posts/2023-09-10-enhancing-rails-sqlite-optimizing-compilation.md %})
* [Part 6 — array columns]({% link _posts/2023-09-12-enhancing-rails-sqlite-array-columns.md %})
* [Part 7 — local snapshots]({% link _posts/2023-09-14-enhancing-rails-sqlite-local-snapshots.md %})
* [Part 8 — Rails improvements]({% link _posts/2023-09-15-enhancing-rails-sqlite-activerecord-adapter-improvements.md %})

- - -

[^1]: Here are some other posts that dig into the pragmas to tune for SQLite in production: [https://phiresky.github.io/blog/2020/sqlite-performance-tuning/](https://phiresky.github.io/blog/2020/sqlite-performance-tuning/) and [https://blog.devart.com/increasing-sqlite-performance.html](https://blog.devart.com/increasing-sqlite-performance.html)
[^2]: This is mentioned by a maintainer in a [forum response](https://sqlite.org/forum/info/3fd33f0b9be72353) and can be seen in the `sqliteDefaultBusyCallback` method in the [`main.c` file](https://sqlite.org/src/file?name=src/main.c&ci=trunk).
[^3]: If you want to dive deeper into understanding how and when SQLite will throw a `BUSY` exception, this is an excellent blog post: [https://activesphere.com/blog/2018/12/24/understanding-sqlite-busy](https://activesphere.com/blog/2018/12/24/understanding-sqlite-busy).
