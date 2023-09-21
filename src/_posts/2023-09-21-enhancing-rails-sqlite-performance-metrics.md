---
title: Enhancing your Rails app with SQLite
subtitle: Performance metrics
date: 2023-09-21
tags:
  - code
  - ruby
  - rails
  - sqlite
published: false
---

When using [SQLite](https://www.sqlite.org/index.html) in your [Ruby on Rails](https://rubyonrails.org) application, [fine]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %})-[tuning]({% link _posts/2023-09-10-enhancing-rails-sqlite-optimizing-compilation.md %}) is essential. While SQLite is naturally fast, it's default configuration isn't tuned for web app usage. In this post, I want to explore some benchmarks and dig into why fine-tuning your SQLite database is so valuable.

<!--/summary-->

- - -

Benchmarking a database or an ORM can take a large variety of different shapes and sizes. There are enterprise-grade, council-produced standards, like the [Transaction Processing Performance Council](http://www.tpc.org)'s [TPC-E](https://www.tpc.org/TPC_Documents_Current_Versions/pdf/TPC-E_v1.14.0.pdf). There are large-scale benchmarks used often in academic research, like the [Telecom Application Transaction Processing Benchmark](https://tatpbenchmark.sourceforge.net). Then, there are the ad-hoc, custom benchmarks used typically by individuals.

I didn't want to write my own benchmarking suite, but I also needed something that would work seamlessly with SQLite and Rails. Luckily, one of Ruby's true gems—[Jeremy Evans](http://code.jeremyevans.net)—has a [benchmarking suite](https://github.com/jeremyevans/simple_orm_benchmark) which he has used for benchmarking different Ruby ORMs against different databases. It is written in Ruby, for Ruby ORMs. It has a nice mix of operations, and I know Jeremy is a top-notch programmer, so I basically just implicitly trust him. This suite of benchmarking operations forms the foundation of my benchmark.

I did rewrite the code, both to remove the indirection required in his code to support multiple ORMs and database engines and also to tailor the benchmark results to my interests. You can find the code for the benchmarking done in this blog post in [this Gist](https://gist.github.com/fractaledmind/fa7e975d59b093808334624ebe0b6f86).

The goal is to provide insight into how the fine-tuning options I've described in [past]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %}) [posts]({% link _posts/2023-09-10-enhancing-rails-sqlite-optimizing-compilation.md %}) impact the performance of ActiveRecord across a range of different operations, loads, and contexts. All benchmarks were run on my MacBook Pro (16-inch, 2021), which has an Apple M1 Max chip and 32GB of RAM running macOS Monterey (12.5.1). I also use version [1.6.6](https://github.com/sparklemotion/sqlite3-ruby/releases/tag/v1.6.6) of the [`sqlite3-ruby`](https://github.com/sparklemotion/sqlite3-ruby) gem for each benchmark run.

For each scenario, I will report all of the compile-time options set as well as the values of all of the relevant `PRAGMA`s.[^1] It is important to provide the full picture of how SQLite is configured for a benchmark, because as Purohith, Mohan, and Chidambaram detail in their paper ["The Dangers and Complexities of SQLite Benchmarking"](https://www.cs.utexas.edu/~vijay/papers/apsys17-sqlite.pdf), benchmarking results without this context are insufficient to both reproduce the result and place it in the larger context of benchmarks. This is particularly true of SQLite, as even a single configuration change can lead to more than a 10× performance improvement. And since our entire interest here is how different configurations impact performance, this context is essential.

We will benchmark four scenarios:

1. SQLite with default `sqlite3-ruby` compilation and without any `PRAGMA` fine-tuning
2. SQLite with default `sqlite3-ruby` compilation and with our recommended `PRAGMA` fine-tuning
3. SQLite with our recommended compilation fine-tuning and without any `PRAGMA` fine-tuning
4. SQLite with our recommended compilation fine-tuning and with our recommended `PRAGMA` fine-tuning

Let's dig into the results

## Default SQLite without fine-tuning

This will be our baseline. We will install `sqlite3-ruby` version 1.6.6 and then run our benchmarking script without any enhancements:

```shell
gem install sqlite3 -v 1.6.6
irb
```

```ruby
require_relative 'sqlite-activerecord-benchmark'
run_benchmark!(enhance: false, log: true)
```

The `run_benchmark!` function returns a tuple of the average total time for a benchmarking run (we run the full suite 10 times) as well as the average time for each individual benchmark operation. Running the benchmark on my machine, the average total time was:

{:.notice}
**13.5945s**

<details markdown="1">
  <summary>Breakdown by benchmark operation</summary>

{:.tables}
| Operation                                                          | Duration |
| :----                                                              | :---    |
| heavy_threading                                                    | 3.4941s |
| model_object_destruction                                           | 2.4036s |
| model_object_and_associated_object_creation                        | 1.5116s |
| eager_loading_single_query_with_1_to_n_to_n_records                | 1.2999s |
| model_object_select_and_save                                       | 1.2889s |
| eager_loading_single_query_with_1_to_n_to_n_records (txn)          | 1.2686s |
| light_threading                                                    | 0.4362s |
| model_object_update_json                                           | 0.3391s |
| model_object_select_and_save (txn)                                 | 0.2782s |
| model_object_update_json_nested                                    | 0.2304s |
| lazy_loading_with_1_to_1_records                                   | 0.1659s |
| lazy_loading_with_1_to_1_records (txn)                             | 0.1627s |
| model_object_update_json (txn)                                     | 0.0804s |
| eager_loading_query_per_association_with_1_to_n_to_n_records (txn) | 0.0549s |
| eager_loading_query_per_association_with_1_to_n_to_n_records       | 0.0545s |
| eager_loading_single_query_with_1_to_n_records                     | 0.0431s |
| model_object_select_json_nested                                    | 0.0414s |
| eager_loading_single_query_with_1_to_n_records (txn)               | 0.0412s |
| model_object_update_json_nested (txn)                              | 0.0409s |
| model_object_select_json_nested (txn)                              | 0.038s  |
| lazy_loading_with_1_to_n_records                                   | 0.0374s |
| lazy_loading_with_1_to_n_records (txn)                             | 0.0356s |
| eager_loading_query_per_association_with_1_to_n_records            | 0.0316s |
| eager_loading_query_per_association_with_1_to_n_records (txn)      | 0.0306s |
| eager_loading_single_query_with_1_to_1_records                     | 0.026s  |
| eager_loading_single_query_with_1_to_1_records (txn)               | 0.0258s |
| model_object_select_by_attr                                        | 0.0255s |
| eager_loading_query_per_association_with_1_to_1_records (txn)      | 0.0241s |
| eager_loading_query_per_association_with_1_to_1_records            | 0.0239s |
| model_object_select_by_attr (txn)                                  | 0.0231s |
| model_object_select_by_pk                                          | 0.0183s |
| model_object_select_by_pk (txn)                                    | 0.0161s |
| model_object_creation                                              | 0.0013s |
| model_object_creation (txn)                                        | 0.001s  |
| model_object_and_associated_object_creation (txn)                  | 0.0003s |
| model_object_destruction (txn)                                     | 0.0003s |
| model_object_select (txn)                                          | 0.0001s |
| model_object_select                                                | 0.0s    |

</details>
<div style="height: 1rem;"></div>
<details markdown="1">
  <summary>Environment information</summary>
```ruby
{
  "sqlite3-ruby version" => "1.6.6",
  "sqlite3 version" => "3.43.1",
  "sqlcipher?" => false,
  "threadsafe?" => true,
  "compile_options" => [
    "ATOMIC_INTRINSICS=1",
    "COMPILER=clang-10.0.0",
    "DEFAULT_AUTOVACUUM",
    "DEFAULT_CACHE_SIZE=-2000",
    "DEFAULT_FILE_FORMAT=4",
    "DEFAULT_JOURNAL_SIZE_LIMIT=-1",
    "DEFAULT_MMAP_SIZE=0",
    "DEFAULT_PAGE_SIZE=4096",
    "DEFAULT_PCACHE_INITSZ=20",
    "DEFAULT_RECURSIVE_TRIGGERS",
    "DEFAULT_SECTOR_SIZE=4096",
    "DEFAULT_SYNCHRONOUS=2",
    "DEFAULT_WAL_AUTOCHECKPOINT=1000",
    "DEFAULT_WAL_SYNCHRONOUS=2",
    "DEFAULT_WORKER_THREADS=0",
    "ENABLE_FTS3",
    "ENABLE_FTS4",
    "ENABLE_FTS5",
    "ENABLE_GEOPOLY",
    "ENABLE_MATH_FUNCTIONS",
    "ENABLE_RTREE",
    "MALLOC_SOFT_LIMIT=1024",
    "MAX_ATTACHED=10",
    "MAX_COLUMN=2000",
    "MAX_COMPOUND_SELECT=500",
    "MAX_DEFAULT_PAGE_SIZE=8192",
    "MAX_EXPR_DEPTH=1000",
    "MAX_FUNCTION_ARG=127",
    "MAX_LENGTH=1000000000",
    "MAX_LIKE_PATTERN_LENGTH=50000",
    "MAX_MMAP_SIZE=0x7fff0000",
    "MAX_PAGE_COUNT=1073741823",
    "MAX_PAGE_SIZE=65536",
    "MAX_SQL_LENGTH=1000000000",
    "MAX_TRIGGER_DEPTH=1000",
    "MAX_VARIABLE_NUMBER=32766",
    "MAX_VDBE_OP=250000000",
    "MAX_WORKER_THREADS=8",
    "MUTEX_PTHREADS",
    "SYSTEM_MALLOC",
    "TEMP_STORE=1",
    "THREADSAFE=1"
  ],
  "pragmas" => {
    "analysis_limit" => 0,
    "application_id" => 0,
    "auto_vacuum" => 0,
    "automatic_index" => 1,
    "timeout" => 0,
    "cache_size" => -2000,
    "cache_spill" => 483,
    "cell_size_check" => 0,
    "checkpoint_fullfsync" => 0,
    "data_version" => 1,
    "defer_foreign_keys" => 0,
    "encoding" => "UTF-8",
    "foreign_keys" => 1,
    "freelist_count" => 0,
    "fullfsync" => 0,
    "hard_heap_limit" => 0,
    "ignore_check_constraints" => 0,
    "integrity_check" => "ok",
    "journal_mode" => "delete",
    "journal_size_limit" => -1,
    "legacy_alter_table" => 0,
    "locking_mode" => "normal",
    "max_page_count" => 1073741823,
    "mmap_size" => 0,
    "page_count" => 7,
    "page_size" => 4096,
    "query_only" => 0,
    "quick_check" => "ok",
    "read_uncommitted" => 0,
    "recursive_triggers" => 0,
    "reverse_unordered_selects" => 0,
    "secure_delete" => 0,
    "soft_heap_limit" => 0,
    "synchronous" => 2,
    "temp_store" => 0,
    "threads" => 0,
    "trusted_schema" => 1,
    "user_version" => 0,
    "wal_autocheckpoint" => 1000
  }
}
```
</details>

## Default SQLite with `PRAGMA` fine-tuning

Still using the default installation of `sqlite3-ruby` (v1.6.6), on this run we will apply the `PRAGMA` enhancements from our [previous post]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %}):

```ruby
require_relative 'sqlite-activerecord-benchmark'
run_benchmark!(enhance: true, log: true)
```

Every time I run the benchmark on my machine, the average total time is **_2×_** better:

{:.notice}
**6.7886s**

This result conforms with the findings of Purohith, Mohan, and Chidambaram in their [SQLite benchmarking research paper](https://www.cs.utexas.edu/~vijay/papers/apsys17-sqlite.pdf):

> [Study] shows [a] 11.8X difference in performance due to changing only the journal mode, 1.5X difference due to varying the synchronization mode alone and a 5X change by modifying only the journal size.

If you want improved performance of your SQLite database, you **must** fine-tune your run-time configuration.

<details markdown="1">
  <summary>Breakdown by benchmark operation</summary>

{:.tables}
| Operation                                                          | Duration |
| :----                                                              | :---    |
| eager_loading_single_query_with_1_to_n_to_n_records                | 1.317s |
| eager_loading_single_query_with_1_to_n_to_n_records (txn)          | 1.2892s |
| heavy_threading                                                    | 1.1621s |
| model_object_destruction                                           | 0.5061s |
| model_object_and_associated_object_creation                        | 0.4827s |
| model_object_select_and_save                                       | 0.3851s |
| model_object_select_and_save (txn)                                 | 0.2797s |
| lazy_loading_with_1_to_1_records                                   | 0.165s |
| lazy_loading_with_1_to_1_records (txn)                             | 0.1644s |
| light_threading                                                    | 0.142s |
| model_object_update_json                                           | 0.1388s |
| model_object_update_json (txn)                                     | 0.0819s |
| eager_loading_query_per_association_with_1_to_n_to_n_records (txn) | 0.0553s |
| eager_loading_query_per_association_with_1_to_n_to_n_records       | 0.0539s |
| model_object_update_json_nested                                    | 0.0487s |
| model_object_update_json_nested (txn)                              | 0.0413s |
| eager_loading_single_query_with_1_to_n_records (txn)               | 0.04s |
| eager_loading_single_query_with_1_to_n_records                     | 0.0398s |
| model_object_select_json_nested                                    | 0.0386s |
| lazy_loading_with_1_to_n_records                                   | 0.0382s |
| model_object_select_json_nested (txn)                              | 0.0376s |
| lazy_loading_with_1_to_n_records (txn)                             | 0.0367s |
| eager_loading_query_per_association_with_1_to_n_records            | 0.0305s |
| eager_loading_query_per_association_with_1_to_n_records (txn)      | 0.0304s |
| eager_loading_single_query_with_1_to_1_records                     | 0.0265s |
| eager_loading_single_query_with_1_to_1_records (txn)               | 0.0264s |
| eager_loading_query_per_association_with_1_to_1_records            | 0.0246s |
| eager_loading_query_per_association_with_1_to_1_records (txn)      | 0.0245s |
| model_object_select_by_attr                                        | 0.0243s |
| model_object_select_by_attr (txn)                                  | 0.0239s |
| model_object_select_by_pk                                          | 0.0165s |
| model_object_select_by_pk (txn)                                    | 0.0159s |
| model_object_creation                                              | 0.0005s |
| model_object_creation (txn)                                        | 0.0004s |
| model_object_destruction (txn)                                     | 0.0002s |
| model_object_and_associated_object_creation (txn)                  | 0.0002s |
| model_object_select (txn)                                          | 0.0s |
| model_object_select                                                | 0.0s |

</details>
<div style="height: 1rem;"></div>
<details markdown="1">
  <summary>Environment information</summary>
```ruby
{
  "sqlite3-ruby version"=>"1.6.6",
  "sqlite3 version"=>"3.43.1",
  "sqlcipher?"=>false,
  "threadsafe?"=>true,
  "compile_options"=>[
    "ATOMIC_INTRINSICS=1",
    "COMPILER=clang-10.0.0",
    "DEFAULT_AUTOVACUUM",
    "DEFAULT_CACHE_SIZE=-2000",
    "DEFAULT_FILE_FORMAT=4",
    "DEFAULT_JOURNAL_SIZE_LIMIT=-1",
    "DEFAULT_MMAP_SIZE=0",
    "DEFAULT_PAGE_SIZE=4096",
    "DEFAULT_PCACHE_INITSZ=20",
    "DEFAULT_RECURSIVE_TRIGGERS",
    "DEFAULT_SECTOR_SIZE=4096",
    "DEFAULT_SYNCHRONOUS=2",
    "DEFAULT_WAL_AUTOCHECKPOINT=1000",
    "DEFAULT_WAL_SYNCHRONOUS=2",
    "DEFAULT_WORKER_THREADS=0",
    "ENABLE_FTS3",
    "ENABLE_FTS4",
    "ENABLE_FTS5",
    "ENABLE_GEOPOLY",
    "ENABLE_MATH_FUNCTIONS",
    "ENABLE_RTREE",
    "MALLOC_SOFT_LIMIT=1024",
    "MAX_ATTACHED=10",
    "MAX_COLUMN=2000",
    "MAX_COMPOUND_SELECT=500",
    "MAX_DEFAULT_PAGE_SIZE=8192",
    "MAX_EXPR_DEPTH=1000",
    "MAX_FUNCTION_ARG=127",
    "MAX_LENGTH=1000000000",
    "MAX_LIKE_PATTERN_LENGTH=50000",
    "MAX_MMAP_SIZE=0x7fff0000",
    "MAX_PAGE_COUNT=1073741823",
    "MAX_PAGE_SIZE=65536",
    "MAX_SQL_LENGTH=1000000000",
    "MAX_TRIGGER_DEPTH=1000",
    "MAX_VARIABLE_NUMBER=32766",
    "MAX_VDBE_OP=250000000",
    "MAX_WORKER_THREADS=8",
    "MUTEX_PTHREADS",
    "SYSTEM_MALLOC",
    "TEMP_STORE=1",
    "THREADSAFE=1"
  ],
  "pragmas" => {
    "analysis_limit"=>0,
    "application_id"=>0,
    "auto_vacuum"=>0,
    "automatic_index"=>1,
    "timeout"=>0,
    "cache_size"=>2000,
    "cache_spill"=>2000,
    "cell_size_check"=>0,
    "checkpoint_fullfsync"=>0,
    "data_version"=>2,
    "defer_foreign_keys"=>0,
    "encoding"=>"UTF-8",
    "foreign_keys"=>1,
    "freelist_count"=>0,
    "fullfsync"=>0,
    "hard_heap_limit"=>0,
    "ignore_check_constraints"=>0,
    "integrity_check"=>"ok",
    "journal_mode"=>"wal",
    "journal_size_limit"=>67108864,
    "legacy_alter_table"=>0,
    "locking_mode"=>"normal",
    "max_page_count"=>1073741823,
    "mmap_size"=>134217728,
    "page_count"=>7,
    "page_size"=>4096,
    "query_only"=>0,
    "quick_check"=>"ok",
    "read_uncommitted"=>0,
    "recursive_triggers"=>0,
    "reverse_unordered_selects"=>0,
    "secure_delete"=>0,
    "soft_heap_limit"=>0,
    "synchronous"=>1,
    "temp_store"=>0,
    "threads"=>0,
    "trusted_schema"=>1,
    "user_version"=>0,
    "wal_autocheckpoint"=>1000
  }
}
```
</details>

## Compilation-tuned SQLite without fine-tuning

While tuning the `PRAGMA`s of our database will provide the most noticeable performance improvement, fine-tuning the compile-time flags can eke out a few more cycles as well.

In order to get our testing environment ready, we need to uninstall `v1.6.6` of the `sqlite3-ruby` gem and re-install it with our compilation flags:

```shell
gem uninstall sqlite3 -v 1.6.6
gem install sqlite3 -v 1.6.6 --platform=ruby -- \
--with-sqlite-cflags="-DSQLITE_DQS=0 -DSQLITE_THREADSAFE=0 -DSQLITE_DEFAULT_MEMSTATUS=0 -DSQLITE_DEFAULT_WHRONOUS=1 -DSQLITE_LIKE_DOESNT_MATCH_BLOBS -DSQLITE_MAX_EXPR_DEPTH=0 -DSQLITE_OMIT_PROGRESS_CALLBACK -DSQLITE_OMIT_SHARED_CACHE -DSQLITE_USE_ALLOCA -DSQLITE_ENABLE_FTS5"
```

Once installed, enter an `irb` console and run the benchmarks:

```ruby
require_relative 'sqlite-activerecord-benchmark'
run_benchmark!(enhance: false, log: true)
```

As expected, since the [SQLite docs](https://www.sqlite.org/compile.html#recommended_compile_time_options) say that the full recommended compilation flag set can produce only a 5% increase, we see only a mild improvement compared to the baseline (~3%).

{:.notice}
**13.2174s**

<details markdown="1">
  <summary>Breakdown by benchmark operation</summary>

{:.tables}
| Operation                                                          | Duration |
| heavy_threading                                                    | 3.4161s |
| model_object_destruction                                           | 2.3001s |
| model_object_and_associated_object_creation                        | 1.4006s |
| model_object_select_and_save                                       | 1.3145s |
| eager_loading_single_query_with_1_to_n_to_n_records                | 1.2383s |
| eager_loading_single_query_with_1_to_n_to_n_records (txn)          | 1.233s  |
| light_threading                                                    | 0.423s  |
| model_object_update_json                                           | 0.328s  |
| model_object_select_and_save (txn)                                 | 0.2785s |
| model_object_update_json_nested                                    | 0.2281s |
| lazy_loading_with_1_to_1_records                                   | 0.1765s |
| lazy_loading_with_1_to_1_records (txn)                             | 0.1688s |
| model_object_update_json (txn)                                     | 0.0802s |
| eager_loading_query_per_association_with_1_to_n_to_n_records (txn) | 0.0555s |
| eager_loading_query_per_association_with_1_to_n_to_n_records       | 0.0541s |
| model_object_update_json_nested (txn)                              | 0.0405s |
| model_object_select_json_nested                                    | 0.0405s |
| eager_loading_single_query_with_1_to_n_records (txn)               | 0.04s   |
| eager_loading_single_query_with_1_to_n_records                     | 0.0387s |
| model_object_select_json_nested (txn)                              | 0.0374s |
| lazy_loading_with_1_to_n_records                                   | 0.037s  |
| lazy_loading_with_1_to_n_records (txn)                             | 0.0365s |
| eager_loading_query_per_association_with_1_to_n_records (txn)      | 0.0313s |
| eager_loading_query_per_association_with_1_to_n_records            | 0.031s  |
| model_object_select_by_attr                                        | 0.0272s |
| eager_loading_single_query_with_1_to_1_records                     | 0.0262s |
| eager_loading_single_query_with_1_to_1_records (txn)               | 0.026s  |
| model_object_select_by_attr (txn)                                  | 0.0251s |
| eager_loading_query_per_association_with_1_to_1_records            | 0.0247s |
| eager_loading_query_per_association_with_1_to_1_records (txn)      | 0.0243s |
| model_object_select_by_pk                                          | 0.0176s |
| model_object_select_by_pk (txn)                                    | 0.0155s |
| model_object_creation                                              | 0.0012s |
| model_object_creation (txn)                                        | 0.001s  |
| model_object_and_associated_object_creation (txn)                  | 0.0003s |
| model_object_destruction (txn)                                     | 0.0003s |
| model_object_select (txn)                                          | 0.0001s |
| model_object_select                                                | 0.0s    |

</details>
<div style="height: 1rem;"></div>
<details markdown="1">
  <summary>Environment information</summary>
```ruby
{
  "sqlite3-ruby version" => "1.6.6",
  "sqlite3 version" => "3.43.1",
  "sqlcipher?" => false,
  "threadsafe?" => false,
  "compile_options" => [
    "ATOMIC_INTRINSICS=1",
    "COMPILER=clang-14.0.0",
    "DEFAULT_AUTOVACUUM",
    "DEFAULT_CACHE_SIZE=-2000",
    "DEFAULT_FILE_FORMAT=4",
    "DEFAULT_JOURNAL_SIZE_LIMIT=-1",
    "DEFAULT_MEMSTATUS=0",
    "DEFAULT_MMAP_SIZE=0",
    "DEFAULT_PAGE_SIZE=4096",
    "DEFAULT_PCACHE_INITSZ=20",
    "DEFAULT_RECURSIVE_TRIGGERS",
    "DEFAULT_SECTOR_SIZE=4096",
    "DEFAULT_SYNCHRONOUS=2",
    "DEFAULT_WAL_AUTOCHECKPOINT=1000",
    "DEFAULT_WAL_SYNCHRONOUS=2",
    "DEFAULT_WORKER_THREADS=0",
    "DQS=0",
    "ENABLE_FTS3",
    "ENABLE_FTS4",
    "ENABLE_FTS5",
    "ENABLE_GEOPOLY",
    "ENABLE_MATH_FUNCTIONS",
    "ENABLE_RTREE",
    "LIKE_DOESNT_MATCH_BLOBS",
    "MALLOC_SOFT_LIMIT=1024",
    "MAX_ATTACHED=10",
    "MAX_COLUMN=2000",
    "MAX_COMPOUND_SELECT=500",
    "MAX_DEFAULT_PAGE_SIZE=8192",
    "MAX_EXPR_DEPTH=0",
    "MAX_FUNCTION_ARG=127",
    "MAX_LENGTH=1000000000",
    "MAX_LIKE_PATTERN_LENGTH=50000",
    "MAX_MMAP_SIZE=0x7fff0000",
    "MAX_PAGE_COUNT=1073741823",
    "MAX_PAGE_SIZE=65536",
    "MAX_SQL_LENGTH=1000000000",
    "MAX_TRIGGER_DEPTH=1000",
    "MAX_VARIABLE_NUMBER=32766",
    "MAX_VDBE_OP=250000000",
    "MAX_WORKER_THREADS=0",
    "MUTEX_OMIT",
    "OMIT_PROGRESS_CALLBACK",
    "OMIT_SHARED_CACHE",
    "SYSTEM_MALLOC",
    "TEMP_STORE=1",
    "THREADSAFE=0",
    "USE_ALLOCA"
  ],
  "pragmas" => {
    "analysis_limit" => 0,
    "application_id" => 0,
    "auto_vacuum" => 0,
    "automatic_index" => 1,
    "timeout" => 0,
    "cache_size" => -2000,
    "cache_spill" => 483,
    "cell_size_check" => 0,
    "checkpoint_fullfsync" => 0,
    "data_version" => 1,
    "defer_foreign_keys" => 0,
    "encoding" => "UTF-8",
    "foreign_keys" => 1,
    "freelist_count" => 0,
    "fullfsync" => 0,
    "hard_heap_limit" => 0,
    "ignore_check_constraints" => 0,
    "integrity_check" => "ok",
    "journal_mode" => "delete",
    "journal_size_limit" => -1,
    "legacy_alter_table" => 0,
    "locking_mode" => "normal",
    "max_page_count" => 1073741823,
    "mmap_size" => 0,
    "page_count" => 7,
    "page_size" => 4096,
    "query_only" => 0,
    "quick_check" => "ok",
    "read_uncommitted" => 0,
    "recursive_triggers" => 0,
    "reverse_unordered_selects" => 0,
    "secure_delete" => 0,
    "soft_heap_limit" => 0,
    "synchronous" => 2,
    "temp_store" => 0,
    "threads" => 0,
    "trusted_schema" => 1,
    "user_version" => 0,
    "wal_autocheckpoint" => 1000
  }
}
```
</details>

## Compilation-tuned SQLite with fine-tuning

Finally, we can consider the fully-tuned SQLite setup. Of course, we already know that the compilation-tuning only improves performance minimally, but let's run and see the exact results anyway.

Compared to the second scenario, we see another ~3% improvement:

{:.notice}
**6.5462s**

<details markdown="1">
  <summary>Breakdown by benchmark operation</summary>

{:.tables}
| Operation                                                          | Duration |
| eager_loading_single_query_with_1_to_n_to_n_records                | 1.2298s |
| eager_loading_single_query_with_1_to_n_to_n_records (txn)          | 1.1829s |
| heavy_threading                                                    | 1.1489s |
| model_object_destruction                                           | 0.4958s |
| model_object_and_associated_object_creation                        | 0.477s  |
| model_object_select_and_save                                       | 0.3783s |
| model_object_select_and_save (txn)                                 | 0.2746s |
| lazy_loading_with_1_to_1_records                                   | 0.171s  |
| lazy_loading_with_1_to_1_records (txn)                             | 0.1697s |
| light_threading                                                    | 0.1403s |
| model_object_update_json                                           | 0.1313s |
| model_object_update_json (txn)                                     | 0.0792s |
| eager_loading_query_per_association_with_1_to_n_to_n_records (txn) | 0.0541s |
| eager_loading_query_per_association_with_1_to_n_to_n_records       | 0.0532s |
| model_object_update_json_nested                                    | 0.0461s |
| eager_loading_single_query_with_1_to_n_records                     | 0.0404s |
| eager_loading_single_query_with_1_to_n_records (txn)               | 0.0402s |
| model_object_select_json_nested                                    | 0.0395s |
| model_object_update_json_nested (txn)                              | 0.0394s |
| model_object_select_json_nested (txn)                              | 0.0379s |
| lazy_loading_with_1_to_n_records                                   | 0.0375s |
| lazy_loading_with_1_to_n_records (txn)                             | 0.0354s |
| eager_loading_query_per_association_with_1_to_n_records            | 0.0309s |
| eager_loading_query_per_association_with_1_to_n_records (txn)      | 0.0304s |
| eager_loading_single_query_with_1_to_1_records                     | 0.026s  |
| eager_loading_single_query_with_1_to_1_records (txn)               | 0.0256s |
| model_object_select_by_attr                                        | 0.025s  |
| model_object_select_by_attr (txn)                                  | 0.0244s |
| eager_loading_query_per_association_with_1_to_1_records            | 0.0236s |
| eager_loading_query_per_association_with_1_to_1_records (txn)      | 0.0236s |
| model_object_select_by_pk                                          | 0.0167s |
| model_object_select_by_pk (txn)                                    | 0.0164s |
| model_object_creation                                              | 0.0005s |
| model_object_creation (txn)                                        | 0.0005s |
| model_object_and_associated_object_creation (txn)                  | 0.0002s |
| model_object_destruction (txn)                                     | 0.0002s |
| model_object_select                                                | 0.0s    |
| model_object_select (txn)                                          | 0.0s    |

</details>
<div style="height: 1rem;"></div>
<details markdown="1">
  <summary>Environment information</summary>
```ruby
{
  "sqlite3-ruby version" => "1.6.6",
  "sqlite3 version" => "3.43.1",
  "sqlcipher?" => false,
  "threadsafe?" => false,
  "compile_options" => [
    "ATOMIC_INTRINSICS=1",
    "COMPILER=clang-14.0.0",
    "DEFAULT_AUTOVACUUM",
    "DEFAULT_CACHE_SIZE=-2000",
    "DEFAULT_FILE_FORMAT=4",
    "DEFAULT_JOURNAL_SIZE_LIMIT=-1",
    "DEFAULT_MEMSTATUS=0",
    "DEFAULT_MMAP_SIZE=0",
    "DEFAULT_PAGE_SIZE=4096",
    "DEFAULT_PCACHE_INITSZ=20",
    "DEFAULT_RECURSIVE_TRIGGERS",
    "DEFAULT_SECTOR_SIZE=4096",
    "DEFAULT_SYNCHRONOUS=2",
    "DEFAULT_WAL_AUTOCHECKPOINT=1000",
    "DEFAULT_WAL_SYNCHRONOUS=2",
    "DEFAULT_WORKER_THREADS=0",
    "DQS=0",
    "ENABLE_FTS3",
    "ENABLE_FTS4",
    "ENABLE_FTS5",
    "ENABLE_GEOPOLY",
    "ENABLE_MATH_FUNCTIONS",
    "ENABLE_RTREE",
    "LIKE_DOESNT_MATCH_BLOBS",
    "MALLOC_SOFT_LIMIT=1024",
    "MAX_ATTACHED=10",
    "MAX_COLUMN=2000",
    "MAX_COMPOUND_SELECT=500",
    "MAX_DEFAULT_PAGE_SIZE=8192",
    "MAX_EXPR_DEPTH=0",
    "MAX_FUNCTION_ARG=127",
    "MAX_LENGTH=1000000000",
    "MAX_LIKE_PATTERN_LENGTH=50000",
    "MAX_MMAP_SIZE=0x7fff0000",
    "MAX_PAGE_COUNT=1073741823",
    "MAX_PAGE_SIZE=65536",
    "MAX_SQL_LENGTH=1000000000",
    "MAX_TRIGGER_DEPTH=1000",
    "MAX_VARIABLE_NUMBER=32766",
    "MAX_VDBE_OP=250000000",
    "MAX_WORKER_THREADS=0",
    "MUTEX_OMIT",
    "OMIT_PROGRESS_CALLBACK",
    "OMIT_SHARED_CACHE",
    "SYSTEM_MALLOC",
    "TEMP_STORE=1",
    "THREADSAFE=0",
    "USE_ALLOCA"
  ],
  "pragmas" => {
    "analysis_limit" => 0,
    "application_id" => 0,
    "auto_vacuum" => 0,
    "automatic_index" => 1,
    "timeout" => 0,
    "cache_size" => 2000,
    "cache_spill" => 2000,
    "cell_size_check" => 0,
    "checkpoint_fullfsync" => 0,
    "data_version" => 2,
    "defer_foreign_keys" => 0,
    "encoding" => "UTF-8",
    "foreign_keys" => 1,
    "freelist_count" => 0,
    "fullfsync" => 0,
    "hard_heap_limit" => 0,
    "ignore_check_constraints" => 0,
    "integrity_check" => "ok",
    "journal_mode" => "wal",
    "journal_size_limit" => 67108864,
    "legacy_alter_table" => 0,
    "locking_mode" => "normal",
    "max_page_count" => 1073741823,
    "mmap_size" => 134217728,
    "page_count" => 7,
    "page_size" => 4096,
    "query_only" => 0,
    "quick_check" => "ok",
    "read_uncommitted" => 0,
    "recursive_triggers" => 0,
    "reverse_unordered_selects" => 0,
    "secure_delete" => 0,
    "soft_heap_limit" => 0,
    "synchronous" => 1,
    "temp_store" => 0,
    "threads" => 0,
    "trusted_schema" => 1,
    "user_version" => 0,
    "wal_autocheckpoint" => 1000
  }
}
```
</details>

## Conclusions

After all of that, what conclusions can we draw? Well, it is clear that tuning `PRAGMA`s, and in particular setting the `journal_mode`, `synchronization`, and `journal_size_limit` pragmas, are **_essential_**. And, while compilation-tuning doesn't provide the same 2× improvements as pragma-tuning, given that it is now trivially easy, why leave the 3-5% on the table, right?

I wanted to see how these different SQLite setups compared to running PostgreSQL locally on my laptop thru the same benchmark. I confess that I don't know much about how to fine-tune PG, so I only ran the benchmark once with the default installation of PG (gem version 1.5.4, Postgres version 14.0.9) on my Macbook Pro. Here are the results:[^2]

{:.notice}
**11.4623s**

<details markdown="1">
  <summary>Breakdown by benchmark operation</summary>

{:.tables}
| Operation                                                          | Duration |
| heavy_threading                                                    | 2.8473s |
| model_object_destruction                                           | 1.232s  |
| eager_loading_single_query_with_1_to_n_to_n_records                | 1.2192s |
| eager_loading_single_query_with_1_to_n_to_n_records (txn)          | 1.2174s |
| model_object_and_associated_object_creation                        | 1.0791s |
| model_object_select_and_save                                       | 0.7963s |
| model_object_select_and_save (txn)                                 | 0.3855s |
| light_threading                                                    | 0.3575s |
| lazy_loading_with_1_to_1_records (txn)                             | 0.3465s |
| lazy_loading_with_1_to_1_records                                   | 0.3404s |
| model_object_update_json                                           | 0.2407s |
| model_object_select_by_attr (txn)                                  | 0.1708s |
| model_object_select_by_attr                                        | 0.1591s |
| model_object_select_json_nested                                    | 0.1392s |
| model_object_select_json_nested (txn)                              | 0.1383s |
| model_object_update_json_nested                                    | 0.1219s |
| model_object_update_json (txn)                                     | 0.1008s |
| model_object_update_json_nested (txn)                              | 0.0655s |
| eager_loading_query_per_association_with_1_to_n_to_n_records (txn) | 0.0545s |
| eager_loading_query_per_association_with_1_to_n_to_n_records       | 0.0521s |
| lazy_loading_with_1_to_n_records                                   | 0.0474s |
| lazy_loading_with_1_to_n_records (txn)                             | 0.0471s |
| eager_loading_single_query_with_1_to_n_records                     | 0.0392s |
| eager_loading_single_query_with_1_to_n_records (txn)               | 0.0375s |
| eager_loading_query_per_association_with_1_to_n_records (txn)      | 0.0303s |
| eager_loading_query_per_association_with_1_to_n_records            | 0.0302s |
| model_object_select_by_pk                                          | 0.0299s |
| model_object_select_by_pk (txn)                                    | 0.0295s |
| eager_loading_single_query_with_1_to_1_records (txn)               | 0.0265s |
| eager_loading_single_query_with_1_to_1_records                     | 0.0263s |
| eager_loading_query_per_association_with_1_to_1_records            | 0.0249s |
| eager_loading_query_per_association_with_1_to_1_records (txn)      | 0.0247s |
| model_object_creation                                              | 0.0017s |
| model_object_creation (txn)                                        | 0.0015s |
| model_object_destruction (txn)                                     | 0.0009s |
| model_object_and_associated_object_creation (txn)                  | 0.0007s |
| model_object_select (txn)                                          | 0.0001s |
| model_object_select                                                | 0.0s    |

</details>

This is a couple seconds faster than the non-tuned default SQLite, but it is nearly 2× **slower** than the fine-tuned SQLite installation. And this is without a full, realistic network delay, as both the benchmark and Postgres server are running on the same machine. Hopefully, even this simple benchmark demonstrates how performant SQLite can be, especially when tuned for web application usage.

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
* {:.bg-[var(--tw-prose-bullets)]}[Part 9 — Performance metrics]({% link _posts/2023-09-20-enhancing-rails-sqlite-performance-metrics.md %})

- - -

[^1]: By "relevant", I mean the sub-set of `PRAGMA`s generated by taking the full set provided by the [SQLite documentation](https://www.sqlite.org/pragma.html) and then filtering out deprecated pragmas, specialized pragmas, and internal data pragmas, which leaves a list of 40 "configuration" pragmas. I provide the full list in [my post]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %}) on fine-tuning SQLite with `PRAGMA`s.
[^2]: You can find the tweaked benchmark I used in [this file](https://gist.github.com/fractaledmind/fa7e975d59b093808334624ebe0b6f86#file-pg-activerecord-benchmark-rb) in the Gist.