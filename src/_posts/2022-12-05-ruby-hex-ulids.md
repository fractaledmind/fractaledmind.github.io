---
title: Generating Hex-ULIDs in Ruby
date: 2022-12-05
tags:
  - code
  - ruby
---

In [the previous post]({% link _posts/2022-12-04-sqlite-quasi-ulids.md %}), we explored how to generate a base16-encoded [<abbr title="Universally Unique Lexicographically Sortable Identifiers">ULIDs</abbr>](https://github.com/ulid/spec) with only native SQLite functions. In the end, we built an expression that will generate hex-ULIDs for us:

```sql
SELECT PRINTF('%012X', CAST(ROUND((JULIANDAY('now') - 2440587.5)*86400000) AS INTEGER)) | HEX(RANDOMBLOB(10)) AS qulid;
```

This expression will return a 32 character string like `0184E14B9D33DF0EA40E00D20FC31406`, which encodes a 48 bit timestamp and an 80 bit random portion, producing a 128 bit blob just like ULIDs and UUIDs. The string is composed of an 12 character base16-encoded timestamp and a 20 character random portion.

But what if we need to generate a hex-ULID in Ruby?

<!--/summary-->

### Ruby Hex-ULIDs

Let's convert our SQLite expression into a Ruby function.

```ruby
class HexULID
  def self.generate(moment: nil, entropy: nil)
    moment = (Time.now.to_r * 1000).to_i
    entropy = SecureRandom.random_bytes(10)

    hex_timestamp = sprintf('%012X', moment)
    hex_randomness = entropy.bytes.map { |byte| sprintf('%02X', byte) }.join
    hex_timestamp << hex_randomness
  end
end
```

This `HexULID` class will generate strings _in exactly the same format_ as our SQLite expression. This will allow us to generate our hex-ULIDs in either Ruby or SQLite, which will make schema migrations and various code patterns easier.

In the future, we will explore how to make a schema migration to make use of such hex-ULIDs in a new or existing Rails project.
