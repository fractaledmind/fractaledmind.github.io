---
series: Rails Template Scripts
title: Manipulating <code>database.yml</code>
date: 2024-08-21
tags:
  - code
  - ruby
  - yaml
  - rails
---

This is the second in a series of posts on building powerful and resilient [Rails application templates](https://guides.rubyonrails.org/rails_application_templates.html). In the [previous post]({% link _posts/2024-08-21-rails-template-scripts-parsing-and-emitting-database-yml.md %}), we discussed parsing and emitting YAML files with comments. Today, we will be looking at manipulating the `database.yml` file's AST.

<!--/summary-->

- - -

At the end of the [previous post]({% link _posts/2024-08-21-rails-template-scripts-parsing-and-emitting-database-yml.md %}), we had a way to parse a YAML file or string and emit _partial_ YAML content. We needed to emit _partial_ YAML content to leave comment blocks in place. We also needed to ensure that our implementation could handle inline commented out lines in the YAML content. To achieve all of this, we created a `DatabaseYAML` class:

```ruby
class DatabaseYAML
  COMMENT_REGEX = /^([ \t]+)#\s?(.*?)$/.freeze

  def initialize(yaml)
    @yaml = yaml
    @comment_cache = {}
  end

  def parse_yaml_with_comments(yaml)
    matchdata = yaml.match COMMENT_REGEX
    parseable = if matchdata
      commented, indentation, content = matchdata.to_a
      uncommented = indentation + content
      @comment_cache[uncommented] = commented
      yaml.gsub(commented, uncommented)
    else
      yaml
    end
    Psych.parse_stream(parseable)
  end

  def emit_pair(scalar, mapping)
    emission_stream = Psych::Nodes::Stream.new
    emission_document = Psych::Nodes::Document.new
    emission_mapping = Psych::Nodes::Mapping.new
    emission_mapping.children.concat [scalar, mapping]
    emission_document.children.concat [emission_mapping]
    emission_stream.children.concat [emission_document]
    output = emission_stream.yaml.gsub!(/^---/, '').strip!
    @comment_cache.each do |uncommented, commented|
      output.gsub!(uncommented, commented)
    end
    output
  end
end
```

In this post, let's dig into some actual AST manipulations. One of the most important take-aways that I have had from this project is that limiting your problem space is key to making progress. In this case, we are only interested in manipulating the `database.yml` file. This means that we can make some assumptions about the structure of the file. We can also make some assumptions about the types of manipulations that we will need to make. This allows us to focus on the problem at hand and not get bogged down in the details of YAML parsing and emitting.

Trust me, trying to write a completely generic YAML manipulation engine is a fool's errand. YAML is a complex format with many edge cases. By limiting our scope to a specific file and a specific set of manipulations, we can make progress much more quickly.

### Defining a new database definition

The first manipulation to tackle is adding a new database definition to the `database.yml` file. This is a common task when setting up a new Rails application, especially when using SQLite, where having a separate database file for each IO-bound component helps avoid write contention. We want to add a new database definition to the `database.yml` file. This is a simple task, but it is a good starting point for our manipulation engine.

Let's start with an example of the YAML output we need to generate:

```yaml
name: &name
  <<: *default
  migrations_paths: db/name_migrate
  database: storage/<%= Rails.env %>-name.sqlite3
```

We want to generate a new top-level mapping that has an anchor (so that we can reference this mapping in our environment definitions), inherits the `default` database configuration, defines a separate directory to hold migrations for this database, and specifies the location of the database file.

To achieve this, we need to create a new method in our `DatabaseYAML` class. This method will take the name of the new database and return the YAML content for the new database definition. We will call this method `new_database`:

```ruby
def new_database(name)
  db = Psych::Nodes::Mapping.new(name)
  db.children.concat [
    Psych::Nodes::Scalar.new("<<"),
    Psych::Nodes::Alias.new("default"),
    Psych::Nodes::Scalar.new("migrations_paths"),
    Psych::Nodes::Scalar.new("db/#{name}_migrate"),
    Psych::Nodes::Scalar.new("database"),
    Psych::Nodes::Scalar.new("storage/<%= Rails.env %>-#{name}.sqlite3"),
  ]
  emit_pair(Psych::Nodes::Scalar.new(name), db)
end
```

A couple key points to note here:

* When you create a new `Mapping` instance with a value, that value will become the anchor. A `Mapping` initialized with no value will be a "normal" mapping.
* We need to ensure to create an `Alias` node when referencing the `default` database configuration.
* The YAML AST structure uses a flat array of child nodes for a key-value mapping. Each tuple of child nodes represents a key-value pair.

Once you know the structure of the AST, it is relatively straightforward to build up the AST for the new database definition. The `emit_pair` method will take care of emitting the YAML string for the new database definition. If you execute something like `puts new_database("name")` in an IRB console, you should see the following output:

```yaml
new: &new
  <<: *default
  migrations_paths: db/new_migrate
  database: storage/<%= Rails.env %>-new.sqlite3
```

### Adding a new database definition to environment configurations

Once you have a database defined in the `database.yml` file, you need to "activate" it by adding it to the environment configurations. That means, we need to make use of Rails' [multiple database support](https://guides.rubyonrails.org/active_record_multiple_databases.html). You see, defining a new database definition is inert until you tell Rails that this database should be used in a specific environment. In order to use multiple databases in a single environment, you have to define the environment(s) using a three-tiered configuration structure. This is the example given in the Rails Guides:

```yaml
production:
  primary:
    database: my_primary_database
    username: root
    password: <%= ENV['ROOT_PASSWORD'] %>
    adapter: mysql2
  primary_replica:
    database: my_primary_database
    username: root_readonly
    password: <%= ENV['ROOT_READONLY_PASSWORD'] %>
    adapter: mysql2
    replica: true
  animals:
    database: my_animals_database
    username: animals_root
    password: <%= ENV['ANIMALS_ROOT_PASSWORD'] %>
    adapter: mysql2
    migrations_paths: db/animals_migrate
  animals_replica:
    database: my_animals_database
    username: animals_readonly
    password: <%= ENV['ANIMALS_READONLY_PASSWORD'] %>
    adapter: mysql2
    replica: true
```

Under the `production` environment key, you have a hash of database name keys, and under each of those is a hash of configuration options. Now, this three-tiered structure can be simplified using YAML anchors and aliases. So, in the same way that the default `development` environment config inherits from the `default` database configuration:

```yaml
development:
  <<: *default
  database: storage/development.sqlite3
```

You can use the same technique to simplify a three-tiered environment configuration:

```yaml
development:
  primary:
    <<: *default
    database: storage/development.sqlite3
  new: *new
```

So, this is the second transformation we need to implement. And, to keep the implementation simple, we will simply add the database to _every_ environment defined in the `database.yml` file. Let's add a new method to our `DatabaseYAML` class called `add_database` and get to work:

```ruby
class DatabaseYAML
  def add_database(environment, name)
    # implementation goes here
  end
end
```

There are essentially 2 steps to this implementation:

1. Find the environment configurations in the YAML AST.
2. Add the new database definition to each environment configuration.

Let's start with the first. How do we identify the environment configurations in the YAML? I don't want to simply use the `development`, `test`, and `production` names, because what if an app has a `staging` environment defined? Or some other custom environment? So, we can't rely on names, what is the structure of the AST that we can use to identify environment configurations?

Well, we know that the `database.yml` file only has two kinds of top-level mappings: database configurations and environment configurations. The database configurations are easy to identify because they have an anchor. So, the environment configurations are the ones that don't have an anchor. This is the key insight we need to identify environment configurations in the YAML AST.

So, we want to get to the root node, iterate over the pairs of children, and select those pairs that are a `Scalar` plus `Mapping` pair where the `Mapping` doesn't have an anchor. Here's how you can do that:[^1]

```ruby
def add_database(name)
  root = @stream.children.first.root
  root.children.each_slice(2).map do |scalar, mapping|
    next unless scalar.is_a?(Psych::Nodes::Scalar)
    next unless mapping.is_a?(Psych::Nodes::Mapping)
    next unless mapping.anchor.nil? || mapping.anchor.empty?

    # implementation goes here
  end.compact!
end
```

[^1]: `@stream` here is an instance variable that holds the result of the `Psych.parse_stream(yaml)` call.

With this in place, we can now focus on adding the new database definition to each environment configuration. But, we need to be thoughtful. This script can be run as a part of `rails new` or against an existing database. This means that the `database.yml` config might already be in a three-tiered structure. We need to handle both two-tiered and three-tiered environment configurations.

Again, we can rely on some conventions to help us navigate the AST and figure out which structure we are dealing with. In a two-tiered environment configuration, the first key-value pair in the mapping will have a scalar with the value `<<` (to inherit from the `default` database configuration). Otherwise, we can presume we are dealing with a three-tiered environment configuration:

```ruby
def add_database(name)
  root = @stream.children.first.root
  root.children.each_slice(2).map do |scalar, mapping|
    # ...

    if mapping.children.first.value == "<<" # 2-tiered environment
      # implementation goes here
    else # 3-tiered environment
      # implementation goes here
    end
  end.compact!
end
```

When dealing with a two-tiered environment configuration, we need to shift the whole environment configuration to a three-tiered config and then add the new database definition to the mapping. We can do this by making the existing mapping the value of a `primary` key, then adding a key-value alias for the database beneath that:

```ruby
new_mapping = Psych::Nodes::Mapping.new
new_mapping.children.concat [
  Psych::Nodes::Scalar.new("primary"),
  mapping,
  Psych::Nodes::Scalar.new(name),
  Psych::Nodes::Alias.new(name),
]
```

When dealing with a three-tiered environment configuration, we can simply add the new database definition to the mapping:

```ruby
new_mapping = Psych::Nodes::Mapping.new
new_mapping.children.concat mapping.children
new_mapping.children.concat [
  Psych::Nodes::Scalar.new(name),
  Psych::Nodes::Alias.new(name),
]
```

In both cases we work with a new AST node, instead of mutating to the existing node, so that we can easily emit the YAML content for both the original and the new content. We can then replace the existing mapping with the new mapping in the YAML source via a simple find and replace. Putting it all together, the full `add_database` method looks like this:

```ruby
def add_database(name)
  root = @stream.children.first.root
  root.children.each_slice(2).map do |scalar, mapping|
    next unless scalar.is_a?(Psych::Nodes::Scalar)
    next unless mapping.is_a?(Psych::Nodes::Mapping)
    next unless mapping.anchor.nil? || mapping.anchor.empty?
    # skip if the environment already has the database definition
    next if mapping.children.each_slice(2).any? do |key, value|
      key.is_a?(Psych::Nodes::Scalar) && key.value == name && value.is_a?(Psych::Nodes::Alias) && value.anchor == name
    end

    new_mapping = Psych::Nodes::Mapping.new
    if mapping.children.first.value == "<<" # 2-tiered environment
      new_mapping.children.concat [
        Psych::Nodes::Scalar.new("primary"),
        mapping,
        Psych::Nodes::Scalar.new(name),
        Psych::Nodes::Alias.new(name),
      ]
    else # 3-tiered environment
      new_mapping.children.concat mapping.children
      new_mapping.children.concat [
        Psych::Nodes::Scalar.new(name),
        Psych::Nodes::Alias.new(name),
      ]
    end

    old_environment_entry = emit_pair(scalar, mapping)
    new_environment_entry = emit_pair(scalar, new_mapping)

    [scalar.value, old_environment_entry, new_environment_entry]
  end.compact!
end
```

- - -

As you can see, simplifying the problem space and relying on the conventions of the `database.yml` file made this implementation approachable. Trying to account for every possible variation possible in generic YAML would have been a nightmare, to be frank. So, yes, we can't mutate any YAML content in any kind of way, but we can make the changes we needed in a sufficiently robust and resilient manner. And, it took far less time to implement than trying to tackle the problem in a generic way.

All totalled, we have built a `DatabaseYAML` class that can parse a YAML file or string, emit _partial_ YAML content, handle inline commented out lines in the YAML content, define new database configurations, and add them to the environment configurations in the YAML content. And, we did all of this without mutating the YAML AST directly. We used the AST as a read-only data structure and built new AST nodes to represent the changes we wanted to make, which we then emit as strings so that updates can be done more surgically as find and replace operations.

Hopefully some of the lessons and techniques will prove useful to you if you ever need to manipulate YAML content in a similar way. And, if you have any questions or comments, please feel free to reach out to me on Twitter at [@fractaledmind](https://twitter.com/fractaledmind?ref=fractaledmind.github.io). In following posts, we will turn from YAML parsing, to some other aspects of building a high-quality Rails application template script, like testing and configuration.
