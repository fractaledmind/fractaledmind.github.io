---
title: Enhancing your Rails app with SQLite
subtitle: Table Schema and Metadata
date: 2023-11-13
tags:
  - code
  - sqlite
  - ruby
  - rails
---

How can we get all of the information about a particular table in a SQLite database? The information is spread across several different sources, in various structures, and not so easy to collect into a single report. This post will show you how to get all of the information you need.

<!--/summary-->

There are 4 `PRAGMA` statements that we can use to get various pieces of information about a table:

* [`PRAGMA table_list`](https://www.sqlite.org/pragma.html#pragma_table_list) — This pragma returns information about the tables and views in the schema.
* [`PRAGMA table_xinfo`](https://www.sqlite.org/pragma.html#pragma_table_xinfo) — This pragma returns one row for each column in the named table, including generated columns and hidden columns.
* [`PRAGMA index_list`](https://www.sqlite.org/pragma.html#pragma_index_list) — This pragma returns one row for each index associated with the given table.
* [`PRAGMA foreign_key_list`](https://www.sqlite.org/pragma.html#pragma_foreign_key_list) — This pragma returns one row for each foreign key constraint of the named table.

We can also get the `CREATE TABLE` statement for a table by querying the `sqlite_schema` table.

Taken together, these 5 sources of information give us everything we need to know about a table. The problem is that we can't gather all of this information in a single query. We need to run 5 separate queries, and then combine the results.

Moreover, there is some information that can only be inferred from the `CREATE TABLE` statement. For example, to know whether a table's primary key is `AUTOINCREMENT`, we need to look at the `CREATE TABLE` statement. The `PRAGMA table_xinfo` statement doesn't tell us this.

So, I sat down to write a method that would gather all of this information and return a well-structured hash outlining the table's structure and metadata. For your Rails application, you can put this method in your `ApplicationRecord` class and then call it on any of your models to get the information you need:

```ruby
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.schema
    table_info = connection.execute("PRAGMA table_list(#{table_name});").first
    columns_info = connection.execute("PRAGMA table_xinfo(#{table_name});")
    index_info = connection.execute("PRAGMA index_list(#{table_name});")
    fk_info = connection.execute("PRAGMA foreign_key_list(#{table_name});")
    table_sql = connection.exec_query(<<~SQL, 'SQL', [table_name]).first
      SELECT sql
      FROM (
        SELECT * FROM main.sqlite_schema UNION ALL
        SELECT * FROM temp.sqlite_schema
      )
      WHERE type = 'table'
        AND name = ?;
    SQL
    column_names = columns_info.map { |column| column["name"] }

    collate_regex = /COLLATE\s+(\w+).*/i
    primary_key_autoincrement_regex = /PRIMARY KEY AUTOINCREMENT/i
    unquoted_open_parens_regex = /\((?![^'"]*['"][^'"]*$)/
    final_close_parens_regex = /\);*\z/
    column_separator_regex = /,(?=\s(?:CONSTRAINT|"(?:#{Regexp.union(column_names).source})"))/i

    column_defs = table_sql["sql"]
      .partition(unquoted_open_parens_regex)
      .last
      .sub(final_close_parens_regex, "")
      .split(column_separator_regex)
      .map do |definition|
        definition = definition.strip
        key = definition.partition(" ").first.gsub(/^"*|"*$/, "")
        [key, definition]
      end
      .to_h

    {
      schema: table_info["schema"],
      name: table_info["name"],
      sql: table_sql["sql"],
      without_rowid: table_info["wr"] == 1,
      strict: table_info["strict"] == 1,
      columns: columns_info.map do |column_info|
        column_string = column_defs[column_info["name"]]

        { name: column_info["name"],
          type: column_info["type"],
          sql: column_string,
          nullable: column_info["notnull"] == 0,
          default: column_info["dflt_value"],
          primary_key: column_info["pk"],
          kind: case column_info["hidden"]
                when 0 then :normal
                when 1 then :virtual
                when 2 then :dynamic
                when 3 then :stored
                end,
          collation: ($1 if collate_regex =~ column_string),
          autoincrement: column_string.match?(primary_key_autoincrement_regex) }
      end,
      indexes: index_info.map do |index_info|
        { name: index_info["name"],
          unique: index_info["unique"] == 1,
          origin: case index_info["origin"]
                  when "c" then :create_index
                  when "u" then :unique_constraint
                  when "pk" then :primary_key_constraint
                  end,
          partial: index_info["partial"] == 1 }
      end,
      foreign_keys: fk_info.map do |fk_info|
        { table: fk_info["table"],
          from: fk_info["from"],
          to: fk_info["to"],
          on_update: fk_info["on_update"],
          on_delete: fk_info["on_delete"],
          match: fk_info["match"] }
      end
    }
  end
end
```

- - -

What is nice about this method is that it returns a hash that is easy to work with. For a schema like this:

```sql
CREATE TABLE IF NOT EXISTS artists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE
);
CREATE TABLE IF NOT EXISTS albums (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT COLLATE NOCASE UNIQUE,
  release_date DATE,
  artist_id INTEGER,
  FOREIGN KEY(artist_id) REFERENCES artists(id)
);
CREATE TABLE IF NOT EXISTS songs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  album_id INTEGER,
  FOREIGN KEY(album_id) REFERENCES albums(id)
);
```

You would get this output for the `albums` table:

```ruby
{ schema: "main",
  name: "albums",
  sql: "CREATE TABLE albums (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT COLLATE NOCASE UNIQUE,
    release_date DATE,
    artist_id INTEGER,
    FOREIGN KEY(artist_id) REFERENCES artists(id)
  )",
  without_rowid: false,
  strict: false,
  columns: [
    { name: "id",
      type: "INTEGER",
      sql: "id INTEGER PRIMARY KEY AUTOINCREMENT",
      nullable: true,
      default: nil,
      primary_key: 1,
      kind: :normal,
      collation: nil,
      autoincrement: true },
    { name: "title",
      type: "TEXT",
      sql: "title TEXT COLLATE NOCASE UNIQUE",
      nullable: true,
      default: nil,
      primary_key: 0,
      kind: :normal,
      collation: "NOCASE",
      autoincrement: false },
    { name: "release_date",
      type: "DATE",
      sql: "release_date DATE",
      nullable: true,
      default: nil,
      primary_key: 0,
      kind: :normal,
      collation: nil,
      autoincrement: false },
    { name: "artist_id",
      type: "INTEGER",
      sql: "artist_id INTEGER",
      nullable: true,
      default: nil,
      primary_key: 0,
      kind: :normal,
      collation: nil,
      autoincrement: false }
  ],
  indexes: [
    { name: "sqlite_autoindex_albums_1",
      unique: true,
      origin: :unique_constraint,
      partial: false }
  ],
  foreign_keys: [
    { table: "artists",
      from: "artist_id",
      to: "id",
      on_update: "NO ACTION",
      on_delete: "NO ACTION",
      match: "NONE" }
  ]
}
```

Here you can see that we have every piece of information about the table, its columns, indexes, and foreign keys that SQLite knows about. This is a lot of information, but it is all useful. For example, if you wanted to know if a column was a primary key, you could do this:

```ruby
schema[:columns].any? { |column| !column[:primary_key].zero? }
```

The `schema` uses integers for the `primary_key` values because SQLite supports composite primary keys. So, if you tweaked the definition of the `songs` table like this:

```sql
CREATE TABLE IF NOT EXISTS songs (
  id INTEGER,
  title TEXT,
  album_id INTEGER,
  PRIMARY KEY(id, album_id),
  FOREIGN KEY(album_id) REFERENCES albums(id)
);
```

You would get a schema like this:

```ruby
{ schema: "main",
	name: "songs",
	sql: "CREATE TABLE songs (
    id INTEGER,
    title TEXT,
    album_id INTEGER,
    PRIMARY KEY(id, album_id),
    FOREIGN KEY(album_id) REFERENCES albums(id)
  )",
  without_rowid: false,
  strict: false,
  columns: [
    { name: "id",
      type: "INTEGER",
      sql: "id INTEGER",
      nullable: true,
      default: nil,
      primary_key: 1,
      kind: :normal,
      collation: nil,
      autoincrement: false },
    { name: "title",
      type: "TEXT",
      sql: "title TEXT",
      nullable: true,
      default: nil,
      primary_key: 0,
      kind: :normal,
      collation: nil,
      autoincrement: false },
    { name: "album_id",
      type: "INTEGER",
      sql: "album_id INTEGER",
      nullable: true,
      default: nil,
      primary_key: 2,
      kind: :normal,
      collation: nil,
      autoincrement: false }
  ],
  indexes: [
    { name: "sqlite_autoindex_songs_1",
      unique: true,
      origin: :primary_key_constraint,
      partial: false }
  ],
  foreign_keys: [
    { table: "albums",
      from: "album_id",
      to: "id",
      on_update: "NO ACTION",
      on_delete: "NO ACTION",
      match: "NONE" }
  ]
}
```

Here, you can see that the `id` and `album_id` columns are both part of the primary key, and the `primary_key` value for each column is the position of the column in the primary key. This is useful information if you want to know the order of the columns in a composite primary key.

- - -

There are many possible uses for the full set of metadata about a table in your SQLite database. For example, you could use it to generate a schema for another database, or to generate a migration to update the schema of another database. By having an intermediate representation of the schema, you can do whatever you want with it.

If you come up with some interesting uses, please reach out to me on Twitter <a href="http://twitter.com/fractaledmind?ref=fractaledmind.github.io">@fractaledmind</a>.

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
* [Part 9 — performance metrics]({% link _posts/2023-09-21-enhancing-rails-sqlite-performance-metrics.md %})
* [Part 10 — custom primary keys]({% link _posts/2023-09-22-enhancing-rails-sqlite-ulid-primary-keys.md %})
* [Part 11 — more Rails improvements]({% link _posts/2023-09-26-enhancing-rails-sqlite-more-activerecord-adapter-improvements.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Part 12 — table schema and metadata]({% link _posts/2023-11-13-enhancing-rails-sqlite-table-schema-and-metadata.md %})
* [Part 13 — prefixed ULID keys]({% link _posts/2023-12-13-enhancing-rails-sqlite-prefixed-ulids.md %})
* [Part 14 — installing extensions]({% link _posts/2023-12-24-enhancing-rails-installing-extensions.md %})
