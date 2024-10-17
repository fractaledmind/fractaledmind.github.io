---
title: Supercharge the One Person Framework with SQLite
subtitle: Rails World 2024
date: 2024-10-16
tags:
  - code
  - ruby
  - rails
  - sqlite
---

<a href="https://www.youtube.com/watch?v=l56IBad-5aQ"><img src="{{ '/images/railsworld-2024/001.png' | relative_url }}" alt="" style="width: 100%" /></a>

{:.notice}
**NOTE:** This is an edited transcript of a talk I gave at [Rails World 2024](https://rubyonrails.org/world/2024). You can watch the full talk on [YouTube](https://www.youtube.com/watch?v=l56IBad-5aQ).

From its beginning, [Rails](https://rubyonrails.org) has been famous for being a kind of a rocket engine that could propel your idea to astronomic heights at supersonic speed. But, at least for me, it has lately felt like I needed to be a rocket scientist to then deploy and run my full-featured application.

<img src="{{ '/images/railsworld-2024/rocket-launch.mov' | relative_url }}" alt="" style="width: 100%" />

And that is because just as, over time, rocket engines have grown larger and more complex,

<img loading="lazy" src="{{ '/images/railsworld-2024/003.png' | relative_url }}" alt="" style="width: 100%" />

So too has the "_standard_" web application architecture only grown more complicated with time.

<img loading="lazy" src="{{ '/images/railsworld-2024/004.png' | relative_url }}" alt="" style="width: 100%" />

Let’s consider a [typical Heroku application architecture](https://blog.heroku.com/modern-web-app-architecture) from, say, 2008. It would have had some web dynos to respond to HTTP requests, a database to persist data, and some worker dynos alongside a job queue. Sure, it’s a distributed system, but it is  manageable enough.

<img loading="lazy" src="{{ '/images/railsworld-2024/005.png' | relative_url }}" alt="" style="width: 100%" />

Well, **this** 👇️ is a standard Heroku application today—where the number of servers and services has basically tripled.

And I’m sure many, if not most, of you see this and think that this is simply the cost of running production-grade systems these days. It is easy enough to believe that complexity is the price to pay for progress.

<img loading="lazy" src="{{ '/images/railsworld-2024/006.png' | relative_url }}" alt="" style="width: 100%" />

But, not always. Sometimes progress is simplification. Sometimes, progress is reducing the number of moving parts, shrinking the surface area of the system, yet still expanding its power and functionality.

<img loading="lazy" src="{{ '/images/railsworld-2024/007.png' | relative_url }}" alt="" style="width: 100%" />

My name is Stephen Margheim, or you might know me as [@fractaledmind](https://x.com/fractaledmind) on Twitter, and today …

<img loading="lazy" src="{{ '/images/railsworld-2024/008.png' | relative_url }}" alt="" style="width: 100%" />

… I want to show you how [Rails 8](https://rubyonrails.org/2024/9/27/rails-8-beta1-no-paas-required) and [SQLite](https://www.sqlite.org) together supercharge Rails as the “[one-person framework](https://world.hey.com/dhh/the-one-person-framework-711e6318)”.

<img loading="lazy" src="{{ '/images/railsworld-2024/009.png' | relative_url }}" alt="" style="width: 100%" />

I want to offer a vision of building applications that have all of _this_ power,

<img loading="lazy" src="{{ '/images/railsworld-2024/010.png' | relative_url }}" alt="" style="width: 100%" />

but are _this_ lean and _this_ simple.

<img loading="lazy" src="{{ '/images/railsworld-2024/011.png' | relative_url }}" alt="" style="width: 100%" />

Because, believe it or not, **this** 👇️ is now a viable application architecture, and one that can serve tens of thousands of users, if not many, many more.

<img loading="lazy" src="{{ '/images/railsworld-2024/012.png' | relative_url }}" alt="" style="width: 100%" />

You see, just like liquid methane and liquid oxygen in a rocket, SQLite and Rails—when mixed—form a potent combination.

<img loading="lazy" src="{{ '/images/railsworld-2024/rocket-engine.gif' | relative_url }}" alt="" style="width: 100%" />

This is because Rails, with 2 decades of battle-tested solutions extracted from production applications, provides unparalleled  **conceptual** compression, while SQLite, with its single file database and embedded executable, provides truly unique **operational** compression.

<img loading="lazy" src="{{ '/images/railsworld-2024/014.png' | relative_url }}" alt="" style="width: 100%" />

And together they compress an explosive amount of power into a remarkably lean and simple application. Let me show you how.

<img loading="lazy" src="{{ '/images/railsworld-2024/rocket-boost.gif' | relative_url }}" alt="" style="width: 100%" />

- - -

To begin, we need to understand how Rails 8 makes the [`rails new`](https://guides.rubyonrails.org/command_line.html#rails-new) command production ready.

<img loading="lazy" src="{{ '/images/railsworld-2024/016.png' | relative_url }}" alt="" style="width: 100%" />

Rails has always been a “batteries included” framework that ships with a wide range of components.

<img loading="lazy" src="{{ '/images/railsworld-2024/017.png' | relative_url }}" alt="" style="width: 100%" />

And many require some form of persistent data.

<img loading="lazy" src="{{ '/images/railsworld-2024/data-components.gif' | relative_url }}" alt="" style="width: 100%" />

These are the data-bound components of Rails, and a full-featured application will need some data stores to back each of them.

<img loading="lazy" src="{{ '/images/railsworld-2024/023.png' | relative_url }}" alt="" style="width: 100%" />

Of course, each component has multiple adapters for various data stores.

<img loading="lazy" src="{{ '/images/railsworld-2024/024.png' | relative_url }}" alt="" style="width: 100%" />

With version 7 of Rails, when you run `rails new`, these are the production defaults you would get for each. Nothing offensive here, but this also isn’t a plug-and-play production setup.

<img loading="lazy" src="{{ '/images/railsworld-2024/025.png' | relative_url }}" alt="" style="width: 100%" />

The async adapter for jobs is fast and simple locally, but if you run it in production, you will lose pending jobs on deploys or restarts.

<img loading="lazy" src="{{ '/images/railsworld-2024/026.png' | relative_url }}" alt="" style="width: 100%" />

The file store for caching works well enough if you control the file system, but many platform services, like Heroku, only provide ephemeral file systems. And a cache isn’t nearly as helpful when its contents are completely wiped at random.

<img loading="lazy" src="{{ '/images/railsworld-2024/027.png' | relative_url }}" alt="" style="width: 100%" />

And the Redis adapter for Action Cable is certainly production-ready software, but it does require you to have a Redis instance configured, running, and connected to your application. So, production-ready, but not plug-and-play.

<img loading="lazy" src="{{ '/images/railsworld-2024/028.png' | relative_url }}" alt="" style="width: 100%" />

Rails 8 makes major changes to ensure that the out-of-the-box experience is both production-ready and plug-and-play.

<img loading="lazy" src="{{ '/images/railsworld-2024/029.png' | relative_url }}" alt="" style="width: 100%" />

With version 8, when you run `rails new`, you get a notably different set of defaults. The suite of Solid gems provide production-ready, flexible, and scalable defaults for the central data-bound components of Rails.

<img loading="lazy" src="{{ '/images/railsworld-2024/030.png' | relative_url }}" alt="" style="width: 100%" />

These new gems offer database-backed, but database-agnostic adapters for Active Job, Active Support Cache, and Action Cable.

<img loading="lazy" src="{{ '/images/railsworld-2024/031.png' | relative_url }}" alt="" style="width: 100%" />

[Rosa’s talk](https://www.youtube.com/watch?v=SsFA490IQ2c) outlined what makes Solid Queue production-grade software.

<img loading="lazy" src="{{ '/images/railsworld-2024/032.png' | relative_url }}" alt="" style="width: 100%" />

And at last year’s Rails World, [Donal introduced Solid Cache](https://www.youtube.com/watch?v=wYeVne3aRow), detailing its thoughtful and production-oriented design.

<img loading="lazy" src="{{ '/images/railsworld-2024/033.png' | relative_url }}" alt="" style="width: 100%" />

Finally, [Nick Pezza](https://pezza.co) has done great work getting [Solid Cable](https://github.com/rails/solid_cable) off the ground.

<img loading="lazy" src="{{ '/images/railsworld-2024/034.png' | relative_url }}" alt="" style="width: 100%" />

But, Rails 8 being production-ready isn’t only about these new defaults for Rails components.

<img loading="lazy" src="{{ '/images/railsworld-2024/035.png' | relative_url }}" alt="" style="width: 100%" />

Rails 8 also comes with a new and improved out-of-the-box solution for production deployments…

<img loading="lazy" src="{{ '/images/railsworld-2024/036.png' | relative_url }}" alt="" style="width: 100%" />

with [Kamal](https://kamal-deploy.org). Kamal offers everything you need to deploy and manage your web app in production with Docker.

<img loading="lazy" src="{{ '/images/railsworld-2024/037.png' | relative_url }}" alt="" style="width: 100%" />

You can learn more about the new version of Kamal, version 2.0, in [Donal's Rails World talk](https://www.youtube.com/watch?v=rne8OoabiC8).

<img loading="lazy" src="{{ '/images/railsworld-2024/038.png' | relative_url }}" alt="" style="width: 100%" />

and [Kevin introduced the brand new Kamal Proxy](https://www.youtube.com/watch?v=UpVoFqq8VFo).

I think you should learn what the future of deploying and running Rails applications looks like.

<img loading="lazy" src="{{ '/images/railsworld-2024/039.png' | relative_url }}" alt="" style="width: 100%" />

All in all, Rails 8 provides the tools you need to go from the “hello, world” of the `rails new` command to the “hello, web” of a production application.

<img loading="lazy" src="{{ '/images/railsworld-2024/hello.gif' | relative_url }}" alt="" style="width: 100%" />

These are the features and details that make Rails “the one-person framework”. As David outlined in [his keynote last year](https://www.youtube.com/watch?v=iqXjGiQ_D-A), Rails aims to be a bridge over complexity that allows even the smallest possible team—just you and your laptop—to build full, rich, valuable web applications. And SQLite aligns perfectly with that vision.

<img loading="lazy" src="{{ '/images/railsworld-2024/041.png' | relative_url }}" alt="" style="width: 100%" />

I like to say that SQLite **supercharges** Rails.

<img loading="lazy" src="{{ '/images/railsworld-2024/042.png' | relative_url }}" alt="" style="width: 100%" />

Because SQLite enables you to go from the moderate complexity of a minimally distributed system to the radical simplicity of an application and all of operational dependencies living on a single machine.

<img loading="lazy" src="{{ '/images/railsworld-2024/043.png' | relative_url }}" alt="" style="width: 100%" />

And this is because of SQLite’s unique architecture. Most SQL engines run in a separate process from your application, even typically on separate machines.

<img loading="lazy" src="{{ '/images/railsworld-2024/044.png' | relative_url }}" alt="" style="width: 100%" />

SQLite runs embedded within your Ruby thread and the process that spawns it.

<img loading="lazy" src="{{ '/images/railsworld-2024/045.png' | relative_url }}" alt="" style="width: 100%" />

So, it’s not a database in the way you might be used to.

<img loading="lazy" src="{{ '/images/railsworld-2024/046.png' | relative_url }}" alt="" style="width: 100%" />

It is just a file on disk and an executable embedded in your application process. Nonetheless, it is a full-featured SQL engine, with CTEs, window functions, aggregations, and the like.

<img loading="lazy" src="{{ '/images/railsworld-2024/047.png' | relative_url }}" alt="" style="width: 100%" />

And this is **_stable_** software. SQLite’s current major version, version 3, was first released 2 decades ago in 2004.

<img loading="lazy" src="{{ '/images/railsworld-2024/048.png' | relative_url }}" alt="" style="width: 100%" />

And today there are an estimated [1 trillion active SQLite databases](https://www.sqlite.org/mostdeployed.html) around the globe, making SQLite the single most used database in the world.

<img loading="lazy" src="{{ '/images/railsworld-2024/trillion.gif' | relative_url }}" alt="" style="width: 100%" />

Now, I’ll forgive you if you presume that an embedded database that stores data in a single file can only handle a tiny fraction of the amount of data something like Postgres or MySQL could handle.

<img loading="lazy" src="{{ '/images/railsworld-2024/050.png' | relative_url }}" alt="" style="width: 100%" />

But you would be completely wrong. SQLite can handle database files up to [281 terabytes](https://www.sqlite.org/limits.html). Or, to put it otherwise, you won’t hit its computational limits. I promise.

<img loading="lazy" src="{{ '/images/railsworld-2024/051.png' | relative_url }}" alt="" style="width: 100%" />

Pair that power and simplicity with modern hardware, and you are hopefully starting to appreciate how SQLite enhances the vision of Rails as the one-person framework, enabling us to radically simplify our application’s operational needs.

<img loading="lazy" src="{{ '/images/railsworld-2024/052.png' | relative_url }}" alt="" style="width: 100%" />

But, as I say this, I know that we have had years and years of people consistently saying…

<img loading="lazy" src="{{ '/images/railsworld-2024/053.png' | relative_url }}" alt="" style="width: 100%" />

that SQLite simply doesn’t work for *web* applications.

<img loading="lazy" src="{{ '/images/railsworld-2024/054.png' | relative_url }}" alt="" style="width: 100%" />

Indeed, for the last few years, Rails would log this warning if you ran SQLite in production.

<img loading="lazy" src="{{ '/images/railsworld-2024/055.png' | relative_url }}" alt="" style="width: 100%" />

Hell, the last time you read the Rails Guides, they warned you against using SQLite in production. But, this is an antiquated point of view.

<img loading="lazy" src="{{ '/images/railsworld-2024/056.png' | relative_url }}" alt="" style="width: 100%" />

The reality is that, today, this sentiment is a myth.

<img loading="lazy" src="{{ '/images/railsworld-2024/myth-1.gif' | relative_url }}" alt="" style="width: 100%" />

And more and more people are realizing it.

<img loading="lazy" src="{{ '/images/railsworld-2024/058.png' | relative_url }}" alt="" style="width: 100%" />

But, this myth does have foundations; because SQLite in the context of web applications is easily misunderstood and misused.

<img loading="lazy" src="{{ '/images/railsworld-2024/059.png' | relative_url }}" alt="" style="width: 100%" />

You see, unlike much of modern software, SQLite cares more about backwards-compatibility than it does about enabling newer, better features by default. The maintainers care deeply that a database file created 2 decades ago can be opened by SQLite 2 decades from now. This is a key reason why, among other things, SQLite is the storage format used for digital data by the United States’ Library of Congress.

<img loading="lazy" src="{{ '/images/railsworld-2024/060.png' | relative_url }}" alt="" style="width: 100%" />

So, for all intents and purposes, when you use SQLite today without any tweaking you are effectively using SQLite as it was configured when first released in 2004. And in 2004, SQLite was *not* well suited to being run in a web application.

<img loading="lazy" src="{{ '/images/railsworld-2024/061.png' | relative_url }}" alt="" style="width: 100%" />

But, over the last 2 decades, SQLite has added many features that make it suitable for web applications. All that is needed is to fine-tune SQLite’s configuration and usage.

<img loading="lazy" src="{{ '/images/railsworld-2024/062.png' | relative_url }}" alt="" style="width: 100%" />

And that is precisely what myself and the Rails Core team have been doing over the course of the last year.

<img loading="lazy" src="{{ '/images/railsworld-2024/rails-prs.gif' | relative_url }}" alt="" style="width: 100%" />

This work culminating in Rails 8.

<img loading="lazy" src="{{ '/images/railsworld-2024/073.png' | relative_url }}" alt="" style="width: 100%" />

Now, many of these improvements are inherited from 7.2, but there are two additions coming with Rails 8 that merit closer consideration. Because these changes make Rails 8 the first version of Rails (and, as far as I know, the first version of any web framework) that provides a fully production-ready SQLite experience…

<img loading="lazy" src="{{ '/images/railsworld-2024/074.png' | relative_url }}" alt="" style="width: 100%" />

out-of-the-box.

<img loading="lazy" src="{{ '/images/railsworld-2024/075.png' | relative_url }}" alt="" style="width: 100%" />

There were two issues that hindered the default experience of SQLite on Rails up ’til now. The first problem was that as your application was put under more and more concurrent load, a growing percentage of requests would error out. Even at just 4 concurrent requests, nearly half of your responses would be errors. Obviously, utterly unacceptable for production.

<img loading="lazy" src="{{ '/images/railsworld-2024/076.png' | relative_url }}" alt="" style="width: 100%" />

The second problem related to the application’s tail latency under increasing concurrent load. You would see your p99 or even your p95 latency skyrocket. Again, when some requests are taking 5 plus seconds to respond, this is completely untenable for real applications.

<img loading="lazy" src="{{ '/images/railsworld-2024/077.png' | relative_url }}" alt="" style="width: 100%" />

Both issues arise from the nuances of using an embedded database in a multi-threaded web application. Rails spins up multiple threads to process incoming requests, and each thread has its own embedded connection to the SQLite database.

<img loading="lazy" src="{{ '/images/railsworld-2024/078.png' | relative_url }}" alt="" style="width: 100%" />

Rails must ensure that those connections don’t conflict with each other.

<img loading="lazy" src="{{ '/images/railsworld-2024/079.png' | relative_url }}" alt="" style="width: 100%" />

And that they don’t block, waiting for each other.

<img loading="lazy" src="{{ '/images/railsworld-2024/080.png' | relative_url }}" alt="" style="width: 100%" />

Ensuring that the embedded connections don’t conflict was solved with [this change](https://github.com/rails/rails/pull/50371) to how Rails constructs transactions for SQLite.

<img loading="lazy" src="{{ '/images/railsworld-2024/081.png' | relative_url }}" alt="" style="width: 100%" />

And ensuring that they don’t block was fixed with a pair of PRs. One [in the `sqlite3-ruby` gem](https://github.com/sparklemotion/sqlite3-ruby/pull/456), which is the lower level interface between Ruby and the SQLite engine.

<img loading="lazy" src="{{ '/images/railsworld-2024/082.png' | relative_url }}" alt="" style="width: 100%" />

And then [one in Rails](https://github.com/rails/rails/pull/51958) to make use of this new feature in the driver.

<img loading="lazy" src="{{ '/images/railsworld-2024/083.png' | relative_url }}" alt="" style="width: 100%" />

I don’t have the time today to dig into the technical details, but if you are interested in learning more, I have an [in-depth post on my blog]({% link _posts/2023-12-23-rubyconftw.md %}) that walks through every detail of these changes—the nature of the problems, the reasoning behind the solutions, and the details of the implementation.

<img loading="lazy" src="{{ '/images/railsworld-2024/084.png' | relative_url }}" alt="" style="width: 100%" />

But details aside, the results speak for themselves. Not only do we no longer see errored responses…

<img loading="lazy" src="{{ '/images/railsworld-2024/085.png' | relative_url }}" alt="" style="width: 100%" />

but our `p99` latency is literally improved by an order of magnitude under heavier concurrent load.

<img loading="lazy" src="{{ '/images/railsworld-2024/086.png' | relative_url }}" alt="" style="width: 100%" />

In fact, we can see the improvements hold steady even in the very slowest requests in our benchmark.

<img loading="lazy" src="{{ '/images/railsworld-2024/087.png' | relative_url }}" alt="" style="width: 100%" />

These configuration and usage changes require nothing of you in your application code. And they unlock the full power and speed of SQLite, which now makes SQLite a fully viable production option.

<img loading="lazy" src="{{ '/images/railsworld-2024/088.png' | relative_url }}" alt="" style="width: 100%" />

You can now back 4 out of the 5 data-bound components of Rails with SQLite, without compromise.

<img loading="lazy" src="{{ '/images/railsworld-2024/089.png' | relative_url }}" alt="" style="width: 100%" />

And this is precisely what unlocks this architecture as a viable option. A full-featured Rails application, with no compromises on features or performance, all running on a single machine.

<img loading="lazy" src="{{ '/images/railsworld-2024/090.png' | relative_url }}" alt="" style="width: 100%" />

Now, I recognize that this is a fairly radical suggestion. I expect many of you are thinking right now that this architecture cannot possibly serve production workloads. So, let’s investigate.

<img loading="lazy" src="{{ '/images/railsworld-2024/091.png' | relative_url }}" alt="" style="width: 100%" />

I want to start with using the [Campfire app](https://once.com/campfire) released earlier this year by [37signals](https://37signals.com). And I want to start here because the team at 37signals not only built a full-featured, production-grade application, but they also shipped it with a realistic load-testing tool built in.

<img loading="lazy" src="{{ '/images/railsworld-2024/092.png' | relative_url }}" alt="" style="width: 100%" />

Now, admittedly, Campfire did not go all in on SQLite. Yes, SQLite is the database engine that backs Active Record, but jobs, cache, and web sockets are all driven by Redis.

<img loading="lazy" src="{{ '/images/railsworld-2024/093.png' | relative_url }}" alt="" style="width: 100%" />

But, Rails is modular, and so I simply swapped those adapters out. I reconfigured Campfire to use Rails 8, the Solid gems, and back everything with SQLite. And, as a side note, it only took me an hour or so.

<img loading="lazy" src="{{ '/images/railsworld-2024/094.png' | relative_url }}" alt="" style="width: 100%" />

Then, I ran the load tests for both the standard build of Campfire and my “Campfire on SQLite” fork.

<img loading="lazy" src="{{ '/images/railsworld-2024/loading.gif' | relative_url }}" alt="" style="width: 100%" />

And the results, once again, speak for themselves. Whether looking at the number of connections spawned…

<img loading="lazy" src="{{ '/images/railsworld-2024/096.png' | relative_url }}" alt="" style="width: 100%" />

or the number of messages received, the Campfire on SQLite fork performs just as well as the standard Campfire build.

<img loading="lazy" src="{{ '/images/railsworld-2024/097.png' | relative_url }}" alt="" style="width: 100%" />

In addition to this load testing, there are also existing Rails applications built on this stack running today, like [Ruby Video](https://www.rubyvideo.dev) by [Adrien Poly](https://x.com/adrienpoly). This app runs on a single $4 per month Hetzner box, with SQLite backing its IO needs, and it has served millions of requests with an average response time of less than 100 milliseconds and 4 nines of uptime.

<img loading="lazy" src="{{ '/images/railsworld-2024/099.png' | relative_url }}" alt="" style="width: 100%" />

There are also the applications I ran in production with nothing but SQLite on a single machine for years at my previous company. Unfortunately, they are proprietary applications connected to NDAs with massive companies, so I can’t share details or screenshots. But I can say that these applications are still running smoothly, have driven millions of dollars in revenue, and have never had a performance complaint.

<img loading="lazy" src="{{ '/images/railsworld-2024/100.png' | relative_url }}" alt="" style="width: 100%" />

Of course, tech Twitter has been chatting incessantly recently about [Peter Levels’ setup](https://www.youtube.com/watch?v=oFtjKbXKqbg&pp=ygUOZnJpZG1hbiBsZXZlbHM%3D), because he runs multiple successful applications, all backed by SQLite, with a single beefy VPS.

<img loading="lazy" src="{{ '/images/railsworld-2024/101.png' | relative_url }}" alt="" style="width: 100%" />

And, as a reminder, single server production deployments have served Rails applications well since day one.

<img loading="lazy" src="{{ '/images/railsworld-2024/102.png' | relative_url }}" alt="" style="width: 100%" />

So, yes, it is actually possible to run full-featured Rails applications in production, with no compromises on features or performance, all on a single machine.

<img loading="lazy" src="{{ '/images/railsworld-2024/103.png' | relative_url }}" alt="" style="width: 100%" />

So, I hope you trust me when I say, this idea is a myth. And next year, hopefully some of you here today will have started projects and been running them successfully for a while to add even more evidence.

<img loading="lazy" src="{{ '/images/railsworld-2024/104.gif' | relative_url }}" alt="" style="width: 100%" />

But, this isn’t some silver bullet. There are use-cases where this architecture shines and those where it doesn’t. And there are areas where you do need to be more considerate.

<img loading="lazy" src="{{ '/images/railsworld-2024/105.png' | relative_url }}" alt="" style="width: 100%" />

When running SQLite in production, you need to have a solid backup mechanism setup. And I say this as someone who has accidentally deleted the production SQLite database. Trust me, resilience is something you should have setup from day one.

<img loading="lazy" src="{{ '/images/railsworld-2024/106.png' | relative_url }}" alt="" style="width: 100%" />

I think the best tool for the job is [Litestream](https://litestream.io). The Litestream utility allows you to stream every update to your SQLite database (or databases) to any of a number of bucket storage systems, or even an FTS server. So, you get point in time backups and incredibly cheap storage costs.

<img loading="lazy" src="{{ '/images/railsworld-2024/107.png' | relative_url }}" alt="" style="width: 100%" />

Since it is only a single Go executable, I have wrapped it up in [a Ruby gem](https://github.com/fractaledmind/litestream-ruby) to make installation a breeze. The gem also uses a Puma plugin to manage the replication process, so it is truly a plug-and-play solution. It even ships with a verification job that you can schedule to run regularly to ensure that your backup process is continuously running smoothly.

<img loading="lazy" src="{{ '/images/railsworld-2024/108.png' | relative_url }}" alt="" style="width: 100%" />

Aside from data resilience, probably the most common worry I hear centers on the fact that SQLite only currently supports linear writes.

<img loading="lazy" src="{{ '/images/railsworld-2024/109.png' | relative_url }}" alt="" style="width: 100%" />

The worry is that only having one write operation at a time will prevent your application from “scaling”, whatever that means. But, this worry is overblown. Firstly, most applications are read-heavy, not write-heavy. So likely only around 20% of your traffic is writes. Plus, we forget what a difference using an embedded database makes on performance.

<img loading="lazy" src="{{ '/images/railsworld-2024/110.png' | relative_url }}" alt="" style="width: 100%" />

Even if you run Postgres on the same machine as your application, you can execute 10 SQLite queries in the time it takes to run one Postgres query. But, web applications are generally moving away from self-hosting and managing their own database server, and cloud databases are more popular than ever. When using a cloud database, there is a good chance that your database server will be in a different region than you application server. In this case, even if the regions are neighbors, the increased latency means that you can run nearly 600 SQLite queries in the same amount of time as running one Postgres query.[^1] When you go from a client/server database architecture to an embedded database, your queries go from being measured in milliseconds to microseconds!

[^1]: This estimate comes from benchmarking done by [Ben Johnson](), creator of Litestream and general SQLite expert, for a talk he gave at the [GopherCon](https://www.youtube.com/watch?v=XcAYkriuQ1o).

<img loading="lazy" src="{{ '/images/railsworld-2024/111.png' | relative_url }}" alt="" style="width: 100%" />

Unless you are ingesting **a lot** of data, and by “a lot” I mean on the order of 50,000 writes per second, I promise you that this aspect of SQLite’s architecture will not have a meaningful impact on your application.

<img loading="lazy" src="{{ '/images/railsworld-2024/113.png' | relative_url }}" alt="" style="width: 100%" />

But, it does mean that you should be thoughtful about migrations.

<img loading="lazy" src="{{ '/images/railsworld-2024/114.png' | relative_url }}" alt="" style="width: 100%" />

If you have a long and write-intensive migration—like adding a new index to a table with millions of rows—that migration will impact your application’s performance. There currently are not popular, battle-tested tools to get around this limitation, so be aware that such migrations will require scheduled downtime.

<img loading="lazy" src="{{ '/images/railsworld-2024/115.png' | relative_url }}" alt="" style="width: 100%" />

The next detail to be considerate of is that SQLite is built to work best on a single machine. And this means that as you need to scale, vertical scaling is your best bet. Expanding the size of that single machine as needed.

<img loading="lazy" src="{{ '/images/railsworld-2024/vertical-scaling.gif' | relative_url }}" alt="" style="width: 100%" />

Now, there is a fair chance that many of you have some out of date presumptions about the size of machine that you can rent and run using off-the-shelf providers like Digital Ocean or Hetzner or AWS.

<img loading="lazy" src="{{ '/images/railsworld-2024/117.png' | relative_url }}" alt="" style="width: 100%" />

Because you can get a big box.

<img loading="lazy" src="{{ '/images/railsworld-2024/118.png' | relative_url }}" alt="" style="width: 100%" />

Like, a really really big box. You can rent [a VPS from Hetzner](https://www.exoscale.com/pricing/) with 48 cores, 192 gigs of RAM, and 1 terabyte of NVME SSD space. All for no more than 350 dollars a month. That is a beast.

<img loading="lazy" src="{{ '/images/railsworld-2024/119.png' | relative_url }}" alt="" style="width: 100%" />

So, don’t put an artificial ceiling on how far vertical scaling can take an application.

<img loading="lazy" src="{{ '/images/railsworld-2024/120.png' | relative_url }}" alt="" style="width: 100%" />

But, I know that we have all been told for the last decade that the only “correct” way to build web apps is with redundancy,

<img loading="lazy" src="{{ '/images/railsworld-2024/121.png' | relative_url }}" alt="" style="width: 100%" />

and high availability,

<img loading="lazy" src="{{ '/images/railsworld-2024/122.png' | relative_url }}" alt="" style="width: 100%" />

and automatic failovers,

<img loading="lazy" src="{{ '/images/railsworld-2024/123.png' | relative_url }}" alt="" style="width: 100%" />

and zero to infinity auto scaling, and all the rest.

The fact, though, is that these are solutions to problems that a _minority_ of applications on the internet do have or will ever have.

<img loading="lazy" src="{{ '/images/railsworld-2024/124.png' | relative_url }}" alt="" style="width: 100%" />

And they come with real trade-offs around operational complexity. Remember, the larger the surface area of your system, the more opportunities for failures.

<img loading="lazy" src="{{ '/images/railsworld-2024/125.png' | relative_url }}" alt="" style="width: 100%" />

So ask yourself, do I truly _need_ all of that, especially on day one, or should I start with a stack simple enough to keep in my head, yet powerful enough to serve my customers’ needs.

<img loading="lazy" src="{{ '/images/railsworld-2024/126.png' | relative_url }}" alt="" style="width: 100%" />

So, like any tool, SQLite does come with tradeoffs. There is no perfect tool, no perfect stack, no set of decisions that require no additional considerations. You must always learn your tools, their quirks and idiosyncrasies, if you want to make maximal use of them. But, when you choose high-leverage tools, tools that are well-built and well-known, tools that might be considered boring, you unlock the power of simplicity.

<img loading="lazy" src="{{ '/images/railsworld-2024/127.png' | relative_url }}" alt="" style="width: 100%" />

You truly can, today, build an application that has the power to take your next idea to Mars. But you don’t need to be a rocket scientist to run it. Rails 8 and SQLite strip away the incidental complexity…

<img loading="lazy" src="{{ '/images/railsworld-2024/128.png' | relative_url }}" alt="" style="width: 100%" />

leaving you with the leanest, simplest, most powerful application stack imaginable. And few things are as powerful as those tools that have earned their simplicity through years of evolution and consideration.

<img loading="lazy" src="{{ '/images/railsworld-2024/129.png' | relative_url }}" alt="" style="width: 100%" />

These are the kinds of engines that empower individuals to build production-grade, full-featured, valuable applications faster, simpler, and cheaper than ever before. These are the tools that enable a “one person framework”. And whether you are an individual, a small team, or even a large team—these are the tools that provide you the leverage and power to launch.

<img loading="lazy" src="{{ '/images/railsworld-2024/rocket-boost.gif' | relative_url }}" alt="" style="width: 100%" />

SQLite and Rails are unique pair, a powerful pair. And I hope that after this exploration you better understand and appreciate how well SQLite pairs with Rails as an engine for creativity and building. And, I hope that you now feel confident that you can, and maybe should, build and run your next Rails application with SQLite.

<img loading="lazy" src="{{ '/images/railsworld-2024/131.png' | relative_url }}" alt="" style="width: 100%" />

Thank you.

<img loading="lazy" src="{{ '/images/railsworld-2024/132.png' | relative_url }}" alt="" style="width: 100%" />

- - -

This is an edited transcript of a talk I gave at [Rails World 2024](https://rubyonrails.org/world/2024). You can watch the full talk on YouTube below.

[![Stephen Margheim - SQLite on Rails: Supercharging the One-Person Framework - Rails World 2024
](https://img.youtube.com/vi/l56IBad-5aQ/0.jpg)](https://www.youtube.com/watch?v=l56IBad-5aQ "How (and why) to run SQLite in production")

- - -

