---
series: SQLite in Ruby
title: Alternative busy handler implementations
date: 2024-07-20
tags:
  - code
  - ruby
  - sqlite
---

Yesterday, I wrote about [the problems with the backoff busy handler implementation in SQLite]({% link _posts/2024-07-19-sqlite-in-ruby-backoff-busy-handler-problems.md %}). In order to explore the differences in busy handler implementations, I wrote [a pair of scripts](https://gist.github.com/fractaledmind/56329e5893777dbf43b8c480df554bfb) that would run a set of scenarios across a range of contention levels. The scripts would then output the results in a table that I could use to compare the different busy handler implementations. While the first experiment was focused on the problems with the backoff busy handler, I wanted to use this sandobx to experiment with alternative busy handler implementations. Let's explore.

<!--/summary-->

- - -

In the original experiment, I only considered two modes for the `busy_handler`—the `constant` mode will always sleep for 1ms (`busy_handler { |_count| sleep 0.001 }`) and the `backoff` mode always sleeps for N milliseconds, where N is the number of times the handler has been called (`busy_handler { |count| sleep count * 0.001 }`). Today, I want to explore some additional modes, which I call `jitter`, `ceiling`, and `reversed`.

The `jitter` busy handler will sleep for a random number of milliseconds between 1 and 10 (`busy_handler { |_count| sleep 0.001 * rand(1..10) }`). The `ceiling` busy handler will sleep an increasing number of milliseconds between 1 and 10, but never more than 10 (`busy_handler { |count| sleep (count > 10 ? 10 : count) * 0.001 }`). The `reversed` busy handler will sleep a decreasing number of milliseconds between 1 and 10, but never less than 1 (`busy_handler { |count| sleep (count >= 10 ? 1 : 10 - count) * 0.001 }`).

The goal of this experiment is to see if any of these alternative busy handler implementations perform better than the `constant` implementation across the three scenarios we considered in the original experiment. To recap, the three scenarios are:

1. all queries are fast
2. one slow query with contention from fast queries
3. two slow queries with contention from fast queries

Across the three scenarios, we have an ideal case that we are searching for. In the first scenario, where the parent process run zero slow queries so all contention comes from the fast queries that the child connections are running, the ideal case is that the script, parent connection, fastest child connection, and slowest child connection all finish in very short durations (i.e. less than 50ms). In the second scenario, where the parent process runs only one slow query so there is contention between the fast queries from the children connections and the slow query in the parent connection, the ideal case is that the gap between the duration for the parent connection and the script duration is minimal as well as that the gap between the fastest and slowest child connection is minimal. Finally, in the third scenario, where the parent connection is running two slow queries with a 1ms gap in between executions, the ideal case is that the gap between fastest and slowest child connections is minimal (tho it will be larger than previous scenarios, because the slowest child connection will be the one that has to wait for both slow parent queries to finish).

In testing the various busy handler implementations, I run each implementation through a variety of contention situations. Each situation is defined by:

* the number of child processes
* the number of threads per child process
* the number of slow queries that the parent process will run

Each variable is listed, in order, under the `CONTENTION` column in the report output table. The overall "contention level" is the sum of these three variables. For example, a contention level of 6 (4/2/0) means that there are 4 child processes, each with 2 threads, and the parent process will run 0 slow queries. A contention level of 8 (4/2/2) means that there are 4 child processes, each with 2 threads, and the parent process will run 2 slow queries. And so on.

For each situation, we track four durations and make one calculation:

1. the time it takes for the parent process to run
2. the time it takes for the fastest child process to run
3. the time it takes for the slowest child process to run
4. the time it takes for the entire script to run
5. the delta between the parent process duration and slowest child process duration

Each value is the number of milliseconds that it took to complete the task. For the delta, a negative delta means that the parent process ran faster than the slowest child process.

Our baseline is the `constant` mode implementation. Here are its results for the three scenarios across the various contention levels:

```
   MODE    |  CONTENTION  |  PARENT  |  FASTEST  |  SLOWEST  |  SCRIPT  |  DELTA
 constant  |  6 (4/2/0)   |       0  |        1  |        3  |       2  |     -3
 constant  |  8 (4/4/0)   |       0  |        0  |        9  |       1  |     -9
 constant  |  10 (8/2/0)  |       0  |        1  |        8  |       3  |     -8
 constant  |  12 (8/4/0)  |       0  |        0  |       27  |       3  |    -27

 constant  |  7 (4/2/1)   |    1071  |      869  |      875  |    1073  |    196
 constant  |  9 (4/4/1)   |    1077  |      876  |      893  |    1078  |    184
 constant  |  11 (8/2/1)  |    1077  |      877  |      891  |    1080  |    186
 constant  |  13 (8/4/1)  |    1076  |      878  |      902  |    1079  |    174

 constant  |  8 (4/2/2)   |    2142  |      871  |     1944  |    2144  |    198
 constant  |  10 (4/4/2)  |    2144  |      871  |     1952  |    2146  |    192
 constant  |  12 (8/2/2)  |    2141  |      867  |     1953  |    2143  |    188
 constant  |  14 (8/4/2)  |    2163  |      883  |     1984  |    2166  |    179
```

It performs well. In the first scenario, the script, parent connection, fastest child connection, and slowest child connection all finish in very short durations (i.e. less than 50ms). There is no latency on the parent, which is running no queries (each run is 0ms). The fastest child connection runs in 1ms max, and the slowest child connection runs in 27ms max when the contention is maxed out (8 processes with 4 threads each, so 32 contending child connections).

In the second scenario, where the parent process runs only one slow query so there is contention between the fast queries from the children connections and the slow query in the parent connection, the ideal case is that the gap between the duration for the parent connection and the script duration is minimal as well as that the gap between the fastest and slowest child connection is minimal. Finally, in the third scenario, where the parent connection is running two slow queries with a 1ms gap in between executions, the ideal case is that the gap between fastest and slowest child connections is minimal (tho it will be larger than previous scenarios, because the slowest child connection will be the one that has to wait for both slow parent queries to finish).

```
  jitter   |  6 (4/2/0)   |       0  |        0  |       22  |       2  |    -22
  jitter   |  7 (4/2/1)   |    1070  |      870  |      886  |    1072  |    184
  jitter   |  8 (4/2/2)   |    2154  |      876  |     1959  |    2156  |    195
  jitter   |  8 (4/4/0)   |       0  |        9  |       43  |       2  |    -43
  jitter   |  9 (4/4/1)   |    1068  |      875  |      936  |    1070  |    132
  jitter   |  10 (4/4/2)  |    2134  |      865  |     1968  |    2136  |    166
  jitter   |  10 (8/2/0)  |       0  |       10  |       42  |       3  |    -42
  jitter   |  11 (8/2/1)  |    1074  |      873  |      928  |    1077  |    146
  jitter   |  12 (8/2/2)  |    2192  |      880  |     1994  |    2195  |    198
  jitter   |  12 (8/4/0)  |       0  |        9  |      109  |       3  |   -109
  jitter   |  13 (8/4/1)  |    1076  |      878  |      974  |    1081  |    102
  jitter   |  14 (8/4/2)  |    2151  |      871  |     2009  |    2154  |    142
 ceiling   |  6 (4/2/0)   |       0  |        0  |       19  |       2  |    -19
 ceiling   |  7 (4/2/1)   |    1069  |      881  |      930  |    1071  |    139
 ceiling   |  8 (4/2/2)   |    2162  |      885  |     2032  |    2165  |    130
 ceiling   |  8 (4/4/0)   |       0  |        0  |       42  |       2  |    -42
 ceiling   |  9 (4/4/1)   |    1104  |      914  |      972  |    1105  |    132
 ceiling   |  10 (4/4/2)  |    2171  |     1981  |     2078  |    2173  |     93
 ceiling   |  10 (8/2/0)  |       0  |        0  |        7  |       3  |     -7
 ceiling   |  11 (8/2/1)  |    1089  |      889  |      972  |    1092  |    117
 ceiling   |  12 (8/2/2)  |    2182  |     1983  |     2036  |    2185  |    146
 ceiling   |  12 (8/4/0)  |       0  |        0  |       76  |       3  |    -76
 ceiling   |  13 (8/4/1)  |    1072  |      883  |     1012  |    1075  |     60
 ceiling   |  14 (8/4/2)  |    2146  |      870  |     2112  |    2150  |     34
 reversed  |  6 (4/2/0)   |       0  |        0  |       13  |       3  |    -13
 reversed  |  7 (4/2/1)   |    1071  |      870  |      874  |    1073  |    197
 reversed  |  8 (4/2/2)   |    2161  |      878  |      883  |    2163  |   1278
 reversed  |  8 (4/4/0)   |       0  |       12  |       47  |       2  |    -47
 reversed  |  9 (4/4/1)   |    1075  |      876  |      885  |    1077  |    190
 reversed  |  10 (4/4/2)  |    2184  |      886  |      895  |    2185  |   1289
 reversed  |  10 (8/2/0)  |       0  |        0  |       44  |       3  |    -44
 reversed  |  11 (8/2/1)  |    1095  |      894  |      911  |    1098  |    184
 reversed  |  12 (8/2/2)  |    2211  |      901  |      920  |    2213  |   1291
 reversed  |  12 (8/4/0)  |       0  |        0  |       81  |       3  |    -81
 reversed  |  13 (8/4/1)  |    1082  |      882  |      922  |    1085  |    160
 reversed  |  14 (8/4/2)  |    2172  |      878  |     1973  |    2174  |    199
```