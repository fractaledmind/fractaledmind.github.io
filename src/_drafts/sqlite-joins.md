---
title: "SQLite Joins"
date: 2024-12-28
tags:
  - code
  - ruby
  - sqlite
---

While [working](https://bsky.app/profile/fractaledmind.bsky.social/post/3le2su25a3r2b) [on](https://bsky.app/profile/fractaledmind.bsky.social/post/3le4p7xyy262c) [a](https://bsky.app/profile/fractaledmind.bsky.social/post/3le7hyyv4sb26) [project](https://bsky.app/profile/fractaledmind.bsky.social/post/3lecal2fmv222) [with](https://bsky.app/profile/fractaledmind.bsky.social/post/3lecvf45i3y2b) [SQLite in Ruby](https://bsky.app/profile/fractaledmind.bsky.social/post/3leer23zzge2b), I found myself needing to fully understand how SQLite handles joins. This is my <abbr title="Today I learned">TIL</abbr> on my findings, sourced from the [SQLite documentation](https://www.sqlite.org/lang_select.html#determination_of_input_data_from_clause_processing_).

<!--/summary-->

- - -

I love SQLite's [syntax diagrams](https://www.sqlite.org/syntaxdiagrams.html) for getting both a thorough and clear understanding of how SQLite's SQL dialect works. So, when I go to do a deep dive on a particular SQLite feature, I always start with the syntax diagrams. As the syntax diagram for the [simple `SELECT` case](https://www.sqlite.org/syntax/select-core.html) makes clear, you define joins in the `FROM` clause of a `SELECT` statement with a construct that SQLite calls a `join-clause`. Here is a plain text representation of the `join-clause` [syntax diagram](https://www.sqlite.org/syntax/join-clause.html):

{:.lh-tight}
```
◯─▶[ table-or-subquery ]┬─────────────────────────────▶────────────────────────────────────┬─▶◯
                        └┬─▶[ join-operator ]─▶[ table-or-subquery ]─▶[ join-constraint ]─┐┘
                         └────────────────────────────◀───────────────────────────────────┘
```

We see that it references three other constructs: `table-or-subquery`, `join-operator`, and `join-constraint`. I want reproduce the [syntax diagram](https://www.sqlite.org/syntax/table-or-subquery.html) for a `table-or-subquery` construct, as it is irrelevant to understanding SQLite joins. The `join-operator` construct is where the magic happens. It defines the grammar of the types of joins you are able to perform. The `join-constraint` construct is where you then define the conditions for the join. Here is the `join-operator` [syntax diagram](https://www.sqlite.org/syntax/join-operator.html):

{:.lh-tight}
```
◯─┬─────────────────────▶{ , }─────────────────────────────────┬─▶◯
  ├──────▶───────┬─▶─┬───────────────┬─▶───────────┬─▶{ JOIN }─┘
  ├─▶{ NATURAL }─┘   ├─▶{ LEFT }──┬─▶┴─▶{ OUTER }─▶┤
  │                  ├─▶{ RIGHT }─┤                │
  │                  ├─▶{ FULL }──┘                │
  │                  └─▶{ INNER }─────────────────▶┤
  └────────────────────▶{ CROSS }─────────────────▶┘
```

Following this flow chart, we can enumerate every possible join operator construction in SQLite:

1. a simple comma `,`
2. `JOIN`
3. `LEFT JOIN`
4. `LEFT OUTER JOIN`
5. `NATURAL JOIN`
6. `NATURAL LEFT JOIN`
7. `NATURAL LEFT OUTER JOIN`
8. `RIGHT JOIN`
9. `RIGHT OUTER JOIN`
10. `NATURAL RIGHT JOIN`
11. `NATURAL RIGHT OUTER JOIN`
12. `FULL JOIN`
13. `FULL OUTER JOIN`
14. `NATURAL FULL JOIN`
15. `NATURAL FULL OUTER JOIN`
16. `INNER JOIN`
17. `NATURAL INNER JOIN`
18. `CROSS JOIN`

That is a lot of join operators! Luckily, many of them are just aliases for each other. So, let's simplify the list by grouping functionally equivalent join operators together:

1. `INNER JOIN`s can be written additionally as simply `JOIN` or even just `,`
2. `LEFT JOIN`s can be written additionally as `LEFT OUTER JOIN`
3. `RIGHT JOIN`s can be written additionally as `RIGHT OUTER JOIN`
4. `FULL JOIN`s can be written additionally as `FULL OUTER JOIN`
5. `NATURAL` is a modifier that can be applied to any of the above join operators
6. `CROSS JOIN`

The first four cases are the most common types of joins you will encounter in practice, and are the classic joins that we know from the SQL join Venn diagrams. The `NATURAL` modifier is a shorthand for specifying that the join should be performed on columns with the same name in both tables. The `CROSS JOIN` is a special case where every row in the first table is joined with every row in the second table. This is a Cartesian product, and is not typically used in practice because it can lead to very large result sets.

However, it is worth noting here that without any specified constraints (an `ON` or `USING` clause), all join types produce the same result set - a full Cartesian product of the two tables. This is because the different join types determine what to do with rows that do or don't meet the constraint, but without a constraint, they all behave identically. And, for those who, like me, don't immediately know what a "Cartesian product" means in the context of relational data, [the SQLite docs](https://www.sqlite.org/lang_select.html#determination_of_input_data_from_clause_processing_) explain it as:

> The columns of the cartesian product dataset are, in order, all the columns of the left-hand dataset followed by all the columns of the right-hand dataset.

So, let's refresh ourselves on the set logic at the heart of these join types. The `INNER JOIN` is the default and most common type of join.

{:.lh-tight.text-center}
```
┌─────┬──┬─────┐
│     │██│     │
│  A  │██│  B  │
│     │██│     │
└─────┴──┴─────┘
INNER JOIN
```




{:.lh-tight.text-center}
```
┌─────┬──┬─────┐
│█████│██│     │
│██A██│██│  B  │
│█████│██│     │
└─────┴──┴─────┘
LEFT JOIN
```

{:.lh-tight.text-center}
```
┌─────┬──┬─────┐
│     │██│█████│
│  A  │██│██B██│
│     │██│█████│
└─────┴──┴─────┘
RIGHT JOIN
```

{:.lh-tight.text-center}
```
┌─────┬──┬─────┐
│█████│██│█████│
│██A██│██│██B██│
│█████│██│█████│
└─────┴──┴─────┘
FULL JOIN
```

{:.lh-tight.text-center}
```
┌─────┬──┬─────┐
│█████│  │     │
│██A██│  │  B  │
│█████│  │     │
└─────┴──┴─────┘
LEFT JOIN
EXCLUDING
```

{:.lh-tight.text-center}
```
┌─────┬──┬─────┐
│     │  │█████│
│  A  │  │██B██│
│     │  │█████│
└─────┴──┴─────┘
RIGHT JOIN
EXCLUDING
```

{:.lh-tight.text-center}
```
┌─────┬──┬─────┐
│█████│  │█████│
│██A██│  │██B██│
│█████│  │█████│
└─────┴──┴─────┘
FULL OUTER JOIN
EXCLUDING
```



https://www.sqlite.org/syntax/join-constraint.html