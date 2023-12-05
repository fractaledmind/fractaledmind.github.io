---
title: SQLite Myths
subtitle: Concurrent writes can corrupt the database file
date: 2023-10-13
tags:
  - code
  - sqlite
---

There are a number of myths that have made their way into the "common knowledge" of developers that need busting. Today, I want to explore the myth that attempting concurrent writes from concurrent threads/processes to a single SQLite database file can corrupt that file. This isn't true. Let's dig into why.

<!--/summary-->

- - -

I've been planning to write about common myths about SQLite, and this first post was prompted by [a post](https://ruby.social/@gd/111227192469880099) on the Ruby Social Mastodon server:

> [A]ny significant number of writes, while living under a multi-threaded web server, will produce thread-lock errors. These errors will sometimes corrupt the database.

I'm not trying to roast the author of this post, as these myths about SQLite are old and pervasive. But, this statement just isn't well-grounded. Let's check out the details.

SQLite [clearly documents](https://www.sqlite.org/howtocorrupt.html) situation under which db might be corrupted. They identify 8 high-level situations:

1. [File overwrite by a rogue thread or process](https://www.sqlite.org/howtocorrupt.html#_file_overwrite_by_a_rogue_thread_or_process)
2. [File locking problems](https://www.sqlite.org/howtocorrupt.html#_file_locking_problems)
3. [Failure to sync](https://www.sqlite.org/howtocorrupt.html#_failure_to_sync)
4. [Disk Drive and Flash Memory Failures](https://www.sqlite.org/howtocorrupt.html#_disk_drive_and_flash_memory_failures)
5. [Memory corruption](https://www.sqlite.org/howtocorrupt.html#_memory_corruption)
6. [Other operating system problems](https://www.sqlite.org/howtocorrupt.html#_other_operating_system_problems)
7. [SQLite Configuration Errors](https://www.sqlite.org/howtocorrupt.html#sqlite_configuration_errors)
8. [Bugs in SQLite](https://www.sqlite.org/howtocorrupt.html#_bugs_in_sqlite)

The first point to make here is that SQLite is very explicit about the situations where the file on disk could, theoretically or practically, be corrupted. This isn't a VC-backed developer tooling company that only offers marketing-laden documentation and tries to hide the rough edges. Moreover, because of [how well-tested](https://www.sqlite.org/testing.html) SQLite is and because SQLite is the [most deployed database engine in the world](https://www.sqlite.org/mostdeployed.html), they have very clear and detailed knowledge of the engine's rough edges. A document like this should instill deep trust and confidence in using SQLite as your database engine.

But, back to our specific myth. While the post is a bit generic, I believe the author is most likely referencing the scenario where an [I/O error while obtaining a lock leads to corruption](https://www.sqlite.org/howtocorrupt.html#_i_o_error_while_obtaining_a_lock_leads_to_corruption):

> If the operating system returns an I/O error while attempting to obtain a certain lock on shared memory in WAL mode then SQLite might fail to reset its cache, which could lead to database corruption if subsequent writes are attempted.
>
> Note that this problem only occurs if the attempt to acquire the lock resulted in an I/O error. If the lock is simply not granted (because some other thread or process is already holding a conflicting lock) then no corruption will ever occur. We are not aware of any operating systems that will fail with an I/O error while attempting to get a file lock on shared memory. So this is a theoretical problem rather than a real problem. Needless to say, this problem has never been observed in the wild. The problem was discovered while doing stress testing of SQLite in a test harness that simulates I/O errors.
>
> This problem was fixed on 2010-09-20 for SQLite version 3.7.3.

I may be wrong, but none of the other scenarios are problems with SQLite, and the author seems to suggest that this problem is a SQLite problem. Yes, you can corrupt your database file if you simply write to that file outside of using the SQLite library. And yes, you can corrupt your database file if you have multiple threads/processes working with a single database file, but you do foolish things like [touching or deleting the journal files](https://www.sqlite.org/howtocorrupt.html#_deleting_a_hot_journal), [renaming the database file](https://www.sqlite.org/howtocorrupt.html#_unlinking_or_renaming_a_database_file_while_in_use), or [improperly configure your database](https://www.sqlite.org/howtocorrupt.html#sqlite_configuration_errors). But, these require active mistakes on the developers part. The myth we are confronting holds that SQLite, by its nature of only allowing sequential writes, can (and will) corrupt the database file if multiple threads/processes are trying to write to that database file concurrently.

And, as the SQLite documentation states, this is _theoretically_ possible if the operating system returns an I/O error when one thread tries to obtain a lock. The key points to pull out from the documentation, though, are that "this problem has never been observed in the wild" and "was fixed on 2010-09-20 for SQLite version 3.7.3."

The simple fact of the matter is that while SQLite doesn't allow concurrent writes, it is very difficult to corrupt the database without doing something odd in how you use SQLite.

SQLite (in WAL mode, which is the mode [you should absolutely use]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %})) is essentially just operating like PostgreSQL in serialized isolation mode. We don't worry that Postgres in serialized isolation mode will corrupt the data in disk. And yet, SQLite is the best and most extensively tested piece of major software in the world.

- - -

So, in summary, while SQLite [currently doesn't allow concurrent writes](https://sqlite.org/hctree/doc/hctree/doc/hctree/index.html), you can still use it in a multi-threaded environment. Yes, you are likely to receive busy connection errors, but a simple retry is all you need. Using SQLite in a multi-threaded environment does not in any way make it likely that you will corrupt your database file.

As a next post, I will tackle the even more pervasive myth that because SQLite doesn't allow concurrent writes, this means that it can't handle the load required of a production-grade database engine. So, stay tuned for that.

Until then, I'd love to hear your thoughts and reactions. Reach out on [Twitter](https://twitter.com/fractaledmind) or [Mastodon](https://ruby.social/@fractaledmind) where I am `@fractaledmind`.

- - -

## All posts in this series

* {:.bg-[var(--tw-prose-bullets)]}[Myth 1 — concurrent writes can corrupt the database]({% link _posts/2023-10-13-sqlite-myths-concurrent-writes-can-corrupt-the-database.md %})
* [Myth 2 — linear writes do not scale]({% link _posts/2023-12-05-sqlite-myths-linear-writes-do-not-scale.md %})
