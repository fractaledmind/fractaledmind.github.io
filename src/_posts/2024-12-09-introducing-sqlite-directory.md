---
title: Introducing sqlite.directory
date: 2024-12-09
tags:
  - sqlite.directory
  - rails
  - sqlite
---

`sqlite.directory` is a directory of web applications that use the SQLite database engine in some meaningful capacity in production. I have just launched the initial release today. Check it out and list your SQLite-backed app today: [https://sqlite.directory](https://sqlite.directory)

<img src="{{ '/images/sqlite-directory-screenshot.png' | relative_url }}" alt="A screenshot of the sqlite.directory listing form" style="width: 100%" />

<!--/summary-->

- - -

The whole app is open source, a simple `#SQLiteOnRails` application. The codebase is vanilla [Rails](https://rubyonrails.org/), [Puma](http://puma.io/), and—of course—[SQLite](https://sqlite.org/). Basically the simplest possible setup. Feel free to make suggestions or improvements.

[https://github.com/fractaledmind/sqlite.directory](https://github.com/fractaledmind/sqlite.directory)

I've started simple and minimal, but there are all kinds of additional data we could gather about production applications that rely on SQLite. Let me know your thoughts on how to make [sqlite.directory](https://sqlite.directory) the best possible collection of information on production SQLite usage.

- - -

If you would like to contribute to the application itself, it is still very early days for this so your mileage will vary here.

But almost any contribution will be beneficial at this point. Check the [current Issues](https://github.com/fractaledmind/sqlite.directory/issues) to see where you can jump in!

If you've got an improvement, just send in a pull request!

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

If you've got feature ideas, simply [open a new issues](https://github.com/fractaledmind/sqlite.directory/issues/new)!
