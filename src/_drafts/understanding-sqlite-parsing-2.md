---
series: Understanding SQLite
title: Parsing (part 2)
date: 2024-03-27
tags:
  - code
  - ruby
  - sqlite
  - c
---

I am starting a new series of posts digging into the [SQLite](https://www.sqlite.org/index.html) source code to gain a deep and clear understanding of how it functions. As a start, I am digging into how SQLite parses a SQL statement. To begin, I compiled the generated parser and read through the code comments to get a high-level sense of how the parser works.

<!--/summary-->

- - -

This document describes how SQLite tokenizes and parses a SQL statement. It is based on the SQLite 3.45.2 source code. The example SQL statement is:

```sql
INSERT INTO t1 (a) VALUES (1);
```

