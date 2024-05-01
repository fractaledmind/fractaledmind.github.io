---
series: 'Building an Interpreter for Propositional Logic'
title: 'An interlude with minitest/autorun'
date: 2018-01-04
tags:
  - code
  - ruby
  - interpreter
  - philosophy
  - epistemology
  - logic
  - tutorial
  - interpreter
summary: An interlude in a series of posts laying out the process, step by step, of building an interpreter in Ruby for working with propositional logic. In this small post, we take our hand-rolled "tests" and move the code into an executable test script with <code>minitest/autorun</code>.
---

When we left our interpreter for propositional logic, we had a hand-rolled `run_tests` method which was calling our own `assert_interpret_equals` method. However, after looking at the Rails' Guides bug template scripts, I was inspired to make our code an executable test script with `minitest/autorun`.

Here, we won't change any of the logic itself, just update our single-file script to be executable using the `ruby` command which will output minitest results.

I will confess that the change was pretty simple, so I won't walk through it. There are only two key changes. The first is to ensure our dependencies are setup at the start of the file using `bundler/inline`:

```ruby
require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "minitest"
end

require "minitest/autorun"
```

Next, we simply migrate our `run_tests` method and `assert_interpret_equals` into a `Minitest::Test` class with `assert_equals` calls, e.g.:

```ruby
class LogicInterpreterTest < Minitest::Test
  def test_tokens
    assert_equal true, interpret('T')
    assert_equal false, interpret('F')
  end

  # ...
end
```

That's it! With our script updated, we can use it like so:

```shell
$ ruby logical.rb
Fetching gem metadata from https://rubygems.org/.
Resolving dependencies...
Using bundler 2.4.8
Using minitest 5.19.0
Run options: --seed 16731

# Running:

.........

Finished in 0.001000s, 9000.0006 runs/s, 29000.0020 assertions/s.

9 runs, 29 assertions, 0 failures, 0 errors, 0 skips
```

I really like being able to use minitest and move beyond our hand-rolled test harness.

> You can find the script we have built to this point in [this revision of this Gist](https://gist.github.com/fractaledmind/a072674b18086fdebf3b3a535c0f7dfb/338dce03451956f6b9c0bfab80ee992317fc0d0b)

- - -

## All posts in this series

* [Part 1 — starting simple]({% link _posts/2017-12-29-ruby-logic-interpreter-1.md %})
* [Part 2 — proper propositional logic]({% link _posts/2018-01-03-ruby-logic-interpreter-2.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Interlude — minitest tests]({% link _posts/2018-01-04-ruby-logic-interpreter-3.md %})
* [Part 3 — handling variables]({% link _posts/2019-01-26-ruby-logic-interpreter-4.md %})
