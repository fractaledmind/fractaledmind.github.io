---
series: Understanding SQLite
title: Parsing (part 1)
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

I want to understand how SQLite works at a deep level. There are various reasons why. One reason is that I want to build tools on top of SQLite that require a deep understanding of how it works. Another reason is that I want to learn from the SQLite codebase and apply the knowledge to other projects. But, fundamentally, I am just plain curious and want to follow that curiousity as far as it will take me.

While SQLite does provide a number of tools to introspect the structure database, like the [`table_list` pragma](https://www.sqlite.org/pragma.html#pragma_table_list) and [`table_xinfo` pragma](https://www.sqlite.org/pragma.html#pragma_table_xinfo), they do not provide a _complete_ picture of your schema. The [`sqlite_master` table](https://www.sqlite.org/schematab.html) does provide the full `CREATE TABLE` statements for each table, but you need to parse that SQL to get a complete picture of the schema. So, in order to programmatically introspect a database schema, I need to be able to parse SQLite SQL.

Unfortunately, SQLite's parser is not publicly exposed and does not produce an intermediary syntax tree. So, if I want to parse SQLite SQL, I will need to write my own parser. But, that parser will need to exactly match SQLite's parser in order to be able to parse the SQL that SQLite itself parses. So, I need to understand how SQLite's parser works. Thus, this series.

- - -

So, in order to start, I needed to actually see SQLite's parser. Unfortunately, it isn't as easy as viewing their [source online](https://sqlite.org/src/doc/trunk/README.md) as the parser is a generated file. So, I cloned the repository locally using the [GitHub mirror](https://sqlite.org/src/doc/trunk/README.md) and generated the files manually. I did all of this on an M1 Mac running macOS 12.5.1. At the time of this writing, the most recent version of SQLite is 3.45.2, so that is the version I worked with as well.

```sh
git clone git@github.com:sqlite/sqlite.git
cd sqlite
git checkout version-3.45.2
./configure
make .target_source
```

This generated a number of files at the root level of the SQLite repository, one of which is the `parse.c` file that we want. The first thing that jumped out at me where the large comment blocks at each of the major sections of the parser. I figured this is the best place to get an initial sense of how the parser works.

From these comments, we can tell that SQLite implements a ["shift-reduce parser"](https://en.wikipedia.org/wiki/Shift-reduce_parser). So, it works linearly, token by token, along with a stack to keep track of the current state. As described earlier, this means that the SQLite parser doesn't generate an intermediary AST, but instead directly executes the SQL commands as it parses them; tokenization, parsing, and execution are all intermixed into a single operation.

When first reading the comments, a few terms jumped out as central: "terminal symbol", "non-terminal symbol", and "lookahead token". Studying the source code and comments more deeply, it became clear that "terminal symbols" are the actual tokens that the parser reads from the input, while non-terminal symbols are the higher-order grammar rules. We can see the full list of both terminal and non-terminal symbols in the `yyTokenName` array. And, as we see from the `YYNTOKEN` value, there are 185 terminal symbols followed by 134 non-terminal symbols. The "lookahead token" is then simply the current token that the parser is processing from the token stream.

The section explaining the control flow logic for the shift-reduce parser I personally find quite hard to follow. So, I dug in and traced the code path for a simple `CREATE TABLE` statement.

- - -

In order to better trace the execution of SQLite's parser, a new Rails application was created which compiles SQLite with the `SQLITE_DEBUG` flag enabled. The following steps were taken:

```bash
rails new sandbox && cd sandbox
bundle config set build.sqlite3 "--with-sqlite-cflags='-DSQLITE_DEBUG=1'"
# updated Gemfile to `gem "sqlite3", "~> 1.6", force_ruby_platform: true`
bundle install
```

With the `SQLITE_DEBUG` flag enabled, it is possible to enable the `parser_trace` PRAGMA in SQLite. This PRAGMA will print out the state of the parser as it tokenizes and parses the SQL statement.

For whatever reason, the `bin/rails dbconsole` command does not open up a `sqlite3` shell compiled SQLite binary, so, instead, we must use the `bin/rails console` command and run code through the `SQLite3::Database` class:

```ruby
db = ActiveRecord::Base.connection.raw_connection
db.execute 'pragma parser_trace = true;'
```

At this point, we executed our traced SQL statement:

```ruby
db.execute 'CREATE TABLE t1 (a);'
```

This output a number of lines of debug information (cleaned up and simplified to digest easier):

```
[[[CREATE TABLE t1 (a);]]]

Input 'CREATE' in state 0
Shift 'CREATE', pending reduce 14
Return. Stack=[CREATE]

Input 'TABLE' with pending reduce 14
Reduce 14 [createkw ::= CREATE], pop back to state 0.
... then shift 'createkw', go to state 153
Reduce 18 [temp ::=].
... then shift 'temp', go to state 416
Shift 'TABLE', go to state 357
Return. Stack=[createkw temp TABLE]

Input 'ID' in state 357
Reduce 15 [ifnotexists ::=].
... then shift 'ifnotexists', go to state 253
Shift 'ID', pending reduce 359
Return. Stack=[createkw temp TABLE ifnotexists ID]

Input 'LP' with pending reduce 359
Reduce 359 [nm ::= ID|INDEXED|JOIN_KW] without external action, pop back to state 253.
... then shift 'nm', go to state 356
Reduce 116 [dbnm ::=].
... then shift 'dbnm', pending reduce 13
Reduce 13 [create_table ::= createkw temp TABLE ifnotexists nm dbnm], pop back to state 0.
... then shift 'create_table', go to state 320
Shift 'LP', go to state 159
Return. Stack=[create_table LP]

Input 'ID' in state 159
Shift 'ID', pending reduce 359
Return. Stack=[create_table LP ID]

Input 'RP' with pending reduce 359
Reduce 359 [nm ::= ID|INDEXED|JOIN_KW] without external action, pop back to state 159.
... then shift 'nm', go to state 212
Reduce 26 [typetoken ::=].
... then shift 'typetoken', pending reduce 25
Reduce 25 [columnname ::= nm typetoken], pop back to state 159.
... then shift 'columnname', go to state 405
Reduce 366 [carglist ::=] without external action.
... then shift 'carglist', go to state 171
Reduce 358 [columnlist ::= columnname carglist] without external action, pop back to state 159.
... then shift 'columnlist', go to state 391
Reduce 65 [conslist_opt ::=].
... then shift 'conslist_opt', go to state 579
Shift 'RP', go to state 151
Return. Stack=[create_table LP columnlist conslist_opt RP]

Input 'SEMI' in state 151
Reduce 21 [table_option_set ::=].
... then shift 'table_option_set', go to state 578
Reduce 19 [create_table_args ::= LP columnlist conslist_opt RP table_option_set], pop back to state 320.
... then shift 'create_table_args', pending reduce 355
Reduce 355 [cmd ::= create_table create_table_args] without external action, pop back to state 0.
... then shift 'cmd', pending reduce 2
Reduce 2 [cmdx ::= cmd], pop back to state 0.
... then shift 'cmdx', go to state 582
Shift 'SEMI', pending reduce 348
Return. Stack=[cmdx SEMI]

Popping SEMI
Popping cmdx
```

In what follows, we will attempt to explain the output of the parser trace by connecting each trace line to the SQLite source code. In the end, our goal is to understand how SQLite tokenizes and parses SQL statements.

## Tokenization

The first line in the trace output is:

```
[[[CREATE TABLE t1 (a);]]]
```

This line is printed by the `sqlite3RunParser` function defined in the `src/tokenize.c` file, at line 591 in the `version-3.45.2` tag (`becd92a508adb4701029af87ff947a099ea54337`).

The `sqlite3RunParser` function will be our entrypoint. It is called by the `sqlite3_prepare` function, which is the public API for preparing an SQL statement for execution. We don't need to go that far back in the execution stack though.

The `sqlite3RunParser` function has the following signature:

```c
int sqlite3RunParser(Parse*, const char*);
```

The first parameter is a pointer to a `Parse` struct instance, which is basically the instance object for the parser that will do the parsing. The second parameter is the SQL statement to be parsed.

In the function definition, those parameters are named `pParse` and `zSql`, respectively:

```c
int sqlite3RunParser(Parse *pParse, const char *zSql)
```

The line that logs our input SQL statement simply prints the `zSql` parameter:

```c
printf("parser: [[[%s]]]\n", zSql);
```

There is a good bit of code that sets everything, but the heart of the tokenization process can be found in a loop in this function:

```c
while( 1 ){
  n = sqlite3GetToken((u8*)zSql, &tokenType);
  pParse->sLastToken.z = zSql;
  pParse->sLastToken.n = n;
  sqlite3Parser(pEngine, tokenType, pParse->sLastToken);
  lastTokenParsed = tokenType;
  zSql += n;
}
```

I am omitting some details here, but the main idea is that the `sqlite3GetToken` function is called to get the next token from the input SQL statement. The token is then passed to the `sqlite3Parser` function, which is the parser itself. There are a few details here to note, so let's break it down.

Firstly, the `sqlite3GetToken` function takes the input SQL statement and a pointer to a variable that will hold the token type. It will return an integer representing the length (in bytes) of the token at the start of the input SQL statement. The `sqlite3GetToken` function itself is defined in the `src/tokenize.c` file, at line 273 in the `version-3.45.2` tag.

The `sqlite3GetToken` method does not mutate the `zSql` object, but that object is mutated at the end of this loop by moving the pointer forward by `n` bytes to consume the token that was just parsed. Thus, when the loop runs again, the `zSql` pointer will start with the next token in the input SQL statement.

Before this is done, though, the current state of `zSql` and the `n` integer are stored in the `pParse->sLastToken` struct instance. The `sLastToken` struct has two fields: `z` and `n`, which are the pointer to the string starting with the "last token" and the length of the token, respectively.

So, in all, the `sqlite3RunParser` function recieves three pieces of information:

1. the current token type,
2. the length of the current token, and
3. the subset of the input SQL statement that starts with the current token.

It uses this, and some internal state that it keeps track of, to parse the input SQL statement, token by token.

I would love to do a deeper dive on the implementation details of the `sqlite3GetToken` method, but I think that would be a bit too much for this post. I have, however, rewritten that method in pure Ruby, and you can use that to better understand how it works. You can find it [here](https://github.com/fractaledmind/feather/blob/main/lib/feather/lexer.rb) in my [`feather` project](https://github.com/fractaledmind/feather), which is a growing collection of tools for working with SQLite in Ruby.

The short version is, it inspects the first byte of the input string and has a large `switch` statement that matches the byte to different code paths. Each code path has logic for trying to consume as many bytes as possible to form a token. The length that can be consumed is returned and the type of the token that can be parsed is stored in the `tokenType` pointer.

But, let's turn our attention to the parser.

## Parsing

The next line in the trace output is:

```
Input 'CREATE' in state 0
```

This line is printed by the `sqlite3Parser` function, which is unfortunately not available in the SQLite source. The `sqlite3Parser` function is a function generated in the `parse.c` file, which is created from the grammar defined in the `src/parse.y` file. If you would like to view the file in its entirety, I have put it in a Gist [here](https://gist.github.com/fractaledmind/5fba4adf59b1bbfd927ab83aa6bf0bf9). In what follows, I will be referencing this `parse.c` file and specific lines, functions, and structs within it. If you want to follow along closely, I recommend you open the Gist in another tab.

Ok, back to the `sqlite3Parser` function. This function starts at line 5816 in the `parse.c` file. The function signature is:

```c
void sqlite3Parser(
  void *yyp,                   /* The parser */
  int yymajor,                 /* The major token code number */
  sqlite3ParserTOKENTYPE yyminor       /* The value for the token */
  sqlite3ParserARG_PDECL               /* Optional %extra_argument parameter */
)
```

So, `yyp` maps to `pEngine` in the `sqlite3RunParser` function, `yymajor` maps to `tokenType`, and `yyminor` maps to `pParse->sLastToken`. Our trace output is generated at lines 5843-44:

```c
fprintf(yyTraceFILE,"%sInput '%s' in state %d\n",
        yyTracePrompt,yyTokenName[yymajor],yyact);
```

We can ignore `yyTraceFILE` and `yyTracePrompt`, as these are just used for logging. The interesting details are `yyTokenName[yymajor]` and `yyact`. Let's dig into both.

The `yyTokenName` array is defined at line 1503 in the `parse.c` file and stores the names of each and every token and grammar rule in the SQLite grammar. So, the `yymajor`/`tokenType` integer is used as an index into this array to get the name of the token that was just parsed. This name is then printed to the console. Let's look at the `yyTokenName` array defined at line 1503 in the `parse.c` file:

<details markdown="1">
  <summary>Breakdown by benchmark operation</summary>
    <code>yyTokenName</code> array
  </summary>

```c
static const char *const yyTokenName[] = {
  /*    0 */ "$",
  /*    1 */ "SEMI",
  /*    2 */ "EXPLAIN",
  /*    3 */ "QUERY",
  /*    4 */ "PLAN",
  /*    5 */ "BEGIN",
  /*    6 */ "TRANSACTION",
  /*    7 */ "DEFERRED",
  /*    8 */ "IMMEDIATE",
  /*    9 */ "EXCLUSIVE",
  /*   10 */ "COMMIT",
  /*   11 */ "END",
  /*   12 */ "ROLLBACK",
  /*   13 */ "SAVEPOINT",
  /*   14 */ "RELEASE",
  /*   15 */ "TO",
  /*   16 */ "TABLE",
  /*   17 */ "CREATE",
  /*   18 */ "IF",
  /*   19 */ "NOT",
  /*   20 */ "EXISTS",
  /*   21 */ "TEMP",
  /*   22 */ "LP",
  /*   23 */ "RP",
  /*   24 */ "AS",
  /*   25 */ "COMMA",
  /*   26 */ "WITHOUT",
  /*   27 */ "ABORT",
  /*   28 */ "ACTION",
  /*   29 */ "AFTER",
  /*   30 */ "ANALYZE",
  /*   31 */ "ASC",
  /*   32 */ "ATTACH",
  /*   33 */ "BEFORE",
  /*   34 */ "BY",
  /*   35 */ "CASCADE",
  /*   36 */ "CAST",
  /*   37 */ "CONFLICT",
  /*   38 */ "DATABASE",
  /*   39 */ "DESC",
  /*   40 */ "DETACH",
  /*   41 */ "EACH",
  /*   42 */ "FAIL",
  /*   43 */ "OR",
  /*   44 */ "AND",
  /*   45 */ "IS",
  /*   46 */ "MATCH",
  /*   47 */ "LIKE_KW",
  /*   48 */ "BETWEEN",
  /*   49 */ "IN",
  /*   50 */ "ISNULL",
  /*   51 */ "NOTNULL",
  /*   52 */ "NE",
  /*   53 */ "EQ",
  /*   54 */ "GT",
  /*   55 */ "LE",
  /*   56 */ "LT",
  /*   57 */ "GE",
  /*   58 */ "ESCAPE",
  /*   59 */ "ID",
  /*   60 */ "COLUMNKW",
  /*   61 */ "DO",
  /*   62 */ "FOR",
  /*   63 */ "IGNORE",
  /*   64 */ "INITIALLY",
  /*   65 */ "INSTEAD",
  /*   66 */ "NO",
  /*   67 */ "KEY",
  /*   68 */ "OF",
  /*   69 */ "OFFSET",
  /*   70 */ "PRAGMA",
  /*   71 */ "RAISE",
  /*   72 */ "RECURSIVE",
  /*   73 */ "REPLACE",
  /*   74 */ "RESTRICT",
  /*   75 */ "ROW",
  /*   76 */ "ROWS",
  /*   77 */ "TRIGGER",
  /*   78 */ "VACUUM",
  /*   79 */ "VIEW",
  /*   80 */ "VIRTUAL",
  /*   81 */ "WITH",
  /*   82 */ "NULLS",
  /*   83 */ "FIRST",
  /*   84 */ "LAST",
  /*   85 */ "CURRENT",
  /*   86 */ "FOLLOWING",
  /*   87 */ "PARTITION",
  /*   88 */ "PRECEDING",
  /*   89 */ "RANGE",
  /*   90 */ "UNBOUNDED",
  /*   91 */ "EXCLUDE",
  /*   92 */ "GROUPS",
  /*   93 */ "OTHERS",
  /*   94 */ "TIES",
  /*   95 */ "GENERATED",
  /*   96 */ "ALWAYS",
  /*   97 */ "MATERIALIZED",
  /*   98 */ "REINDEX",
  /*   99 */ "RENAME",
  /*  100 */ "CTIME_KW",
  /*  101 */ "ANY",
  /*  102 */ "BITAND",
  /*  103 */ "BITOR",
  /*  104 */ "LSHIFT",
  /*  105 */ "RSHIFT",
  /*  106 */ "PLUS",
  /*  107 */ "MINUS",
  /*  108 */ "STAR",
  /*  109 */ "SLASH",
  /*  110 */ "REM",
  /*  111 */ "CONCAT",
  /*  112 */ "PTR",
  /*  113 */ "COLLATE",
  /*  114 */ "BITNOT",
  /*  115 */ "ON",
  /*  116 */ "INDEXED",
  /*  117 */ "STRING",
  /*  118 */ "JOIN_KW",
  /*  119 */ "CONSTRAINT",
  /*  120 */ "DEFAULT",
  /*  121 */ "NULL",
  /*  122 */ "PRIMARY",
  /*  123 */ "UNIQUE",
  /*  124 */ "CHECK",
  /*  125 */ "REFERENCES",
  /*  126 */ "AUTOINCR",
  /*  127 */ "INSERT",
  /*  128 */ "DELETE",
  /*  129 */ "UPDATE",
  /*  130 */ "SET",
  /*  131 */ "DEFERRABLE",
  /*  132 */ "FOREIGN",
  /*  133 */ "DROP",
  /*  134 */ "UNION",
  /*  135 */ "ALL",
  /*  136 */ "EXCEPT",
  /*  137 */ "INTERSECT",
  /*  138 */ "SELECT",
  /*  139 */ "VALUES",
  /*  140 */ "DISTINCT",
  /*  141 */ "DOT",
  /*  142 */ "FROM",
  /*  143 */ "JOIN",
  /*  144 */ "USING",
  /*  145 */ "ORDER",
  /*  146 */ "GROUP",
  /*  147 */ "HAVING",
  /*  148 */ "LIMIT",
  /*  149 */ "WHERE",
  /*  150 */ "RETURNING",
  /*  151 */ "INTO",
  /*  152 */ "NOTHING",
  /*  153 */ "FLOAT",
  /*  154 */ "BLOB",
  /*  155 */ "INTEGER",
  /*  156 */ "VARIABLE",
  /*  157 */ "CASE",
  /*  158 */ "WHEN",
  /*  159 */ "THEN",
  /*  160 */ "ELSE",
  /*  161 */ "INDEX",
  /*  162 */ "ALTER",
  /*  163 */ "ADD",
  /*  164 */ "WINDOW",
  /*  165 */ "OVER",
  /*  166 */ "FILTER",
  /*  167 */ "COLUMN",
  /*  168 */ "AGG_FUNCTION",
  /*  169 */ "AGG_COLUMN",
  /*  170 */ "TRUEFALSE",
  /*  171 */ "ISNOT",
  /*  172 */ "FUNCTION",
  /*  173 */ "UMINUS",
  /*  174 */ "UPLUS",
  /*  175 */ "TRUTH",
  /*  176 */ "REGISTER",
  /*  177 */ "VECTOR",
  /*  178 */ "SELECT_COLUMN",
  /*  179 */ "IF_NULL_ROW",
  /*  180 */ "ASTERISK",
  /*  181 */ "SPAN",
  /*  182 */ "ERROR",
  /*  183 */ "SPACE",
  /*  184 */ "ILLEGAL",
  /*  185 */ "input",
  /*  186 */ "cmdlist",
  /*  187 */ "ecmd",
  /*  188 */ "cmdx",
  /*  189 */ "explain",
  /*  190 */ "cmd",
  /*  191 */ "transtype",
  /*  192 */ "trans_opt",
  /*  193 */ "nm",
  /*  194 */ "savepoint_opt",
  /*  195 */ "create_table",
  /*  196 */ "create_table_args",
  /*  197 */ "createkw",
  /*  198 */ "temp",
  /*  199 */ "ifnotexists",
  /*  200 */ "dbnm",
  /*  201 */ "columnlist",
  /*  202 */ "conslist_opt",
  /*  203 */ "table_option_set",
  /*  204 */ "select",
  /*  205 */ "table_option",
  /*  206 */ "columnname",
  /*  207 */ "carglist",
  /*  208 */ "typetoken",
  /*  209 */ "typename",
  /*  210 */ "signed",
  /*  211 */ "plus_num",
  /*  212 */ "minus_num",
  /*  213 */ "scanpt",
  /*  214 */ "scantok",
  /*  215 */ "ccons",
  /*  216 */ "term",
  /*  217 */ "expr",
  /*  218 */ "onconf",
  /*  219 */ "sortorder",
  /*  220 */ "autoinc",
  /*  221 */ "eidlist_opt",
  /*  222 */ "refargs",
  /*  223 */ "defer_subclause",
  /*  224 */ "generated",
  /*  225 */ "refarg",
  /*  226 */ "refact",
  /*  227 */ "init_deferred_pred_opt",
  /*  228 */ "conslist",
  /*  229 */ "tconscomma",
  /*  230 */ "tcons",
  /*  231 */ "sortlist",
  /*  232 */ "eidlist",
  /*  233 */ "defer_subclause_opt",
  /*  234 */ "orconf",
  /*  235 */ "resolvetype",
  /*  236 */ "raisetype",
  /*  237 */ "ifexists",
  /*  238 */ "fullname",
  /*  239 */ "selectnowith",
  /*  240 */ "oneselect",
  /*  241 */ "wqlist",
  /*  242 */ "multiselect_op",
  /*  243 */ "distinct",
  /*  244 */ "selcollist",
  /*  245 */ "from",
  /*  246 */ "where_opt",
  /*  247 */ "groupby_opt",
  /*  248 */ "having_opt",
  /*  249 */ "orderby_opt",
  /*  250 */ "limit_opt",
  /*  251 */ "window_clause",
  /*  252 */ "values",
  /*  253 */ "nexprlist",
  /*  254 */ "sclp",
  /*  255 */ "as",
  /*  256 */ "seltablist",
  /*  257 */ "stl_prefix",
  /*  258 */ "joinop",
  /*  259 */ "on_using",
  /*  260 */ "indexed_by",
  /*  261 */ "exprlist",
  /*  262 */ "xfullname",
  /*  263 */ "idlist",
  /*  264 */ "indexed_opt",
  /*  265 */ "nulls",
  /*  266 */ "with",
  /*  267 */ "where_opt_ret",
  /*  268 */ "setlist",
  /*  269 */ "insert_cmd",
  /*  270 */ "idlist_opt",
  /*  271 */ "upsert",
  /*  272 */ "returning",
  /*  273 */ "filter_over",
  /*  274 */ "likeop",
  /*  275 */ "between_op",
  /*  276 */ "in_op",
  /*  277 */ "paren_exprlist",
  /*  278 */ "case_operand",
  /*  279 */ "case_exprlist",
  /*  280 */ "case_else",
  /*  281 */ "uniqueflag",
  /*  282 */ "collate",
  /*  283 */ "vinto",
  /*  284 */ "nmnum",
  /*  285 */ "trigger_decl",
  /*  286 */ "trigger_cmd_list",
  /*  287 */ "trigger_time",
  /*  288 */ "trigger_event",
  /*  289 */ "foreach_clause",
  /*  290 */ "when_clause",
  /*  291 */ "trigger_cmd",
  /*  292 */ "trnm",
  /*  293 */ "tridxby",
  /*  294 */ "database_kw_opt",
  /*  295 */ "key_opt",
  /*  296 */ "add_column_fullname",
  /*  297 */ "kwcolumn_opt",
  /*  298 */ "create_vtab",
  /*  299 */ "vtabarglist",
  /*  300 */ "vtabarg",
  /*  301 */ "vtabargtoken",
  /*  302 */ "lp",
  /*  303 */ "anylist",
  /*  304 */ "wqitem",
  /*  305 */ "wqas",
  /*  306 */ "windowdefn_list",
  /*  307 */ "windowdefn",
  /*  308 */ "window",
  /*  309 */ "frame_opt",
  /*  310 */ "part_opt",
  /*  311 */ "filter_clause",
  /*  312 */ "over_clause",
  /*  313 */ "range_or_rows",
  /*  314 */ "frame_bound",
  /*  315 */ "frame_bound_s",
  /*  316 */ "frame_bound_e",
  /*  317 */ "frame_exclude_opt",
  /*  318 */ "frame_exclude",
};
```
</details>

The index for `"CREATE"` (*17*) matches the integer value assigned to the `TK_CREATE` token constant at the top of the `parse.c` file (line 238):

<details markdown="1">
  <summary>Breakdown by benchmark operation</summary>
    Token constants
  </summary>

```c
#define TK_SEMI                            1
#define TK_EXPLAIN                         2
#define TK_QUERY                           3
#define TK_PLAN                            4
#define TK_BEGIN                           5
#define TK_TRANSACTION                     6
#define TK_DEFERRED                        7
#define TK_IMMEDIATE                       8
#define TK_EXCLUSIVE                       9
#define TK_COMMIT                         10
#define TK_END                            11
#define TK_ROLLBACK                       12
#define TK_SAVEPOINT                      13
#define TK_RELEASE                        14
#define TK_TO                             15
#define TK_TABLE                          16
#define TK_CREATE                         17
#define TK_IF                             18
#define TK_NOT                            19
#define TK_EXISTS                         20
#define TK_TEMP                           21
#define TK_LP                             22
#define TK_RP                             23
#define TK_AS                             24
#define TK_COMMA                          25
#define TK_WITHOUT                        26
#define TK_ABORT                          27
#define TK_ACTION                         28
#define TK_AFTER                          29
#define TK_ANALYZE                        30
#define TK_ASC                            31
#define TK_ATTACH                         32
#define TK_BEFORE                         33
#define TK_BY                             34
#define TK_CASCADE                        35
#define TK_CAST                           36
#define TK_CONFLICT                       37
#define TK_DATABASE                       38
#define TK_DESC                           39
#define TK_DETACH                         40
#define TK_EACH                           41
#define TK_FAIL                           42
#define TK_OR                             43
#define TK_AND                            44
#define TK_IS                             45
#define TK_MATCH                          46
#define TK_LIKE_KW                        47
#define TK_BETWEEN                        48
#define TK_IN                             49
#define TK_ISNULL                         50
#define TK_NOTNULL                        51
#define TK_NE                             52
#define TK_EQ                             53
#define TK_GT                             54
#define TK_LE                             55
#define TK_LT                             56
#define TK_GE                             57
#define TK_ESCAPE                         58
#define TK_ID                             59
#define TK_COLUMNKW                       60
#define TK_DO                             61
#define TK_FOR                            62
#define TK_IGNORE                         63
#define TK_INITIALLY                      64
#define TK_INSTEAD                        65
#define TK_NO                             66
#define TK_KEY                            67
#define TK_OF                             68
#define TK_OFFSET                         69
#define TK_PRAGMA                         70
#define TK_RAISE                          71
#define TK_RECURSIVE                      72
#define TK_REPLACE                        73
#define TK_RESTRICT                       74
#define TK_ROW                            75
#define TK_ROWS                           76
#define TK_TRIGGER                        77
#define TK_VACUUM                         78
#define TK_VIEW                           79
#define TK_VIRTUAL                        80
#define TK_WITH                           81
#define TK_NULLS                          82
#define TK_FIRST                          83
#define TK_LAST                           84
#define TK_CURRENT                        85
#define TK_FOLLOWING                      86
#define TK_PARTITION                      87
#define TK_PRECEDING                      88
#define TK_RANGE                          89
#define TK_UNBOUNDED                      90
#define TK_EXCLUDE                        91
#define TK_GROUPS                         92
#define TK_OTHERS                         93
#define TK_TIES                           94
#define TK_GENERATED                      95
#define TK_ALWAYS                         96
#define TK_MATERIALIZED                   97
#define TK_REINDEX                        98
#define TK_RENAME                         99
#define TK_CTIME_KW                       100
#define TK_ANY                            101
#define TK_BITAND                         102
#define TK_BITOR                          103
#define TK_LSHIFT                         104
#define TK_RSHIFT                         105
#define TK_PLUS                           106
#define TK_MINUS                          107
#define TK_STAR                           108
#define TK_SLASH                          109
#define TK_REM                            110
#define TK_CONCAT                         111
#define TK_PTR                            112
#define TK_COLLATE                        113
#define TK_BITNOT                         114
#define TK_ON                             115
#define TK_INDEXED                        116
#define TK_STRING                         117
#define TK_JOIN_KW                        118
#define TK_CONSTRAINT                     119
#define TK_DEFAULT                        120
#define TK_NULL                           121
#define TK_PRIMARY                        122
#define TK_UNIQUE                         123
#define TK_CHECK                          124
#define TK_REFERENCES                     125
#define TK_AUTOINCR                       126
#define TK_INSERT                         127
#define TK_DELETE                         128
#define TK_UPDATE                         129
#define TK_SET                            130
#define TK_DEFERRABLE                     131
#define TK_FOREIGN                        132
#define TK_DROP                           133
#define TK_UNION                          134
#define TK_ALL                            135
#define TK_EXCEPT                         136
#define TK_INTERSECT                      137
#define TK_SELECT                         138
#define TK_VALUES                         139
#define TK_DISTINCT                       140
#define TK_DOT                            141
#define TK_FROM                           142
#define TK_JOIN                           143
#define TK_USING                          144
#define TK_ORDER                          145
#define TK_GROUP                          146
#define TK_HAVING                         147
#define TK_LIMIT                          148
#define TK_WHERE                          149
#define TK_RETURNING                      150
#define TK_INTO                           151
#define TK_NOTHING                        152
#define TK_FLOAT                          153
#define TK_BLOB                           154
#define TK_INTEGER                        155
#define TK_VARIABLE                       156
#define TK_CASE                           157
#define TK_WHEN                           158
#define TK_THEN                           159
#define TK_ELSE                           160
#define TK_INDEX                          161
#define TK_ALTER                          162
#define TK_ADD                            163
#define TK_WINDOW                         164
#define TK_OVER                           165
#define TK_FILTER                         166
#define TK_COLUMN                         167
#define TK_AGG_FUNCTION                   168
#define TK_AGG_COLUMN                     169
#define TK_TRUEFALSE                      170
#define TK_ISNOT                          171
#define TK_FUNCTION                       172
#define TK_UMINUS                         173
#define TK_UPLUS                          174
#define TK_TRUTH                          175
#define TK_REGISTER                       176
#define TK_VECTOR                         177
#define TK_SELECT_COLUMN                  178
#define TK_IF_NULL_ROW                    179
#define TK_ASTERISK                       180
#define TK_SPAN                           181
#define TK_ERROR                          182
#define TK_SPACE                          183
#define TK_ILLEGAL                        184
```
</details>

So, `yymajor` (`tokenType` when passed from the tokenizer) is an integer that represents the current token being processed. The parser will work one token at a time. In addition to the token, the logged output suggests that the parser is also keeping track of the current state, held in the `yyact` variable.

That variable is defined at line 5839 of the `parse.c` file:

```c
yyact = yypParser->yytos->stateno;
```

The shortened variable names and "yy" prefix can be confusing, but comments in the source help elucidate what we are looking at. `yypParser` points to the `yyp` object conformed to the `yyParser` struct, so it is basically the `pEngine` object from the tokenizer. The `yytos` field on that object is the "top of stack". The parser keeps a "stack" of "entries" that represent the current state of the parser. The `stateno` field on a stack entry is an integer that represents that entry's state. We can see from the logged output that the parser starts at state `0`.

So, when parsing begins, we have a starting token and a starting state. At this point, the parser enters into a loop to process the input tokens. The loop is defined at line 5841 of the `parse.c` file in the `sqlite3Parser` function. Like the loop in the `tokenize.c` file, this loop is a `while` loop that runs indefinitely until a `break` is called internally. In order to digest the complicated logic inside this loop, which is the heart of the parser, I am going to break it down into levels. Directly inside the loop we find an `if`/`else` structure that branches the execution logic down four paths based on a new, computed `yyact` value:

```c
while(1){ /* Exit by "break" */
  yyact = yy_find_shift_action((YYCODETYPE)yymajor,yyact);
  if( yyact >= YY_MIN_REDUCE ){
    // ...
  }else if( yyact <= YY_MAX_SHIFTREDUCE ){
    // ...
  }else if( yyact==YY_ACCEPT_ACTION ){
    // ...
  }else{
    // ...
  }
}
```

Let's start by examining how `yyact` is computed and what the four execution paths are.

- - -

### `yy_find_shift_action`

Given the input token (`yymajor`) and current state (`yyact`), the SQLite parser computes what it calls a "shift action". The `yy_find_shift_action` function takes the input token and current state and returns the "shift action". This function is defined at line 2584 of the `parse.c` file. If you want, you can inspect the full function below, but I will also be walking through it in the next few paragraphs.

<details markdown="1">
  <summary>Breakdown by benchmark operation</summary>
    <code>yy_find_shift_action</code> definition
  </summary>

```c
/*
** Find the appropriate action for a parser given the terminal
** look-ahead token iLookAhead.
*/
static YYACTIONTYPE yy_find_shift_action(
  YYCODETYPE iLookAhead,    /* The look-ahead token */
  YYACTIONTYPE stateno      /* Current state number */
){
  int i;

  if( stateno>YY_MAX_SHIFT ) return stateno;
  assert( stateno <= YY_SHIFT_COUNT );
#if defined(YYCOVERAGE)
  yycoverage[stateno][iLookAhead] = 1;
#endif
  do{
    i = yy_shift_ofst[stateno];
    assert( i>=0 );
    assert( i<=YY_ACTTAB_COUNT );
    assert( i+YYNTOKEN<=(int)YY_NLOOKAHEAD );
    assert( iLookAhead!=YYNOCODE );
    assert( iLookAhead < YYNTOKEN );
    i += iLookAhead;
    assert( i<(int)YY_NLOOKAHEAD );
    if( yy_lookahead[i]!=iLookAhead ){
#ifdef YYFALLBACK
      YYCODETYPE iFallback;            /* Fallback token */
      assert( iLookAhead<sizeof(yyFallback)/sizeof(yyFallback[0]) );
      iFallback = yyFallback[iLookAhead];
      if( iFallback!=0 ){
#ifndef NDEBUG
        if( yyTraceFILE ){
          fprintf(yyTraceFILE, "%sFALLBACK %s => %s\n",
             yyTracePrompt, yyTokenName[iLookAhead], yyTokenName[iFallback]);
        }
#endif
        assert( yyFallback[iFallback]==0 ); /* Fallback loop must terminate */
        iLookAhead = iFallback;
        continue;
      }
#endif
#ifdef YYWILDCARD
      {
        int j = i - iLookAhead + YYWILDCARD;
        assert( j<(int)(sizeof(yy_lookahead)/sizeof(yy_lookahead[0])) );
        if( yy_lookahead[j]==YYWILDCARD && iLookAhead>0 ){
#ifndef NDEBUG
          if( yyTraceFILE ){
            fprintf(yyTraceFILE, "%sWILDCARD %s => %s\n",
               yyTracePrompt, yyTokenName[iLookAhead],
               yyTokenName[YYWILDCARD]);
          }
#endif /* NDEBUG */
          return yy_action[j];
        }
      }
#endif /* YYWILDCARD */
      return yy_default[stateno];
    }else{
      assert( i>=0 && i<(int)(sizeof(yy_action)/sizeof(yy_action[0])) );
      return yy_action[i];
    }
  }while(1);
}
```
</details>

If we simplify the code by removing the `assert`s and `#ifdef`s, the core of the logic is at least approachable:

```c
if( stateno>YY_MAX_SHIFT ) return stateno;

do{
  i = yy_shift_ofst[stateno];
  i += iLookAhead;
  if( yy_lookahead[i]!=iLookAhead ){
    iFallback = yyFallback[iLookAhead];
    if( iFallback!=0 ){
      iLookAhead = iFallback;
      continue;
    }
    int j = i - iLookAhead + YYWILDCARD;
    if( yy_lookahead[j]==YYWILDCARD && iLookAhead>0 ){
      return yy_action[j];
    }
    return yy_default[stateno];
  }else{
    return yy_action[i];
  }
}while(1);
```

We have a guard clause and a loop. The loop has two primary branches. This is digestible; let's take it piece by piece.

First, the guard clause: `if( stateno>YY_MAX_SHIFT ) return stateno;`. The `stateno` argument inside of the `yy_find_shift_action` function is the `yyact` variable passed in from the `sqlite3Parser` function. `YY_MAX_SHIFT`, as suggested by the fact that it is all caps, is a constant. We find it defined on line 525 of the `parse.c` file as the integer `578`. So, while we don't yet understand what all of the different integer values of `yyact`/`stateno` might mean, we now know that any state number greater than `578` does not have a shift action; or, more precisely, the shift action is the state itself. As we are tracing the execution of the parser for the first token and initial state, we know that `stateno` is currently `0`, which is not greater than `578`. So, we will _not_ return early from the function.

For those state's that are less than or equal to `578`, the `yy_find_shift_action` function enters into the loop. The first step is to calculate a new integer from the `stateno`: `i = yy_shift_ofst[stateno];`. There is a "shift offset" array defined where we can transform a `stateno` into an offset `i`. We don't yet know what an "offset" is or does, but let's carry on and see if it becomes clear through usage.

In the comments, the `yy_shift_ofst` array is described as providing "for each state, the offset into `yy_action` for shifting terminals" (line 592). This is indeed the `else` branch of the loop: `return yy_action[i];`. So, the "shift action" offset is returned and then summed with the current token `iLookAhead` to get the next action. Let's look at our statement again and observe the calculations step by step.

We started with `yymajor` equal to *17* and `yyact` equal to *0* inside of the `sqlite3Parser` loop. These two variables are passed to the `yy_find_shift_action` function as arguments for the parameters `iLookAhead` and `stateno`, respectively. Since *0* is not greater than *578* (the value of `YY_MAX_SHIFT`), we enter this loop, where we retrieve the "shift offset" for this state. The 0th value in the `yy_shift_ofst` is *1648*. We then add the `iLookAhead` value to this offset: *1648 + 17 = 1665*. Ignoring the `if` condition for now, the "shift action" that would be returned for `i` as *1665* from the `yy_action` table is *852*. We don't yet know how this "shift action" integer will be used by the `sqlite3Parser` function, and we haven't investigated the `if` condition, but we are starting to wrap our heads around the logic for determing the "shift action".

Before leaving the `yy_find_shift_action` function, let's take a look at the `if` condition that we've been ignoring. It checks if the value for `i` in the `yy_lookahead` table *is not* equal to the argument passed as `iLookAhead`; that is, does the parser need to use a fallback. The comments explain that this is what allows some keywords to be used as identifiers; so, it is possible to execute `CREATE TABLE database (a)`, even though `DATABASE` is a SQLite keyword.

In this first case, we don't enter this if condition because `yy_lookahead[1665]` is 17, which is the value of `iLookAhead`. So, for token `CREATE` and state `0`, `yy_find_shift_action` returns *852* by looking up the "shift offset", adding back the state integer, and returning the value at that index in the `yy_action` table. This *852* value will be set as the value for `yyact` in the `sqlite3Parser` function.

- - -

### Branching logic in `sqlite3Parser`

With `yyact` defined, the next detail is the branching logic in `sqlite3Parser`:

```c
while(1){ /* Exit by "break" */
  yyact = yy_find_shift_action((YYCODETYPE)yymajor,yyact);
  if( yyact >= YY_MIN_REDUCE ){
    // ...
  }else if( yyact <= YY_MAX_SHIFTREDUCE ){
    // ...
  }else if( yyact==YY_ACCEPT_ACTION ){
    // ...
  }else{
    // ...
  }
}
```

The logic compares the `yyact` integer to 3 constants. We can find the definitions of those constants in lines 525-530:

```c
#define YY_MIN_REDUCE        1246
#define YY_MAX_SHIFTREDUCE   1242
#define YY_ACCEPT_ACTION     1244
```

And the comments above those lines provide some basic explanatory context:

```
YY_MIN_REDUCE      Minimum value for reduce actions
YY_MAX_SHIFTREDUCE Maximum value for shift-reduce actions
YY_ACCEPT_ACTION   The yy_action[] code for accept
```

So, we might rephrase the logic of these branches as:

1. does the shift action require a reduce?
2. does the shift action require a shift-reduce?
3. is the shift action simply accepted?

The logic for these question is:

1. is `yyact` greater than or equal to *1246*?
2. is `yyact` less than or equal to *1242*?
3. is `yyact` equal to *1244*?

To put it another way, if `yyact` is in the range `1246..Infinity`, then it requires a reduce; if it is in the range `0..1242`, then it requires a shift-reduce; and if it equals 1244, then it is simply accepted. When we lay out the ranges like this, we can see that the `else` branch only applies when `yyact` is either *1243* or *1245*. In lines 528 and 530, we can see the definitions for these `yyact` values:

```c
#define YY_ERROR_ACTION      1243
#define YY_ACCEPT_ACTION     1244
#define YY_NO_ACTION         1245
```

So, we can expect that within the `else` block, checks will be made to see if `yyact` is an error or simply a no-op.

With this understanding of the branching logic, let's walk through what happens with our current *852* `yyact` value. *852* is not greater than or equal to *1246* (i.e. `YY_MIN_REDUCE`), and so we try the next condition. *852* is less than or equal to *1242* (i.e. `YY_MAX_SHIFTREDUCE`), so we enter this condition.

Let's expand (while still focusing on the core details) that block:

```c
while(1){ /* Exit by "break" */
  yyact = yy_find_shift_action((YYCODETYPE)yymajor,yyact);
  if( yyact >= YY_MIN_REDUCE ){
    // ...
  }else if( yyact <= YY_MAX_SHIFTREDUCE ){
    yy_shift(yypParser,yyact,(YYCODETYPE)yymajor,yyminor);
    break;
  }else if( yyact==YY_ACCEPT_ACTION ){
    // ...
  }else{
    // ...
  }
}
```

Pretty straightforward; when `yyact` is less than or equal to *1242*, call the `yy_shift` function and break out of the while loop. Let's dig into this `yy_shift` function next.

- - -

### `yy_shift`

The `yy_shift` function, well, performs a shift action. Its signature is:

```c
static void yy_shift(
  yyParser *yypParser,          /* The parser to be shifted */
  YYACTIONTYPE yyNewState,      /* The new state to shift in */
  YYCODETYPE yyMajor,           /* The major token to shift in */
  sqlite3ParserTOKENTYPE yyMinor        /* The minor token to shift in */
)
```

Before jumping into the definition of this function, let's do a quick recap of the arguments and parameters we have at this point in our parsing. The top-level `sqlite3Parser` function has 3 require parameters: `yyp`, `yymajor`, and `yyminor`. `yyp` is the parser instance, so we won't worry about it for now. `yymajor` and `yyminor` are the key parameters. `yymajor` is the token type defined as an integer. Right now, we are parsing the `CREATE` keyword token, represented by the integer *17*. `yyminor` holds the value for the token, which is currently the string `"CREATE"`.

When `yy_shift` is called from `sqlite3Parser`, its `yyNewState` parameter is supplied by the `yyact` argument; its `yyMajor` parameter is supplied by the `yymajor` argument; and its `yyMinor` parameter is supplied by the `yyminor` argument. So, in addition to the parser instance, for this invocation, `yy_shift` is passed `852`, `17`, and `"CREATE"`. With that refresher out of the way, let's check out the body of this method. Once again, I will simplify the source by removing branches and sections added for safety:

```c
static void yy_shift(
  yyParser *yypParser,          /* The parser to be shifted */
  YYACTIONTYPE yyNewState,      /* The new state to shift in */
  YYCODETYPE yyMajor,           /* The major token to shift in */
  sqlite3ParserTOKENTYPE yyMinor        /* The minor token to shift in */
){
  yyStackEntry *yytos;
  yypParser->yytos++;
  if( yypParser->yytos>=&yypParser->yystack[yypParser->yystksz] ){
    if( yyGrowStack(yypParser) ){
      yypParser->yytos--;
      yyStackOverflow(yypParser);
      return;
    }
  }
  if( yyNewState > YY_MAX_SHIFT ){
    yyNewState += YY_MIN_REDUCE - YY_MIN_SHIFTREDUCE;
  }
  yytos = yypParser->yytos;
  yytos->stateno = yyNewState;
  yytos->major = yyMajor;
  yytos->minor.yy0 = yyMinor;
  yyTraceShift(yypParser, yyNewState, "Shift");
}
```

At a high level we see that the function has a stack overflow guard clause, accounts for a possible shift-reduce action, and then updates the "top of the stack". So, in short, the "shift action" is simply updating the top of the stack entry. The one bit of spice is the check if the action (`yyNewState`) is a simple "shift action" or a "shift-reduce" action.

If the action integer is larger than the `YY_MAX_SHIFT` value (*578* as defined on line 525), then the `yyNewState` integer is updated. The update is defined in terms of the `YY_MIN_REDUCE` and `YY_MIN_SHIFTREDUCE` constants, which are *1246* and *838* respectively. So, when the action requires a shift-reduce, the new state value is increments by *408*.

In our case, *852* is indeed greater than *578*, so the `yyNewState` value is updated to *1260* (*852 + 408*).

The `yyTraceShift` call is what prints out the next line in our trace:

```
Shift 'CREATE', pending reduce 14
```

The value *14* is a hint of what is to come. The `yyTraceShift` function has two branches—one for when the new state is less than the `YYNSTATE`, which represents the total number of symobls (*579* in our parser file), and one for when it is greater than or equal to this number. *1260* is greater than *579*, so the latter branch is called:

```c
fprintf(yyTraceFILE,"%s%s '%s', pending reduce %d\n",
   yyTracePrompt, zTag, yyTokenName[yypParser->yytos->major],
   yyNewState - YY_MIN_REDUCE);
```

We see here that *14* is calculated as `yyNewState - YY_MIN_REDUCE`. From above, we can recall that `YY_MIN_REDUCE` is equal to *1246*. So, *14* is simply *1260 - 1246*. We can expect that shortly in the code path, this same calculation will be done and *14* will be used to take the appropriate reduce action.

- - -

### Finishing this parsing pass

The next line in our trace output is:

```
Return. Stack=[CREATE]
```

This is printed in lines 6015-6024 of the `parse.c` file in the `sqlite3Parser` function right before `return;` is called. So, we are finishing the parsing pass for this first token where the `sqlite3Parser` function is called within the while loop running in the `sqlite3RunParser` function in the `tokenize.c` file. The result of this first run of `sqlite3Parser` is a parser instance with a stack containing one symbol.

In the next run, this same parser instance will be told to parse the next token, the `TK_TABLE` token, given its current state. But, I think this investigation is thorough enough for this first post. I will leave that investigation to the next post. For now, let's simply summarize what we have found.

SQLite uses a shift-reduce parser, parsing token by token. A parser instance that holds state, like a stack of symbols, is used to decide what actions to take given the current token and the current state. When calling `CREATE TABLE`, the `sqlite3_prepare` function calls the `sqlite3RunParser`, which calls `sqlite3Parser` in a while loop. The parsing function takes the current token and current state and finds the appropriate next action. That next action can either be a shift action or a reduce action. A shift action pushes the token onto the parser's stack and advances the parser's current state. A reduce action, well, reduces the stack of tokens to some higher-order rule definition; that is, it reduces a stack composed of terminal and possibly non-terminal symbols into a stack with simply one non-terminal symbol.
