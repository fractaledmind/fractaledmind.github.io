---
series: SQLite Myths
title: Linear writes don't scale
date: 2023-12-05
tags:
  - code
  - ruby
  - rails
  - sqlite
---

One of the biggest myths around running SQLite in production for web applications is that it simply won't _scale_ beyond "toy/hobby" numbers, primarily because SQLite requires linear writes (that is, it doesn't support concurrent writes). This isn't true. Let's dig into why.

<!--/summary-->

- - -

SQLite [lays out clearly](https://www.sqlite.org/howtocorrupt.html) the situations under which a client/server database (like Postgres or MySQL) is a better fit than SQLite. One of those scenarios is when you need to support a large number of concurrent writes:

> SQLite supports an unlimited number of simultaneous readers, but it will only allow one writer at any instant in time. For many situations, this is not a problem. Writers queue up. Each application does its database work quickly and moves on, and no lock lasts for more than a few dozen milliseconds. But there are some applications that require more concurrency, and those applications may need to seek a different solution.

The question, therefore, is: what is a "large number of concurrent writes"? SQLite doesn't give a specific number. In order to figure this out, I spun up a new Rails application and did some basic load testing to see how SQLite's linear writes affect performance under concurrent load.

The results show clearly that a Rails application using a single SQLite database can handle thousands of concurrent write requests per second on even a modestly powerful machine. This is more than enough for most applications, and certainly enough for a large number of applications that are currently using a client/server database.

But, let's dig into the details.

- - -

To start, I scaffolded a new Rails app:

```shell
rails new sqlite-benchmark --database=sqlite3 --asset-pipeline=propshaft --javascript=esbuild --css=tailwind --skip-jbuilder --skip-action-mailbox --skip-spring
```

I setup a resource that doesn't require any inputs so that we can load test `POST` requests without needing a tool that can generate dynamic inputs:

```shell
bin/rails generate scaffold Request uid:string:uniq ip:string method:string url:string parameters:json --skip-test-framework --skip-helper
```

I then updated the `create` method to simply create a new record with the request's data:

```ruby
@request = Request.new(
  uid: request.uuid,
  ip: request.remote_ip,
  method: request.method,
  url: request.original_url,
  parameters: request.request_parameters,
)
```

I am running these benchmarks locally on my MacBook Pro (16-inch, 2021), which has an Apple M1 Max chip and 32GB of RAM running macOS Monterey (12.5.1). The app is running Ruby 3.2.2, Rails 7.1.2, and SQLite 3.44.2 (via the [1.6.9](https://github.com/sparklemotion/sqlite3-ruby/releases/tag/v1.6.9) version of the [`sqlite3-ruby`](https://github.com/sparklemotion/sqlite3-ruby) gem).

In order to get performant, production-grade results, I am running the Rails server in the `production` environment, with YJIT enabled, and using Puma in clustered mode (10 workers, 3 threads each), and turning off logging:

```shell
RAILS_LOG_LEVEL=warn RUBY_YJIT_ENABLE=1 SECRET_KEY_BASE=asdf RAILS_ENV=production WEB_CONCURRENCY=10 RAILS_MAX_THREADS=3 bin/rails server
```

You can see the full app code [here](https://github.com/fractaledmind/rubyconftw/tree/reset).

In order to perform the load testing, I am using the simple `hey` CLI (`brew install hey`). I run each test for 10 seconds, and I run each test 3 times to get an average:

```shell
hey -c N -z 10s -m POST http://127.0.0.1:3000/requests
```

`N` is the number of concurrent write requests. I scaled up from 1 to 16 concurrent requests, doubling the number of concurrent requests each time. I also ran a test with 10 concurrent requests, which matches the number of Puma workers. As you will see, this is the sweet spot for this app.

Here are my results as I scale up the number of concurrent write requests.

{:.tables}
| Concurrent requests | <abbr title="requests per second">RPS</abbr>   | Average response time | Slowest response time |
| :---:               | :---  | :---                  | :---                  |
| 1                   | 750   | 1.33ms                | 13.1ms                |
| 2                   | 1,080 | 1.83ms                | 15.4ms                |
| 4                   | 1,889 | 2.1ms                 | 40.8ms                |
| 8                   | 2,572 | 3.1ms                 | 189.4ms               |
| 10                  | 2,730 | 3.67ms                | 249.3ms               |
| 16                  | 633   | 26.4ms                | 5.4s                  |

The key details here are that the Rails app can handle a peak of **_2.5k+ write requests per second_**. Now, this is a synthetic benchmark, and we are only making one SQL write within the `POST` write request. Additionally our table is simple with a single primary key index. In a real-world application, you are going to have more SQL writes per HTTP request, you are going to mix in additional SQL reads within each HTTP request as well, and you are going to be querying more, larger, more complex tables, and those tables are going to have more indexes. So, this benchmark does not suggest that you will get 2k RPS on a real-world Rails application. The point here is to isolate SQLite linear writes and consider the degree to which they limit a SQLite on Rails application to scale beyond "toy" levels. And on that point, I think this benchmark shows that SQLite linear writes are not a de-facto limiting factor.

Returning to the synthetic benchmark results, to put them in perspective, [Nate Berkopec's post](https://www.speedshop.co/2015/07/29/scaling-ruby-apps-to-1000-rpm.html) in 2015 about scaling Rails applications provides some context from Twitter and Shopify when they were both monolithic Rails apps. Twitter in 2007 was handling 600 requests per second,[^1] and Shopify in 2013 was handling 833 requests per second.[^2] Both of these apps were running on client/server databases, and both of these apps were handling less than half the number of requests per second that this Rails app is handling. Plus, these are numbers for total requests, not just write requests. For this profiling, we are talking about pure writes; read requests will scale much further. Of course, both applications are real-world applications with more tables with more indexes and requests that are doing much more work than inserting into a single simple table. The comparison here is not apples-to-apples, but it does provide some context for the potential scalability of a SQLite on Rails app.

If you use the rule-of-thumb that all of the requests your app receives in a 24 hour period can be packed into a 4 hour period, then in order to handle 1 million write requests per day, you only need to handle 70 write requests per second.[^3] This "napkin-math" suggests that this Rails app could handle **over 35 million write requests per day**.

Another way to put this in perspective is to consider how many "daily active users" (<abbr>DAU</abbr>) you can reasonably expect to handle at this throughput. Given that we could handle over 35 million write requests per day, this means that we could handle **1 million <abbr title="daily active users">DAUs</abbr>** if each user made _35 write requests per day_. This is a pretty generous performance ceiling for most applications.

So, I think it is fair to say, this myth is just that — a myth. A SQLite on Rails application can handle a lot of traffic. The fact that SQLite only allows linear writes does not put a performance ceiling on your application.

That being said, we do also see that there is a point where the performance starts to degrade. By running the Rails app in Puma's clustered mode with 10 workers, the app can handle 10 concurrent requests. On my machine, if we have more concurrent requests coming in than Puma workers, the contention on our SQLite database can lead to timeouts. However, on a larger machine, like [Joel Drapper's](https://ruby.social/@joeldrapper) MacBook Pro (16-inch, 2023), which has an Apple 16-core M3 Max chip and 128GB of RAM running macOS Sonoma (14.1.2), the app can handle many more concurrent requests than the number of Puma workers. We saw no issues up to 128 concurrent requests on Joel's machine running on 16 Puma workers.[^4] So, a SQLite on Rails app can handle more concurrent write requests than the number of Puma workers, but you do need a powerful enough machine.

So, on smaller and cheaper machines, you will be better off to ensure that you can provide enough Puma workers to handle your expected peak number of concurrent write requests. And thus, the myth is _partially_ true — you do need to be careful about how many concurrent requests you expect to receive, but this is true of any application, regardless of the database you are using. The maximum number of concurrent requests will also be a clear signal for when you need to vertically scale.

It is also worth mentioning that any single slow write (e.g. creating an index on a large table) will slow down a write heavy app while it is running, so SQLite users need to be careful when they issue any slow write query. However, even a write heavy real-world application will have a mix of writes and reads. This benchmarking is very synthetic, as it constantly hits the server with `POST` requests. In a real-world application, even a write heavy one, the natural distribution of read requests and write requests, as well as the naturally stochastic distribution of requests from users, will allow SQLite to scale well and perhaps even look better than these benchmarks suggest.

Moreover, I want to be clear that these benchmarks are testing a simple `POST` route. In a real-world Rails application, you are very likely to have more latency on your requests, so you will see slower response times and thus fewer write requests per second. But, this is true of any application, regardless of the database you are using. The point is that SQLite is not going to be the bottleneck in your application.

With all of this in mind, I think it is fair to say that SQLite is a great choice for a lot of applications. It is simple, it is fast, and it is reliable. It is a great choice for a lot of applications, and it is a great choice for a lot of Rails applications.

Let's now take a look at the details for our load testing.

- - -

{:.notice}
1 concurrent request: RPS: **_750_**, Average: **1.33ms**, Slowest: _13.1ms_

<details markdown="1">
  <summary>Full breakdown of 3 runs</summary>
```shell
$ hey -c 1 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0001 secs
  Slowest:	0.0131 secs
  Fastest:	0.0010 secs
  Average:	0.0013 secs
  Requests/sec:	758.9932

  Total data:	11217741 bytes
  Size/request:	1477 bytes

Response time histogram:
  0.001 [1]    |
  0.002 [7532] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.003 [26]   |
  0.005 [17]   |
  0.006 [4]    |
  0.007 [1]    |
  0.008 [1]    |
  0.009 [1]    |
  0.011 [4]    |
  0.012 [2]    |
  0.013 [1]    |


Latency distribution:
  10% in 0.0011 secs
  25% in 0.0012 secs
  50% in 0.0013 secs
  75% in 0.0014 secs
  90% in 0.0015 secs
  95% in 0.0017 secs
  99% in 0.0021 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0010 secs, 0.0131 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0001 secs
  resp wait:	0.0007 secs, 0.0005 secs, 0.0078 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0001 secs

Status code distribution:
  [200]	7590 responses
```

```shell
$ hey -c 1 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0022 secs
  Slowest:	0.0127 secs
  Fastest:	0.0010 secs
  Average:	0.0014 secs
  Requests/sec:	716.5437

  Total data:	10599993 bytes
  Size/request:	1479 bytes

Response time histogram:
  0.001 [1]    |
  0.002 [7072] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.003 [58]   |
  0.005 [23]   |
  0.006 [4]    |
  0.007 [1]    |
  0.008 [1]    |
  0.009 [0]    |
  0.010 [1]    |
  0.012 [4]    |
  0.013 [2]    |


Latency distribution:
  10% in 0.0011 secs
  25% in 0.0012 secs
  50% in 0.0013 secs
  75% in 0.0015 secs
  90% in 0.0017 secs
  95% in 0.0019 secs
  99% in 0.0022 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0010 secs, 0.0127 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0001 secs
  resp wait:	0.0007 secs, 0.0005 secs, 0.0071 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0001 secs

Status code distribution:
  [200]	7167 responses
```

```shell
$ hey -c 1 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0012 secs
  Slowest:	0.0116 secs
  Fastest:	0.0010 secs
  Average:	0.0013 secs
  Requests/sec:	786.6088

  Total data:	11635293 bytes
  Size/request:	1479 bytes

Response time histogram:
  0.001 [1]    |
  0.002 [7785] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.003 [37]   |
  0.004 [19]   |
  0.005 [12]   |
  0.006 [1]    |
  0.007 [2]    |
  0.008 [1]    |
  0.009 [3]    |
  0.011 [3]    |
  0.012 [3]    |


Latency distribution:
  10% in 0.0011 secs
  25% in 0.0011 secs
  50% in 0.0012 secs
  75% in 0.0013 secs
  90% in 0.0015 secs
  95% in 0.0017 secs
  99% in 0.0020 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0010 secs, 0.0116 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0001 secs
  resp wait:	0.0006 secs, 0.0005 secs, 0.0076 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0002 secs

Status code distribution:
  [200]	7867 responses
```
</details>

{:.notice}
2 concurrent requests: RPS: **_1,080_**, Average: **1.83ms**, Slowest: _15.4ms_

<details markdown="1">
  <summary>Full breakdown of 3 runs</summary>
```shell
$ hey -c 2 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0007 secs
  Slowest:	0.0154 secs
  Fastest:	0.0011 secs
  Average:	0.0019 secs
  Requests/sec:	1079.0224

  Total data:	15959889 bytes
  Size/request:	1479 bytes

Response time histogram:
  0.001 [1]    |
  0.003 [9789] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.004 [892]  |■■■■
  0.005 [59]   |
  0.007 [28]   |
  0.008 [5]    |
  0.010 [9]    |
  0.011 [1]    |
  0.013 [5]    |
  0.014 [1]    |
  0.015 [1]    |


Latency distribution:
  10% in 0.0014 secs
  25% in 0.0016 secs
  50% in 0.0017 secs
  75% in 0.0019 secs
  90% in 0.0024 secs
  95% in 0.0029 secs
  99% in 0.0039 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0011 secs, 0.0154 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0001 secs
  resp wait:	0.0009 secs, 0.0005 secs, 0.0087 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0005 secs

Status code distribution:
  [200]	10791 responses
```

```shell
$ hey -c 2 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0020 secs
  Slowest:	0.0140 secs
  Fastest:	0.0011 secs
  Average:	0.0018 secs
  Requests/sec:	1083.4833

  Total data:	16027923 bytes
  Size/request:	1479 bytes

Response time histogram:
  0.001 [1]    |
  0.002 [9972] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.004 [753]  |■■■
  0.005 [38]   |
  0.006 [29]   |
  0.008 [14]   |
  0.009 [13]   |
  0.010 [8]    |
  0.011 [3]    |
  0.013 [3]    |
  0.014 [3]    |


Latency distribution:
  10% in 0.0015 secs
  25% in 0.0016 secs
  50% in 0.0017 secs
  75% in 0.0019 secs
  90% in 0.0022 secs
  95% in 0.0029 secs
  99% in 0.0038 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0011 secs, 0.0140 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0005 secs
  resp wait:	0.0009 secs, 0.0005 secs, 0.0091 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0014 secs

Status code distribution:
  [200]	10837 responses
```

```shell
$ hey -c 2 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0015 secs
  Slowest:	0.0129 secs
  Fastest:	0.0011 secs
  Average:	0.0018 secs
  Requests/sec:	1081.2370

  Total data:	15993906 bytes
  Size/request:	1479 bytes

Response time histogram:
  0.001 [1]    |
  0.002 [9657] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.003 [995]  |■■■■
  0.005 [63]   |
  0.006 [37]   |
  0.007 [21]   |
  0.008 [13]   |
  0.009 [14]   |
  0.011 [6]    |
  0.012 [4]    |
  0.013 [3]    |


Latency distribution:
  10% in 0.0015 secs
  25% in 0.0016 secs
  50% in 0.0017 secs
  75% in 0.0019 secs
  90% in 0.0023 secs
  95% in 0.0029 secs
  99% in 0.0042 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0011 secs, 0.0129 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0001 secs
  resp wait:	0.0009 secs, 0.0005 secs, 0.0087 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0017 secs

Status code distribution:
  [200]	10814 responses
```
</details>

{:.notice}
4 concurrent requests: RPS: **_1,889_**, Average: **2.1ms**, Slowest: _40.8ms_

<details markdown="1">
  <summary>Full breakdown of 3 runs</summary>
```shell
$ hey -c 4 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0025 secs
  Slowest:	0.0398 secs
  Fastest:	0.0011 secs
  Average:	0.0021 secs
  Requests/sec:	1882.4288

  Total data:	27848091 bytes
  Size/request:	1479 bytes

Response time histogram:
  0.001 [1]     |
  0.005 [18389] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.009 [322]   |■
  0.013 [108]   |
  0.017 [3]     |
  0.020 [0]     |
  0.024 [3]     |
  0.028 [0]     |
  0.032 [1]     |
  0.036 [0]     |
  0.040 [2]     |


Latency distribution:
  10% in 0.0016 secs
  25% in 0.0017 secs
  50% in 0.0019 secs
  75% in 0.0020 secs
  90% in 0.0031 secs
  95% in 0.0033 secs
  99% in 0.0059 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0011 secs, 0.0398 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0002 secs
  resp wait:	0.0010 secs, 0.0006 secs, 0.0081 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0002 secs

Status code distribution:
  [200]	18829 responses
```

```shell
$ hey -c 4 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0022 secs
  Slowest:	0.0238 secs
  Fastest:	0.0012 secs
  Average:	0.0021 secs
  Requests/sec:	1896.5768

  Total data:	28057356 bytes
  Size/request:	1479 bytes

Response time histogram:
  0.001 [1]     |
  0.003 [18271] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.006 [437]   |■
  0.008 [129]   |
  0.010 [48]    |
  0.012 [70]    |
  0.015 [9]     |
  0.017 [0]     |
  0.019 [0]     |
  0.022 [1]     |
  0.024 [4]     |


Latency distribution:
  10% in 0.0016 secs
  25% in 0.0017 secs
  50% in 0.0018 secs
  75% in 0.0020 secs
  90% in 0.0031 secs
  95% in 0.0033 secs
  99% in 0.0059 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0012 secs, 0.0238 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0000 secs
  resp wait:	0.0009 secs, 0.0005 secs, 0.0082 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0003 secs

Status code distribution:
  [200]	18970 responses
```

```shell
$ hey -c 4 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0033 secs
  Slowest:	0.0408 secs
  Fastest:	0.0011 secs
  Average:	0.0021 secs
  Requests/sec:	1887.7847

  Total data:	27986088 bytes
  Size/request:	1482 bytes

Response time histogram:
  0.001 [1]     |
  0.005 [18397] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.009 [364]   |■
  0.013 [109]   |
  0.017 [7]     |
  0.021 [2]     |
  0.025 [3]     |
  0.029 [0]     |
  0.033 [0]     |
  0.037 [0]     |
  0.041 [1]     |


Latency distribution:
  10% in 0.0016 secs
  25% in 0.0017 secs
  50% in 0.0018 secs
  75% in 0.0020 secs
  90% in 0.0031 secs
  95% in 0.0033 secs
  99% in 0.0060 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0011 secs, 0.0408 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0003 secs
  resp wait:	0.0009 secs, 0.0005 secs, 0.0106 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0004 secs

Status code distribution:
  [200]	18884 responses
```
</details>

{:.notice}
8 concurrent requests: RPS: **_2,572_**, Average: **3.1ms**, Slowest: _189.4ms_

<details markdown="1">
  <summary>Full breakdown of 3 runs</summary>
```shell
$ hey -c 8 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0283 secs
  Slowest:	0.1154 secs
  Fastest:	0.0013 secs
  Average:	0.0032 secs
  Requests/sec:	2488.6530

  Total data:	36986274 bytes
  Size/request:	1482 bytes

Response time histogram:
  0.001 [1]     |
  0.013 [24629] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.024 [236]   |
  0.036 [24]    |
  0.047 [46]    |
  0.058 [2]     |
  0.070 [9]     |
  0.081 [0]     |
  0.093 [6]     |
  0.104 [0]     |
  0.115 [4]     |


Latency distribution:
  10% in 0.0018 secs
  25% in 0.0020 secs
  50% in 0.0023 secs
  75% in 0.0033 secs
  90% in 0.0049 secs
  95% in 0.0063 secs
  99% in 0.0139 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0013 secs, 0.1154 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0005 secs
  resp wait:	0.0012 secs, 0.0006 secs, 0.0196 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0006 secs

Status code distribution:
  [200]	24957 responses
```

```shell
$ hey -c 8 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0049 secs
  Slowest:	0.1219 secs
  Fastest:	0.0013 secs
  Average:	0.0031 secs
  Requests/sec:	2588.3327

  Total data:	38377872 bytes
  Size/request:	1482 bytes

Response time histogram:
  0.001 [1]     |
  0.013 [25608] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.025 [189]   |
  0.038 [10]    |
  0.050 [54]    |
  0.062 [17]    |
  0.074 [5]     |
  0.086 [4]     |
  0.098 [1]     |
  0.110 [1]     |
  0.122 [6]     |


Latency distribution:
  10% in 0.0018 secs
  25% in 0.0019 secs
  50% in 0.0021 secs
  75% in 0.0032 secs
  90% in 0.0041 secs
  95% in 0.0062 secs
  99% in 0.0204 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0013 secs, 0.1219 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0002 secs
  resp wait:	0.0011 secs, 0.0006 secs, 0.0141 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0003 secs

Status code distribution:
  [200]	25896 responses
```

```shell
$ hey -c 8 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0155 secs
  Slowest:	0.1894 secs
  Fastest:	0.0013 secs
  Average:	0.0030 secs
  Requests/sec:	2639.4073

  Total data:	39176670 bytes
  Size/request:	1482 bytes

Response time histogram:
  0.001 [1]     |
  0.020 [26198] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.039 [168]   |
  0.058 [30]    |
  0.077 [23]    |
  0.095 [10]    |
  0.114 [3]     |
  0.133 [0]     |
  0.152 [0]     |
  0.171 [0]     |
  0.189 [2]     |


Latency distribution:
  10% in 0.0018 secs
  25% in 0.0019 secs
  50% in 0.0021 secs
  75% in 0.0032 secs
  90% in 0.0040 secs
  95% in 0.0060 secs
  99% in 0.0131 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0013 secs, 0.1894 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0003 secs
  resp wait:	0.0011 secs, 0.0006 secs, 0.0094 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0004 secs

Status code distribution:
  [200]	26435 responses
```
</details>

{:.notice}
16 concurrent requests: RPS: **_633_**, Average: **26.4ms**, Slowest: _5.4s_

<details markdown="1">
  <summary>Full breakdown of 3 runs</summary>
```shell
$ hey -c 16 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	15.0306 secs
  Slowest:	5.4021 secs
  Fastest:	0.0015 secs
  Average:	0.0197 secs
  Requests/sec:	809.9469

  Total data:	18044622 bytes
  Size/request:	1482 bytes

Response time histogram:
  0.001 [1]     |
  0.542 [12141] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  1.082 [0]     |
  1.622 [0]     |
  2.162 [0]     |
  2.702 [0]     |
  3.242 [0]     |
  3.782 [0]     |
  4.322 [0]     |
  4.862 [0]     |
  5.402 [32]    |


Latency distribution:
  10% in 0.0020 secs
  25% in 0.0029 secs
  50% in 0.0040 secs
  75% in 0.0060 secs
  90% in 0.0095 secs
  95% in 0.0148 secs
  99% in 0.0448 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0015 secs, 5.4021 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0004 secs
  resp wait:	0.0123 secs, 0.0007 secs, 5.4014 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0011 secs

Status code distribution:
  [200]	12156 responses
  [500]	18 responses
```

```shell
$ hey -c 16 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	13.7486 secs
  Slowest:	5.3682 secs
  Fastest:	0.0014 secs
  Average:	0.0262 secs
  Requests/sec:	609.3717

  Total data:	12418338 bytes
  Size/request:	1482 bytes

Response time histogram:
  0.001 [1]    |
  0.538 [8345] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  1.075 [0]    |
  1.611 [0]    |
  2.148 [0]    |
  2.685 [0]    |
  3.221 [0]    |
  3.758 [0]    |
  4.295 [0]    |
  4.831 [0]    |
  5.368 [32]   |


Latency distribution:
  10% in 0.0021 secs
  25% in 0.0030 secs
  50% in 0.0043 secs
  75% in 0.0064 secs
  90% in 0.0110 secs
  95% in 0.0157 secs
  99% in 0.0460 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0014 secs, 5.3682 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0006 secs
  resp wait:	0.0138 secs, 0.0007 secs, 5.3670 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0009 secs

Status code distribution:
  [200]	8364 responses
  [500]	14 responses
```

```shell
$ hey -c 16 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	12.6489 secs
  Slowest:	5.3700 secs
  Fastest:	0.0015 secs
  Average:	0.0333 secs
  Requests/sec:	479.8842

  Total data:	8998341 bytes
  Size/request:	1482 bytes

Response time histogram:
  0.001 [1]    |
  0.538 [6037] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  1.075 [0]    |
  1.612 [0]    |
  2.149 [0]    |
  2.686 [0]    |
  3.223 [0]    |
  3.759 [0]    |
  4.296 [0]    |
  4.833 [0]    |
  5.370 [32]   |


Latency distribution:
  10% in 0.0020 secs
  25% in 0.0024 secs
  50% in 0.0038 secs
  75% in 0.0061 secs
  90% in 0.0106 secs
  95% in 0.0151 secs
  99% in 0.0455 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0015 secs, 5.3700 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0002 secs
  resp wait:	0.0239 secs, 0.0007 secs, 5.3662 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0006 secs

Status code distribution:
  [200]	6053 responses
  [500]	17 responses
```
</details>

When we come back down and match the number of Puma workers with 10 concurrent requests, we see the peak of our throughput and no dropped requests:

{:.notice}
10 concurrent requests: RPS: **_2,730_**, Average: **3.67ms**, Slowest: _249.3ms_

<details markdown="1">
  <summary>Full breakdown of 3 runs</summary>
```shell
$ hey -c 10 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0176 secs
  Slowest:	0.1979 secs
  Fastest:	0.0013 secs
  Average:	0.0037 secs
  Requests/sec:	2679.2759

  Total data:	39776880 bytes
  Size/request:	1482 bytes

Response time histogram:
  0.001 [1]     |
  0.021 [26307] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.041 [408]   |■
  0.060 [44]    |
  0.080 [38]    |
  0.100 [21]    |
  0.119 [15]    |
  0.139 [3]     |
  0.159 [2]     |
  0.178 [0]     |
  0.198 [1]     |


Latency distribution:
  10% in 0.0018 secs
  25% in 0.0020 secs
  50% in 0.0023 secs
  75% in 0.0034 secs
  90% in 0.0058 secs
  95% in 0.0097 secs
  99% in 0.0243 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0013 secs, 0.1979 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0003 secs
  resp wait:	0.0012 secs, 0.0006 secs, 0.0847 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0005 secs

Status code distribution:
  [200]	26840 responses
```

```shell
$ hey -c 10 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0043 secs
  Slowest:	0.2493 secs
  Fastest:	0.0013 secs
  Average:	0.0037 secs
  Requests/sec:	2708.7337

  Total data:	40160718 bytes
  Size/request:	1482 bytes

Response time histogram:
  0.001 [1]     |
  0.026 [26898] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.051 [112]   |
  0.076 [43]    |
  0.101 [25]    |
  0.125 [10]    |
  0.150 [6]     |
  0.175 [0]     |
  0.200 [1]     |
  0.225 [1]     |
  0.249 [2]     |


Latency distribution:
  10% in 0.0018 secs
  25% in 0.0020 secs
  50% in 0.0023 secs
  75% in 0.0034 secs
  90% in 0.0059 secs
  95% in 0.0071 secs
  99% in 0.0235 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0013 secs, 0.2493 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0005 secs
  resp wait:	0.0011 secs, 0.0006 secs, 0.0208 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0005 secs

Status code distribution:
  [200]	27099 responses
```

```shell
$ hey -c 10 -z 10s -m POST http://127.0.0.1:3000/requests

Summary:
  Total:	10.0099 secs
  Slowest:	0.1965 secs
  Fastest:	0.0012 secs
  Average:	0.0036 secs
  Requests/sec:	2803.6254

  Total data:	41590848 bytes
  Size/request:	1482 bytes

Response time histogram:
  0.001 [1]     |
  0.021 [27588] |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  0.040 [362]   |■
  0.060 [40]    |
  0.079 [36]    |
  0.099 [21]    |
  0.118 [5]     |
  0.138 [1]     |
  0.157 [6]     |
  0.177 [0]     |
  0.196 [4]     |


Latency distribution:
  10% in 0.0018 secs
  25% in 0.0019 secs
  50% in 0.0022 secs
  75% in 0.0033 secs
  90% in 0.0057 secs
  95% in 0.0069 secs
  99% in 0.0233 secs

Details (average, fastest, slowest):
  DNS+dialup:	0.0000 secs, 0.0012 secs, 0.1965 secs
  DNS-lookup:	0.0000 secs, 0.0000 secs, 0.0000 secs
  req write:	0.0000 secs, 0.0000 secs, 0.0004 secs
  resp wait:	0.0011 secs, 0.0006 secs, 0.0106 secs
  resp read:	0.0000 secs, 0.0000 secs, 0.0005 secs

Status code distribution:
  [200]	28064 responses
```
</details>

- - -

## All posts in this series

* [Myth 1 — concurrent writes can corrupt the database]({% link _posts/2023-10-13-sqlite-myths-concurrent-writes-can-corrupt-the-database.md %})
* [Myth 2 — don't use autoincrement primary keys]({% link _posts/2023-11-12-sqlite-myths-autoincrement-primary-keys.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Myth 3 — linear writes do not scale]({% link _posts/2023-12-05-sqlite-myths-linear-writes-do-not-scale.md %})

- - -

[^1]: This information was provided in [a presentation](http://www.slideshare.net/Blaine/scaling-twitter) was given at SDForum Silicon Valley by a Twitter engineer.
[^2]: This information was provided in [a presentation](https://www.youtube.com/watch?v=j347oSSuNHA#t=7m44s) at Big Ruby by Shopify engineer John Duff.
[^3]: This rule-of-thumb is suggested by Jaime Buelta in [this post](https://wrongsideofmemphis.com/2013/10/21/requests-per-second-a-reference/). The 70 RPS equaling 1M RPD comes from the simple calculation: `1_000_000/(60*60*4)`. So, for 1 million requests per day, you need to be able to handle 70 requests per second.
[^4]: On Joel's machine, we see basically a 2× increase of RPS, in addition to the ability to handle increased concurrency beyond the number of Puma workers. This goes to show how powerful vertical scaling can be. Simply with a bigger, newer machine, Joel gets massive performance improvements with the exact same codebase. RPS: **_4,272_**, Average: **29.2ms**, Slowest: _65.1ms_.
