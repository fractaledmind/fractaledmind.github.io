---
title: Enhancing your Rails app with SQLite
subtitle: Optimizing compilation
date: 2023-09-10
tags:
  - code
  - ruby
  - rails
  - sqlite
---

This is the next in a collection of posts on how to enhance [SQLite](https://www.sqlite.org/index.html) in order to power up our [Ruby on Rails](https://rubyonrails.org) applications. In this post, we dig into how to tune SQLite _at compile-time_ to better support production usage in a web application. This is a close companion to [a previous post]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %}) on optimizing the _run-time_ configuration of a SQLite database.

<!--/summary-->

- - -

But, before we get to the heart of the issue, a quick story. The fact that I am writing this post is a testament to the power of [publishing your work](https://www.youtube.com/watch?v=2YaEtaXYVtI) and the amazingness of the Ruby open-source community. When I shared the post on optimizing SQLite configuration, [Nate Hopkins](https://twitter.com/hopsoft?ref=fractaledmind.github.io) [replied](https://twitter.com/hopsoft/status/1699795147050061839?s=20) sharing how he optimizes the compilation of SQLite via [a Dockerfile](https://gist.github.com/hopsoft/9a0bf00be2816cbe036fae5aa3d85b73). To be honest, I hadn't even yet considered whether it was even possible to optimize your SQLite database by optimizing your installation of SQLite. I personally don't use Docker for my Rails projects, so I couldn't use Nate's Dockerfile.

I did recall, however, a blog post by Julia Evans on how [easy SQLite is to compile]((https://jvns.ca/blog/2019/10/28/sqlite-is-really-easy-to-compile/)), so I thought I might be able to write a Bash script to install and compile a project-specific installation of SQLite. Using Nate's Dockerfile as a guide and the [SQLite documentation](https://www.sqlite.org/howtocompile.html) it actually wasn't too difficult. You can find the script I used in [this Gist](https://gist.github.com/fractaledmind/6e70b23ecbd150751f6513e1b9839572).

After compiling a custom SQLite installation, I went researching how to tell the [`sqlite3-ruby` gem](https://github.com/sparklemotion/sqlite3-ruby) to use this SQLite installation over the system one. After trying a few different things, I couldn't get it to work. So, I do as we all do when we hit a wall, I opened [a new discussion](https://github.com/sparklemotion/sqlite3-ruby/discussions/400) on the GitHub repo. One of the project's primary maintainers, [Mike Dalessio](https://twitter.com/flavorjones?ref=fractaledmind.github.io), responded quickly. We went back and forth, and he then offered to hop on a pair-programming call with me to debug on my machine. After a quick call and some further chatting, Mike realized that I had overly-complicated things.

I was trying to bind the `sqlite3-ruby` gem to a custom installation of SQLite, but all that I really wanted was the ability to set compile-time flags when installing SQLite. After Mike [realized the core issue](https://github.com/sparklemotion/sqlite3-ruby/discussions/400#discussioncomment-6950366), he quickly opened a new [pull request](https://github.com/sparklemotion/sqlite3-ruby/pull/402) to allow users to set compile-time flags that the `sqlite3-ruby` gem will use when installing and compiling SQLite. The result is a [new release](https://github.com/sparklemotion/sqlite3-ruby/releases/tag/v1.6.5) of the `sqlite3-ruby` gem that enables users to pass compile-time options.

I wanted to tell the whole winding tale because I find the whole thing so remarkable. This is the real power of the Ruby/Rails community. From Nate sharing his Dockerfile to Mike working to understand what I was trying to do, and then doing all of the work to make it possible, we together were able to make something new together. I am genuinely giddy with excitement that we found such a clean and simple way to allow developer's to fine-tune their SQLite with compile-time options for their Rails apps.

- - -

So, what does this mean? Well, it means that we now have full control to optimize our SQLite databases for our Rails apps. We can optimize both _compile-time_ and _run-time_ options to truly **fine-tune** our SQLite databases. And having the ability to tune _compile-time_ options is a massive win for Rails apps, as the default configuration of SQLite is both driven by its commitment to backwards compatibility and its more common usage in embedded systems. In practice, neither is particularly useful for modern web application usage. The SQLite documentation even notes that its default compilation setup is [unsuited for most practical usage](https://www.sqlite.org/compile.html#recommended_compile_time_options). They then outline 12 compile-time flags that they recommend setting in order "to minimize the number of CPU cycles and the bytes of memory used by SQLite."

As with our previous post, I will simplify things and show you the flags that I recommend setting up for your Rails application. But first, how to we take advantage of this new feature of the `sqlite3-ruby` gem?

First and foremost, you need to be using [version 1.6.5 or higher](https://github.com/sparklemotion/sqlite3-ruby/releases/tag/v1.6.5). You should put `gem "sqlite3", "~> 1.6.5"` in your `Gemfile`. Next, you need to tell Bundler to use the "ruby" platform gem so that Bundler will compile SQLite from source by adding the `force_ruby_platform: true` option.[^1] So, in full, your Gemfile entry for `sqlite3` should look like this:

```ruby
gem "sqlite3", "~> 1.6.5", force_ruby_platform: true
```

This ensures that you have an appropriate version of the `sqlite3-ruby` gem and that when the gem compiles SQLite it won't use one of the prebuilt binaries.

Next, you need to set the Bundler config option for the compile-time flags. If you've ever tweaked the compile-time flags for Nokogiri, things should look familiar. You can set the config using the `bundler` CLI:

```shell
bundle config set build.sqlite3 \
"--with-sqlite-cflags='-DSQLITE_DEFAULT_CACHE_SIZE=9999 -DSQLITE_DEFAULT_PAGE_SIZE=4444'"
```

{:.notice}
**Note:** These values are for demonstration purposes only. _Do not_ copy this and run this in your project. I will provide an appropriate set of `CFLAGS` shortly.

Running this command will create or update your project's `.bundler/config` file to include an option like so:

```yaml
BUNDLE_BUILD__SQLITE3: "--with-sqlite-cflags='-DSQLITE_DEFAULT_CACHE_SIZE=9999 -DSQLITE_DEFAULT_PAGE_SIZE=4444'"
```

{:.notice}
**Note:** The use of single quotes within the double-quoted string to ensure the space between compiler flags is interpreted correctly.

That's it! You only need those two changes. An update to your `Gemfile` and your `.bundler/config` file is all it takes to get a project-specific, fine-tuned SQLite installation. You can find these steps, as well as additional instructions for more advanced usage of the `sqlite3-ruby` gem, in the [gem's installation documentation](https://github.com/sparklemotion/sqlite3-ruby/blob/master/INSTALLATION.md).

- - -

Ok, let's get to the heart of the matter. What compile-time flags should we use? The short answer is: use what SQLite recommends, minus the ones that don't make sense for web application usage. The [SQLite docs](https://www.sqlite.org/compile.html#recommended_compile_time_options) recommend 12 flags. I won't repeat their explanation of what each one does here; read the docs to learn more.

```shell
SQLITE_DQS=0
SQLITE_THREADSAFE=0
SQLITE_DEFAULT_MEMSTATUS=0
SQLITE_DEFAULT_WAL_SYNCHRONOUS=1
SQLITE_LIKE_DOESNT_MATCH_BLOBS
SQLITE_MAX_EXPR_DEPTH=0
SQLITE_OMIT_DECLTYPE
SQLITE_OMIT_DEPRECATED
SQLITE_OMIT_PROGRESS_CALLBACK
SQLITE_OMIT_SHARED_CACHE
SQLITE_USE_ALLOCA
SQLITE_OMIT_AUTOINIT
```

<div class="notice" markdown="1">
**Note:** The SQLite docs themselves note that even this recommended set of compile-time options will only make around a 5% improvement:
> When all of the recommended compile-time options above are used, the SQLite library will be approximately 3% smaller and use about 5% fewer CPU cycles. So these options do not make a huge difference. But in some design situations, every little bit helps.
</div>

Two of these options won't work with the `sqlite3-ruby` gem: `SQLITE_OMIT_DEPRECATED` and `SQLITE_OMIT_DECLTYPE`. The gem needs those features of SQLite in order to function, so we must remove them.[^2]

We should also remove the `SQLITE_OMIT_AUTOINIT` option as it requires applications to correctly call SQLite's `initialize` method at appropriate times. We can't guarantee that level of control, and if you fail to call `initialize` properly, you will get a segfault.

You may also want to **_add_** the `SQLITE_ENABLE_FTS5` option, which adds SQLite's [full text search](https://www.sqlite.org/fts5.html) functionality to your build. This one depends on how you plan to use your database, but if you are currently using [ElasticSearch](https://www.elastic.co/elasticsearch/) or [Meilisearch](https://www.meilisearch.com), you could investigate replacing those dependencies with SQLite.

With our removals (and one possible addition), our set of flags now looks like this—9 flags to crank up SQLite's performance:

```shell
SQLITE_DQS=0
SQLITE_THREADSAFE=0
SQLITE_DEFAULT_MEMSTATUS=0
SQLITE_DEFAULT_WAL_SYNCHRONOUS=1
SQLITE_LIKE_DOESNT_MATCH_BLOBS
SQLITE_MAX_EXPR_DEPTH=0
SQLITE_OMIT_PROGRESS_CALLBACK
SQLITE_OMIT_SHARED_CACHE
SQLITE_USE_ALLOCA
SQLITE_ENABLE_FTS5
```

We can turn these into the Bundler config we need via the CLI command:

```shell
bundle config set build.sqlite3 \
"--with-sqlite-cflags='-DSQLITE_DQS=0 -DSQLITE_THREADSAFE=0 -DSQLITE_DEFAULT_MEMSTATUS=0 -DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1 -DSQLITE_LIKE_DOESNT_MATCH_BLOBS -DSQLITE_MAX_EXPR_DEPTH=0 -DSQLITE_OMIT_PROGRESS_CALLBACK -DSQLITE_OMIT_SHARED_CACHE -DSQLITE_USE_ALLOCA -DSQLITE_ENABLE_FTS5'"
```

Or just manually updating your project's `.bundler/config` file:

```yaml
BUNDLE_BUILD__SQLITE3: "--with-sqlite-cflags='-DSQLITE_DQS=0 -DSQLITE_DEFAULT_MEMSTATUS=0 -DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1 -DSQLITE_LIKE_DOESNT_MATCH_BLOBS -DSQLITE_MAX_EXPR_DEPTH=0 -DSQLITE_OMIT_PROGRESS_CALLBACK -DSQLITE_OMIT_SHARED_CACHE -DSQLITE_USE_ALLOCA -DSQLITE_ENABLE_FTS5'"
```

Now, just run `bundle install`. That's it.

In a later post, I will talk about how all of our fine-tuning adjustments come together and what the performance profile comparison is. For now, suffice it to say that simply be tweaking these compile-time options along with the run-time settings discussed previously, you will get a noticeably improved SQLite experience for your Rails app.

So, we now have the ability to tweak each of the knobs that SQLite provides to fine-tune its behavior and performance characteristics. And all because the Ruby community is so amazing. I love it.

- - -

## All posts in this series

* [Part 1 — branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %})
* [Part 2 — fine-tuning SQLite configuration]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %})
* [Part 3 — loading extensions]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %})
* [Part 4 — setting up `Litestream`]({% link _posts/2023-09-09-enhancing-rails-sqlite-setting-up-litestream.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Part 5 — optimizing compilation]({% link _posts/2023-09-10-enhancing-rails-sqlite-optimizing-compilation.md %})
* [Part 6 — array columns]({% link _posts/2023-09-12-enhancing-rails-sqlite-array-columns.md %})
* [Part 7 — local snapshots]({% link _posts/2023-09-14-enhancing-rails-sqlite-local-snapshots.md %})
* [Part 8 — Rails improvements]({% link _posts/2023-09-15-enhancing-rails-sqlite-activerecord-adapter-improvements.md %})
* [Part 9 — performance metrics]({% link _posts/2023-09-21-enhancing-rails-sqlite-performance-metrics.md %})
* [Part 10 — custom primary keys]({% link _posts/2023-09-22-enhancing-rails-sqlite-ulid-primary-keys.md %})
* [Part 11 — more Rails improvements]({% link _posts/2023-09-26-enhancing-rails-sqlite-more-activerecord-adapter-improvements.md %})

- - -

[^1]: Note that you can only use the `force_ruby_platform: true` on Bunder version 2.3.18 or higher. For Bundler version 2.1 or later (up to 2.3.18), you will need to run `bundle config set force_ruby_platform true`, which has the unfortunate side-effect of setting this option globally for your Gemfile 😕. For version 2.0 or earlier, you'll need to run `bundle config force_ruby_platform true`, which has the same side-effect.
[^2]: While you may think that we need to remove the `SQLITE_THREADSAFE=0` option, as web apps use multiple threads, we don't. The [`sqlite3-ruby` gem](https://github.com/sparklemotion/sqlite3-ruby) doesn't release the GVL when waiting for responses, so parallelism isn't possible. That is, a call to the sqlite3 API cannot run in parallel to any other work occurring in the Ruby process. In a Rails app, ActiveRecord itself is already thread-safe. So, because of the thread-safety of ActiveRecord and the non-parallelizability of the `sqlite3-ruby` gem, we don't actually need SQLite itself to add its own layer of thread-safety.
