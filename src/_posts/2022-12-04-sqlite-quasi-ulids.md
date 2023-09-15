---
title: SQLite Hex-ULIDs
date: 2022-12-04
tags:
  - code
  - sqlite
---

Identifiers are an essential aspect of any database schema design. There are various approaches with their various pros and cons. There are likewise various database engines. Today, I want to explore generating universally unique, sortable identifiers in SQLite.

<!--/summary-->

### Unique Identifiers

When it comes to databases generating unique identifiers for records, there are two highly popular options:

1.  auto-incrementing integers
2.  UUIDs ([universally unique identifiers](https://en.wikipedia.org/wiki/Universally_unique_identifier))

They each have their pros and cons. Auto-incrementing integers are the simple, go-to default, but they have two key downsides. Firstly, they don't handle horizontal scaling. As you add more database servers, you will get conflicting identifiers within the same table. Secondly, they open up some security vulnerabilities when used in URLs. On the one hand, they expose some information about the number of records you have of that type in your system; on the other hand, they make it easy for users to poke your system trying to access other records than the records they have natural access to.

UUIDs address each of these weaknesses. The typical v4 UUID, for example, would need 2.71 quintillion UUIDs to be generated before there would be a 50% chance of a collision. And that number is so large that it require generating 1 billion UUIDs per second for nearly 85 years! So, you can have any computer generate a UUID and be confident that this UUID will indeed be "universally unique". Moreover, this extreme degree of randomness also makes gathering any information about the system at large completely impossible. Users can't guess another UUID nor does any UUID reveal any information about the number of records of that type in your system. However, UUIDs do have their own weaknesses. One of the biggest downsides to using UUIDs for primary keys in a database table is that it means you will get a random set of records when you query the table without an explicit sort. This can create issues when you have an application paginating records.

A common approach to address this drawback of UUIDs while keeping the benefits is to prefix a timestamp to a random number. The [ULID spec](https://github.com/ulid/spec) ("Universally Unique Lexicographically Sortable Identifier") describes a standard approach for generating a kind of UUID that retains sortability. ULIDs are 128-bit objects represented as base32-encoded 26-character strings. This makes ULIDs perfect for URLs and record sets that need to be sorted by default.

Unfortunately, SQLite doesn't come with native support for UUIDs or ULIDs, only auto-incrementing integers. So, what can we do? Well, we need to make use of native SQLite functionality to generate a timestamp-prefixed random identifier.

### Quasi-ULIDs

What we need is a "Quasi Universally Unique Lexicographically Sortable Identifier"; that is, we want something with the characteristics of both universal uniqueness and lexicographical sortability. It will not, however, conform to the ULID spec as we won't be able to base32-encode the number, nor will it be exactly 128 bits.

Let's start with the timestamp. We want millisecond precision and an integer, so let's generate an integer timestamp of the number of milliseconds since the Unix epoch. Alternatively, if we want, we could generate an integer timestamp of the number of milliseconds since some system-defined moment in time (like Y2K, for example).

The random portion is relatively simple. We just need to generate a sufficiently random object, whether that is an integer or a byte stream.

So, let's see what native SQLite functionality we can make use of to generate these segments.

### SQLite Functionality

Some quick googling reveals this tip from the [SQLite documentation](https://www.sqlite.org/lang_datefunc.html#examples):

```sql
-- Compute the time since the unix epoch in seconds with millisecond precision:
SELECT (julianday('now') - 2440587.5)*86400.0;
```

Executing this query and comparing with some Ruby shows that this query provides only second-level precision. Luckily, [this StackOverflow answer](https://stackoverflow.com/a/32789171/2884386) presents an approach that provide millisecond precision:

```sql
SELECT CAST((julianday('now') - 2440587.5)*86400000 AS INTEGER);
```

A comment on that StackOverflow answer suggests using the `ROUND` function to get more accuracy. So, we can use this query to get an accurate, millisecond-precise integer timestamp since the Unix epoch:

```sql
SELECT CAST(ROUND((JULIANDAY('now') - 2440587.5)*86400000) AS INTEGER);
```

Perfect. This is how we will generate our timestamps.

For the random portion, we can make use of the [`RANDOMBLOB`](https://www.sqlite.org/lang_corefunc.html#randomblob) function to get a random byte stream.

Now, the question becomes, how do we merge our timestamp integer and our random byte stream to get a QULID?

ULIDs use base32-encoding, but SQLite doesn't have any native mechanism to base32-encode objects. It does, however, provide mechanisms for base16-encoding objects with [the `HEX` function](https://www.sqlite.org/lang_corefunc.html#hex) and [the `FORMAT`/`PRINTF` function](https://www.sqlite.org/printf.html).

The SQLite docs on the `RANDOMBLOB` function even add that "applications can generate globally unique identifiers using this function together with hex()" with `hex(randomblob(16))`.

We can't use the `HEX` function for the timestamp integer, as that function takes `BLOB`s, not `INTEGER`s. Luckily, SQLite also provides the `PRINTF` function, which can format an integer as a hex string with the `%x` or `%X` substitution types. So, let's pass our expression to generate our millisecond integer into `FORMAT`:

```sql
FORMAT('%X', CAST(ROUND((JULIANDAY('now') - 2440587.5)*86400000) AS INTEGER));
```

We use the `%X` substitution type to get uppercase letters, since the `HEX` function returns uppercase letters.

Because we are encoding both the timestamp integer and the byte stream as base16 strings, we can actually drop the `INTEGER` casting for the timestamp. We can simply format the rounded timestamp. We can also use `%012X`, as [Ben Johnson pointed out on Twitter](https://twitter.com/benbjohnson/status/1599579767959085056?s=20&t=kJuiqMvEQOpAZAZj_ccfSg), which would pad the timestamp to 12 hex characters, or 6 bytes/48 bits to match the ULID spec.

With both segments encoded as base16 strings, we can simply concatenate them together to generate our QULID:

```sql
SELECT PRINTF('%012X', ROUND((JULIANDAY('now') - 2440587.5)*86400000) ) | HEX(RANDOMBLOB(10)) AS qulid;
```

This expression will return a 32 character string like `0184E14B9D33DF0EA40E00D20FC31406`, which encodes a 48 bit timestamp and an 80 bit random portion, producing a 128 bit blob just like ULIDs and UUIDs. The string is composed of an 12 character base16-encoded timestamp and a 20 character random portion.

Having the same bit-structure as ULID is thanks to some wonderful improvements suggested by [Ben Johnson](https://twitter.com/benbjohnson). My original `%X` option produced an 11 characters hex string, which is 41 bits. Once our timestamp has the same number of bits as the ULID spec, it makes sense for the random portion to have the same number of bits as well, so Ben also [recommended](https://twitter.com/benbjohnson/status/1599580101532057600?s=20&t=kJuiqMvEQOpAZAZj_ccfSg) to use `RANDOMBLOB(10)` to generate 80 bits of randomness. I was originally using `RANDOMBLOB(8)`, which helped produce a hex string result that was closer in length to the ULID string. However, I agree with Ben that matching the underlying bit structure of the ULID spec is more reasonable than trying the match the string size.

It is worth noting, as [Brandur Leach pointed out](https://twitter.com/brandur/status/1599602789965262849?s=20&t=kJuiqMvEQOpAZAZj_ccfSg), that using base16 hex strings instead of the ULID spec's base32-encoding means that we are losing some range in our random component, which means this implementation has many fewer ULIDs per millisecond. So, if you are working on something at a truly planet scale, this will likely make less sense than using an extension to Postgres or MySQL. However, for the vast majority of web applications, the randomness portion should be entirely sufficient for "universally unique" identifiers.

### Conclusion

So, while we can't natively get UUIDs or ULIDs in a SQLite database, with a bit of ingenuity we can natively generate universally unique, lexicographically sortable identifiers. Using this expression as the default for a primary key column on a table will produce URL-friendly identifiers that don't expose any information about your system, but retain table sort behavior. I for one am happy with this result.
