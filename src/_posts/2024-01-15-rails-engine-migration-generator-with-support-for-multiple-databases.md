---
title: Rails engine migration generator with support for multiple databases
date: 2024-01-15
tags:
  - code
  - ruby
  - rails
  - til
---

Rails [supports multiple databases](https://guides.rubyonrails.org/active_record_multiple_databases.html). This means you can specify which database to point a migration at when you use a generator (e.g. `bin/rails generate migration CreateDogs name:string --database animals`). For gems, when you are creating a [Rails engine](https://guides.rubyonrails.org/engines.html), you will often need to create some tables, so you register a generator to install the migrations (e.g. `bin/rails generate my_gem:install`). I want to ensure that the generator I am providing from my engine/gem allows the user to specify a specific database, and my gem respects that. With the help of some folks from Twitter, I figured out the requirements.

<!--/summary-->

- - -

I started building a new gem this weekend (more about that soon). It needs a generator to install the migrations, so I started with the following:

```ruby
class SolidErrors::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  class_option :skip_migrations, type: :boolean, default: nil, desc: "Skip migrations"

  def create_migration_file
    unless options[:skip_migrations]
      rails_command "railties:install:migrations FROM=solid_errors", inline: true
    end
  end
end
```

This works, but didn't allow users to specify a database. I tried a few things, but couldn't get it to work. I asked for help [on Twitter](https://twitter.com/fractaledmind/status/1746675951067345082), and [Chad Lee B.](https://twitter.com/chaadow) pointed me to [the solution](https://x.com/chaadow/status/1746678496443629956?s=20) and [kowa](https://twitter.com/lzkowa) recommended to checkout how [`GoodJob`](https://github.com/bensheldon/good_job) does this. Both were very helpful. I ended up with the following:

```ruby
class SolidErrors::InstallGenerator < Rails::Generators::Base
  include ActiveRecord::Generators::Migration

  source_root File.expand_path("templates", __dir__)

  class_option :database, type: :string, aliases: %i(--db), desc: "The database for your migration. By default, the current environment's primary database is used."
  class_option :skip_migrations, type: :boolean, default: nil, desc: "Skip migrations"

  def create_migration_file
    return if options[:skip_migrations]

    migration_template 'create_solid_errors_tables.rb.erb', File.join(db_migrate_path, "create_solid_errors_tables.rb")
  end

  private

  def migration_version
    "[#{ActiveRecord::VERSION::STRING.to_f}]"
  end
end
```

There are 3 essential details to ensure that your gem's generator respects the database option:

1. Include [`ActiveRecord::Generators::Migration`](https://api.rubyonrails.org/classes/Rails/Generators/Migration.html) in your generator
2. Add a `class_option` for `database`
3. Use [`migration_template`](https://api.rubyonrails.org/classes/Rails/Generators/Migration.html#method-i-migration_template) method

If you add these three details to your gem's generator, users will be able to specify a database when they run your generator. For example, if you have a gem called `my_gem` and you want to install the migrations for the `animals` database, you would run `bin/rails generate my_gem:install --database animals`.

- - -

This was a fun little problem to solve. I hope this helps you if you are building a gem that needs to install migrations.
