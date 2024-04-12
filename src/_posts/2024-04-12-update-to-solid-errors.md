---
title: Update to Solid Errors
date: 2024-04-12
tags:
  - code
  - ruby
  - rails
  - gem
---

Version 0.4.2 of [Solid Errors](https://github.com/fractaledmind/solid_errors) is out. The 0.4.x versions of the gem adds a number of awesome new features, most notably email notifications. If you need a self-hosted error tracking solution for your Rails application, Solid Errors is a great choice.

<!--/summary-->

- - -

You can find the full changelog [here](https://github.com/fractaledmind/solid_errors/blob/main/CHANGELOG.md). The gem is available on [RubyGems](https://rubygems.org/gems/solid_errors) and the source code is on [GitHub](https://github.com/fractaledmind/solid_errors).

Unfortunately, there is a caveat. The current point release of Rails (7.1.3.2) has a bug which severely limits the utility of Solid Errors. Exceptions raised during a web request are not reported to Rails' error reporter. There is a fix in the main branch, but it has not been released in a new point release. As such, Solid Errors is not production-ready unless you are running Rails from the main branch or until a new point version is released and you upgrade. The original bug report can be found [here](https://github.com/rails/rails/issues/51002) and the pull request making the fix is [here](https://github.com/rails/rails/pull/51050). I will try to backport the fix into the gem directly, but I haven't quite figured it out yet.

If you are using Rails `main` though, you should definitely check out Solid Errors. It's a great gem and I'm excited to see where it goes.

For a sneak peak of the new email notifications, you can check out the error page for any error. Yes, the email notifications include all of the same information formatted and layed out in the same way as the error page. I think they are pretty cool.

<img src="{{ '/images/solid_errors_email.png' | relative_url }}" alt="" style="width: 100%" />

If you bump into any problem, please don't hesitate to [open an issue](https://github.com/fractaledmind/solid_errors/issues/new).
