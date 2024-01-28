---
title: Introducing Solid Errors
date: 2024-01-28
tags:
  - code
  - ruby
  - rails
  - gem
---

[Solid Errors](https://github.com/fractaledmind/solid_errors) is a Rails engine that provides a dashboard for viewing and resolving exceptions in your Rails application without the need for an external 3<sup>rd</sup> party service. With version 0.3.0, I am happy to announce that Solid Errors is now ready for production use.

<!--/summary-->

- - -

Rails 7.0 [added](https://github.com/rails/rails/pull/43625) a new [error reporting API](https://guides.rubyonrails.org/error_reporting.html) that allows you to easily record uncaught exceptions in your application. Solid Errors uses this API to store exceptions in the database, and provides a simple UI for viewing and managing exceptions.

There are intentionally few features; you can view and resolve errors. That's it. The goal is to provide a simple, lightweight, and performant solution for tracking exceptions in your Rails application. If you need more features, you should probably use a 3<sup>rd</sup> party service like [Honeybadger](https://www.honeybadger.io/).

Installation and setup are standard for a Rails engine. Add the gem to your Gemfile (`bundle add solid_errors`), run the installer (`rails generate solid_errors:install`), and mount the engine in your routes file (`mount SolidErrors::Engine, at: "/solid_errors"`).

The gem creates two tables in the database you connect it to: `solid_errors` and `solid_error_occurrences`. The first table stores the exception details, and the second table stores the occurrences of each exception. This allows you to track how many times an exception has occurred, and when it was last resolved.

The engine registers [the subscriber](https://github.com/fractaledmind/solid_errors/blob/main/lib/solid_errors/subscriber.rb), which does a couple of additional things besides storing the exception in the database. First, it checks if the exception should be ignored. The ignore list is currently static, but I plan to make it configurable in the future. Second, it unresolves previously resolved exceptions if a new occurrence is recorded. This allows you to track when an exception is resolved, and when it occurs again.

The dashboard simply shows all unresolved exceptions, and allows you to resolve them. You can also view the details of each exception, including the backtrace, and the occurrences of each exception.

The index view looks like this:

![list of unresolved exceptions](https://github.com/fractaledmind/solid_errors/blob/main/images/index-screenshot.png?raw=true)

The details view looks like this:

![details of a particular exception](https://github.com/fractaledmind/solid_errors/blob/main/images/show-screenshot.png?raw=true)

The gem works particularly well with SQLite on Rails applications, as you can connect the gem to a separate database, and avoid the performance hit of storing exceptions in the same database as your application. I wrote a [quick tip]({% link _posts/2024-01-02-sqlite-quick-tip-multiple-databases.md %}) on how to configure your `database.yml` file to use multiple databases. You can then install the gem with the `--database` option, and specify the database you want to use (`rails generate solid_errors:install --database errors`).

The gem is still in its infancy, and I plan to add more features in the future. If you have any suggestions, please [open an issue](https://github.com/fractaledmind/solid_errors/issues). I hope you find it useful!
