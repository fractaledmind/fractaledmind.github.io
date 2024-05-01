---
series: SQLite Myths
title: Don't use autoincrement primary keys
date: 2023-11-12
tags:
  - code
  - sqlite
---

The [SQLite documentation](https://www.sqlite.org/autoinc.html) recommends _not_ using `AUTOINCREMENT` for primary keys. Is this good advice for web applications? Turns out, the usually solid SQLite docs are wrong on this one. Let's dig into why.

<!--/summary-->

At the top of the SQLite documentation page for [AUTOINCREMENT](https://www.sqlite.org/autoinc.html) is the following warning:

> The `AUTOINCREMENT` keyword imposes extra CPU, memory, disk space, and disk I/O overhead and should be avoided if not strictly needed. It is usually not needed.

The default stance towards the SQLite documentation is that it's correct. It's a well-written, well-maintained, and well-tested piece of software. So, when it says something like this, it's worth taking a moment to understand why. In this case, thought, it's wrong for web applications. Let's take the time to consider the details and understand why.

First up, we need to understand SQLite's two methods for dealing with monotonically increasing primary keys. The default mechanism is the `ROWID` algorithm. When you define a column as a `INTEGER PRIMARY KEY` column type, this will become the table's `ROWID` and the standard `ROWID` algorithm for automatically assigning a row identifier will be used. If, instead, you define a column as a `INTEGER PRIMARY KEY AUTOINCREMENT` column type, this will become the table's `ROWID` and the `AUTOINCREMENT` algorithm will be used.

The default `ROWID` algorithm is simple. It's a 64-bit signed integer that is one larger than the largest `ROWID` in the table. If the table is empty, the `ROWID` is 1. If the table has a `ROWID` of 1, the next `ROWID` will be 2. If the table has a `ROWID` of 2, the next `ROWID` will be 3. And so on. This is a simple, fast, and efficient algorithm. The problems start when you delete rows or when you insert a row with a `ROWID` that is larger than the largest `ROWID` in the table.

The latter problem isn't much of a concern. The limit for a 64-bit unsigned integer is 2<sup>63</sup>—or 9,223,372,036,854,775,807. That's a lot of rows. If you're hitting that limit, you're probably doing something wrong. The former problem, though, is a real concern. If you delete rows, the `ROWID` algorithm will reuse the `ROWID` of the deleted row. I asked Twitter what kinds of issues re-using primary key values might cause. Here is a collection of some of the responses:

* If used in a URL, users might accidentally access deleted records[^1]
* Users cannot delete associated records asynchronously[^2]
* Can’t use primary keys for cache keys
* Can’t use primary keys for web socket channel names[^3]
* Tables without FK constraints now may point to a new, unrelated parent[^4]

These are all notable issues. Web applications need to be able to uniquely identify records. If you're using the `ROWID` algorithm, you can't guarantee that a `ROWID` will always point to the same record. This is a problem. So, what of the `AUTOINCREMENT` algorithm. What does it do and does it avoid these problems?

The `AUTOINCREMENT` algorithm is a bit more complex. It uses a built-in database trigger to keep track of the largest `ROWID` in the table. When you insert a new row, it will use the largest `ROWID` in the table plus one. If you delete a row, it will not reuse the `ROWID`. Instead, it will continue to use the largest `ROWID` in the table plus one. This means that the `ROWID` will always be unique and will always point to the same record. This is exactly what we want. But, it does incur the performance penalty mentioned in the SQLite documentation. So, how much of a performance penalty are we talking about?

I wanted to isolate the overhead of just the `AUTOINCREMENT` algorithm. So, I created a simple benchmark to compare only the `ROWID` and `AUTOINCREMENT` algorithms. I ran the benchmark in 3 scenarios:

1. against an in-memory database
2. against an on-disk database using the default settings
3. against an on-disk database with [fine-tuned settings]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %})

Each benchmark was run on my M1 Max Macbook Pro, details:

```
Model Name:	MacBook Pro
Model Identifier:	MacBookPro18,2
Chip:	Apple M1 Max
Total Number of Cores:	10 (8 performance and 2 efficiency)
Memory:	32 GB
```

For the in-memory database, the `AUTOINCREMENT` adds overhead of about

{:.notice}
**0.7 microseconds**

<details markdown="1">
  <summary>Code and results</summary>

```ruby
require 'benchmark'

connection = Extralite::Database.new(":memory:")
connection.execute(<<~SQL)
  CREATE TABLE with_rowid(id INTEGER PRIMARY KEY);
  CREATE TABLE with_autoincrement(id INTEGER PRIMARY KEY AUTOINCREMENT);
SQL

Benchmark.bmbm do |x|
  x.report("with_rowid") { 1_000_000.times { connection.execute("INSERT INTO with_rowid DEFAULT VALUES;") } }
  x.report("with_autoincrement")  { 1_000_000.times { connection.execute("INSERT INTO with_autoincrement DEFAULT VALUES;") } }
end
```

```
Rehearsal ------------------------------------------------------
with_rowid           1.519872   0.106731   1.626603 (  1.626619)
with_autoincrement   2.138196   0.103201   2.241397 (  2.241435)
--------------------------------------------- total: 3.868000sec

                         user     system      total        real
with_rowid           1.499923   0.100343   1.600266 (  1.600322)
with_autoincrement   2.184500   0.103087   2.287587 (  2.287726)
```
</details>

For the on-disk database with default settings, the `AUTOINCREMENT` adds overhead of about

{:.notice}
**11 microseconds**

<details markdown="1">
  <summary>Code and results</summary>

```ruby
require 'benchmark'

connection = Extralite::Database.new("on-disk-default.sqlite3")
connection.execute(<<~SQL)
  CREATE TABLE with_rowid(id INTEGER PRIMARY KEY);
  CREATE TABLE with_autoincrement(id INTEGER PRIMARY KEY AUTOINCREMENT);
SQL

Benchmark.bmbm do |x|
  x.report("with_rowid") do
  	1_000_000.times { connection.execute("INSERT INTO with_rowid DEFAULT VALUES;") }
  end
  x.report("with_autoincrement") do
  	1_000_000.times { connection.execute("INSERT INTO with_autoincrement DEFAULT VALUES;") }
  end
end
```

```
Rehearsal ------------------------------------------------------
with_rowid          11.739542 209.125691 220.865233 (289.690082)
with_autoincrement  12.595312 224.557327 237.152639 (302.689240)
------------------------------------------- total: 458.017872sec

                         user     system      total        real
with_rowid          11.866481 207.251119 219.117600 (290.708165)
with_autoincrement  13.108186 227.025329 240.133515 (301.807846)
```
</details>

Finally, for the on-disk database with fine-tuned settings, the `AUTOINCREMENT` adds overhead of about

{:.notice}
**6.3 microseconds**

<details markdown="1">
  <summary>Code and results</summary>

```ruby
require 'benchmark'

connection = Extralite::Database.new("on-disk-tuned.sqlite3")
connection.execute(<<~SQL)
  PRAGMA journal_mode = WAL;
  PRAGMA synchronous = NORMAL;
  PRAGMA journal_size_limit = 67108864; -- 64 megabytes
  PRAGMA mmap_size = 134217728; -- 128 megabytes
  PRAGMA cache_size = 2000;
  PRAGMA busy_timeout = 5000;

  CREATE TABLE with_rowid(id INTEGER PRIMARY KEY);
  CREATE TABLE with_autoincrement(id INTEGER PRIMARY KEY AUTOINCREMENT);
SQL

Benchmark.bmbm do |x|
  x.report("with_rowid") do
  	1_000_000.times { connection.execute("INSERT INTO with_rowid DEFAULT VALUES;") }
  end
  x.report("with_autoincrement") do
  	1_000_000.times { connection.execute("INSERT INTO with_autoincrement DEFAULT VALUES;") }
  end
end
```

```
Rehearsal ------------------------------------------------------
with_rowid           4.067183   4.977109   9.044292 ( 11.926259)
with_autoincrement   5.541272   7.273528  12.814800 ( 17.929862)
-------------------------------------------- total: 21.859092sec

                         user     system      total        real
with_rowid           4.350798   5.422309   9.773107 ( 12.516695)
with_autoincrement   5.845045   7.607169  13.452214 ( 18.841942)
```
</details>

As the documentation says, `AUTOINCREMENT` does add overhead, but even in the worst case, it's only about **11 microseconds**. For a properly tuned database, it's only a single digit of _**microseconds**_. That is effectively no overhead at all. For the safety guarantees that `AUTOINCREMENT` provides, I think it is clearly worth ~10 microseconds.

So, when building your next SQLite-backed web application, I recommend using `AUTOINCREMENT` for all primary keys.

- - -

## All posts in this series

* [Myth 1 — concurrent writes can corrupt the database]({% link _posts/2023-10-13-sqlite-myths-concurrent-writes-can-corrupt-the-database.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Myth 2 — don't use autoincrement primary keys]({% link _posts/2023-11-12-sqlite-myths-autoincrement-primary-keys.md %})
* [Myth 3 — linear writes do not scale]({% link _posts/2023-12-05-sqlite-myths-linear-writes-do-not-scale.md %})


- - -

[^1]: pointed out by [Konnor Rogers](https://x.com/RogersKonnor/status/1723784846311342475)
[^2]: pointed out by [Mike Coutermarsh](https://x.com/mscccc/status/1723785941628641784)
[^3]: pointed out by [Mike Coutermarsh](https://x.com/mscccc/status/1723787598999511443)
[^4]: pointed out by [Xavier Noria](https://x.com/fxn/status/1723796594791752157)
