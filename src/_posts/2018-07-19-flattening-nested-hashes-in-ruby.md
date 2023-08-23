---
title: Flattening Nested Hashes in Ruby
date: 2018-07-19
tags:
  - code
  - ruby
---

Sometimes, especially when working with external data, you will be handed a thickly nested blob of JSON, represented in Ruby as a nested hash. I have found in my experience that processing this data is often simpler when we can work with a flat hash instead, collapsing the key paths into a simple array key. And so, I wrote a function that does just this -- it flattens a nested hash into a flat hash.

Before we turn to the code, let's consider some examples. Imagine we have a simple nested hash like this:

```ruby
  {
    key: 'value',
    nested: {
      key: 'nested_value'
    },
    array: [
      0,
      1,
      2
    ]
  }
```

What we want is a function, let's call it `flatten_keys_of`, that will return a hash like this:

```ruby
  {
    [:key]=>"value",
    [:nested, :key]=>"nested_value",
    [:array]=>[0, 1, 2]
  }
```

So, `flatten_keys_of` returns a flat hash where all nested keys are flattened into an array of keys.

However, I want to add an additional degree of freedom. Let's ensure that users can also pass a `Proc` to change how nested keys are flattened:

```ruby
  flatten_keys_of(hash, flattener: ->(*keys) { keys.join('.') })
  => { "key"=>"value", "nested.key"=>"nested_value", "array"=>[0, 1, 2] }
  flatten_keys_of(hash, flattener: ->(*keys) { keys.join('-') })
  => { "key"=>"value", "nested-key"=>"nested_value", "array"=>[0, 1, 2] }
  flatten_keys_of(hash, flattener: ->(*keys) { keys.map(&:to_s).reduce { |memo, key| memo + "[#{key}]" } })
  => { "key"=>"value", "nested[key]"=>"nested_value", "array"=>[0, 1, 2] }
```

Finally, I want to ensure that users can also determine if array values should be flattened as well:

```ruby
  hash = { person: { age: '28', siblings: ['Tom', 'Sally'] } }
  flatten_keys_of(hash, flatten_arrays: true)
  => { [:key]=>"value", [:nested, :key]=>"nested_value", [:array, 0]=>0, [:array, 1]=>1, [:array, 2]=>2 }
  flatten_keys_of(hash, flattener: ->(*keys) { keys.join('.') }, flatten_arrays: true)
  => { "key"=>"value", "nested.key"=>"nested_value", "array.0"=>0, "array.1"=>1, "array.2"=>2 }
```

To my mind, this is the basic flexibility that a hash flattener would need. So, how do we build it?

Luckily, as is nearly always the case, we can find a solid starting point on StackOverflow. In this case, I looked up "how to flatten a hash in Ruby" and eventually found this gem: https://stackoverflow.com/a/23861946/2884386

This solution looks like so:

```ruby
def flat_hash(h,f=[],g={})
  return g.update({ f=>h }) unless h.is_a? Hash
  h.each { |k,r| flat_hash(r,f+[k],g) }
  g
end
```

I wanted to tweak a few different things. Firstly, I like longer (and to me, clearer) variable names. I also wanted to add the two additional features described above. So, without further adieu, here is my implementation of `flatten_keys_of`:

```ruby
def flatten_keys_of(input, keys = [], output = {}, flattener: ->(*k) { k }, flatten_arrays: false)
  if input.is_a?(Hash)
    input.each do |key, value|
      flatten_keys_of(
        value,
        keys + Array[key],
        output,
        flattener: flattener,
        flatten_arrays: flatten_arrays
      )
    end
  elsif input.is_a?(Array) && flatten_arrays
    input.each_with_index do |value, index|
      flatten_keys_of(
        value,
        keys + Array[index],
        output,
        flattener: flattener,
        flatten_arrays: flatten_arrays
      )
    end
  else
    return output.merge!(flattener.call(*keys) => input)
  end

  output
end
```

It is a relatively simple recursive function. We build up an internal array of `keys` while constructing an internal `output` hash. We recurse if dealing with a `Hash` value or an `Array` value when `flatten_arrays` is true. We flatten the keys using the `flattener` proc and construct our `output` hash.

I have used this method across a number of projects, and it has served me well. Maybe it will prove useful to you as well.