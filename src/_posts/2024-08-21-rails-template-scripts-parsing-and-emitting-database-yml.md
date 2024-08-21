---
series: Rails Template Scripts
title: Parsing and emitting <code>database.yml</code>
date: 2024-08-21
tags:
  - code
  - ruby
  - yaml
  - rails
---

Recently, I have been working on [Rails application templates](https://guides.rubyonrails.org/rails_application_templates.html). These are scripts that can be run with `rails new` to enhance or extend the setup of a new Rails application with a specific configuration. They can also be ran against existing Rails applications using `rails app:template`. So, they are a powerful tool for automating certain kinds of configuration, modification, and setup tasks. But, there are also many limitations and stumbling blocks to what you can do with them.

In this series, I will be sharing some of the things I have learned while working on these scripts. This post is about the difficulty of manipulating the `database.yml` file. Let's jump into it.

<!--/summary-->

- - -

My template script needs to be able to make modifications to the application's `database.yml` file. And the work "modification" is key here. I need to react to the existing contents of the file, and make changes based on that. I'm not just replacing the file wholesale, and I'm not simply prepending or appending content. I need to make targeted changes. This proved to be more difficult than I naively anticipated.

Even in my initial naive mindset, I knew that I would not be able to rely on regular expressions. YAML is a complex format, and using regular expressions to parse it is a recipe for disaster. So, I knew I would need to parse the YAML into an AST, make changes to the AST, and then dump the AST back to a YAML string. But, this is where things got tricky.

Let's say I have a simple YAML file that looks like this:

```yaml
development:
  adapter: sqlite3
  timeout: 5000
```

If we use `YAML.parse` or `YAML.load_file`, we get back a Ruby hash. The [`yaml`](https://github.com/ruby/yaml) gem exclusively maps between Ruby objects and YAML strings. It does not provide a way to work with the AST directly. In order to get at the AST, we need to use the gem that `yaml` uses under the hood: [`psych`](https://github.com/ruby/psych).

Psych is a YAML "parser and emitter." This is precisely what we want. And because it is a dependency of Rails itself, we know that it will be available in any Rails application. So, we can use it in our template script.[^1]

[^1]: This is an important detail to keep in mind when writing Rails template scripts. You are limited to the gems that are guaranteed to be present in a Rails app. You cannot rely on _any_ external gems.

`Psych` does provide a way to work with the AST directly, but it is not very well documented. I had to explore and experiment to figure out how to parse some YAML into an AST, make changes to that AST, and then dump the AST back to a YAML string. I will save you the time and trouble. The only top-level AST object that can be dumped back to a YAML string is a `Psych::Nodes::Stream`. You get a stream object by parsing a YAML string with `Psych.parse_stream(string)`.

This stream object will have one child, which is a `Psych::Nodes::Document`. It is the document object that will have a `root` node. It is the children and descendents of the root node that represent the actual YAML content. So, if you want to make changes to the YAML content, you need to work with the root node of the document, which you can access with `stream.children.first.root`. I know it doesn't look pretty, but this is what it takes to get the actual YAML content in the AST.

Putting aside the actual manipulation of the AST for now, let's jump to dumping the AST back to a YAML string. Unfortunately, this was also convoluted. As I said, you can only dump a stream object. This means you can only dump full documents; you cannot dump partial documents. After exploring doing exclusively document mutations, I realized that this direction wouldn't work for my needs.

The Psych parser ignores all non-YAML content in the original file. This means that if you parse the full original YAML, mutate the AST, and then dump and replace, you lose all non-YAML content in the original, such as comments. This was a dealbreaker for me. I needed to retain the comments in the original file.

This meant that I needed to find a way to dump partial YAML content. Again, after a fair bit of exploring and experimenting, which I will spare you, I came up with this solution:

```ruby
def emit_pair(scalar, mapping)
  emission_stream = Psych::Nodes::Stream.new
  emission_document = Psych::Nodes::Document.new
  emission_mapping = Psych::Nodes::Mapping.new
  emission_mapping.children.concat [scalar, mapping]
  emission_document.children.concat [emission_mapping]
  emission_stream.children.concat [emission_document]
  emission_stream.yaml.gsub!(/^---/, '').strip!
end
```

This function takes a scalar node (an instance of `Psych::Nodes::Scalar`) that represents the key of a YAML "hash" and a mapping node (an instance of `Psych::Nodes::Mapping`) that represents the value of the hash. It then constructs a stream object with a document object that contains a mapping object with the scalar and mapping as children. It then dumps the stream to a YAML string, and removes the leading `---` marks the string as a YAML document. This way, you can dump just a key-value pair of a YAML hash.

With parsing and emitting in place, I thought I was in the home stretch. But, yet again, I was naive. I was originally only thinking of the comments at the top of the generated `database.yml` file, e.g.:

```yaml
# SQLite. Versions 3.8.0 and up are supported.
#   gem install sqlite3
#
#   Ensure the SQLite 3 gem is defined in your Gemfile
#   gem "sqlite3"
#
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
```

By only finding and replacing sections of the YAML, I can retain such comments. But, there can also be inline comments the file. There are two kinds of inline comments in YAML that I considered: comments at the end of a line and comments on their own line.

The first kind might look like this:

```yaml
default: &default
  adapter: sqlite3 # this is a comment
```

And the second kind might look like this:

```yaml
production:
  <<: *default
  # database: path/to/persistent/storage/production.sqlite3
```

I confess at the outset that I have not found a way to retain comments at the end of a line. But, I was able to retain comments on their own line. This was a bit of a hack, but it worked. The idea was to find such comment nodes in the original YAML string, replace it with the uncommented version of the string, store that change in some kind of cache, and then parse the string. Then, when emitting a partial, check if that partial has a change in the cache, and if it does, replace the uncommented node with the original commented node.

I created a Ruby class to manage this state and provide a clean interface for the template script:

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

We can implement a `#copy` method in our class to test that we can parse and emit YAML content with such an inline comment:

```ruby
class DatabaseYAML
  def copy
    ast = parse_yaml_with_comments(@yaml)
    root = ast.children.first.root
    root.children.each_slice(2).map do |scalar, mapping|
      emit_pair(scalar, mapping)
    end.join("\n")
  end

  # ...
end
```

You can test this with the following script in an IRB console if you'd like:

```ruby
yaml = <<~YAML
  production:
    <<: *default
    # database: path/to/persistent/storage/production.sqlite3
YAML
instance = DatabaseYAML.new(yaml)
copy = instance.copy
puts [yaml, copy]
```

This should output:

```ruby
["production:\n  <<: *default\n  # database: path/to/persistent/storage/production.sqlite3\n",
 "production:\n  <<: *default\n  # database: path/to/persistent/storage/production.sqlite3"]
```

And if you inspec the `@comment_cache` instance variable, you should see something like this:

```ruby
{"  database: path/to/persistent/storage/production.sqlite3"=>"  # database: path/to/persistent/storage/production.sqlite3"}
```

This is a quick demonstration that our "hack" is working. We could maybe do something similar for comments at the end of a line, but I haven't personally had a _need_ for that yet, so I haven't implemented it. But, I think it's possible.

After all of that, we finally have a way to parse and emit partial YAML content. By working with partial YAML content, we can leave comment blocks in place. Plus, our implementation is robust enough to handle one kind of inline comments.

- - -

I think this post is long enough, so I will stop here. I hope you found this post helpful. I will be writing more posts in this series on building powerful and robust Rails application template scripts. In the next post, I will continue building out this `DatabaseYAML` class to handle actual YAML AST manipulations. I will show you how to add, remove, and update key-value pairs in a YAML file.

As always, if you have any questions or comments, please feel free to reach out to me on Twitter at [@fractaledmind](https://twitter.com/fractaledmind?ref=fractaledmind.github.io). I'd love to hear from you.

Until next time, happy coding! 🚀
