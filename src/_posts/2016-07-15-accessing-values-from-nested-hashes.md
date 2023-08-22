---
layout: post
title: Accessing Values from Nested Hashes
description: How can you access values from a nested (i.e. multidimensional) hash without throwing errors when the shape of the hash is not strictly fixed?
image: null
published_time: 2016-07-15
modified_time: null
author: Stephen Margheim
tags:
  - code
  - ruby
---

<p>I need a function that will allow me to access values from a nested (i.e. multidimensional) hash. However, the shape of the hash is not strictly fixed.</p>

<p>If you knew the keypath already (i.e. you didn&#39;t need it to be a param that was passed into a function), the oldest standard way to achieve this in Ruby is:</p>

```ruby
  hash[:path] && hash[:path][:to] && hash[:path][:to][:key]
```

<p>If you wanted to take that approach and put it into a method, you could use <code>Enumerable#reduce</code> to work with the keypath&#39;s array:</p>

```ruby
  def access(hash, keypath)
    keypath.reduce(hash) { |memo, key| memo && memo[key] }
  end
```

<p>Starting in Ruby 2.3, the <code data-language='ruby'>Hash</code> class actually added a method that does essentially this. <code data-language='ruby'>Hash#dig</code> takes a keypath and will access the value:</p>

```ruby
  hash.dig(:path, :to, :key)
```

<p>So, we could rewrite our function to use <code data-language='ruby'>Hash#dig</code> like so:</p>

```ruby
  def access(hash, keypath)
    hash.dig(*keypath)
  end
```

<p>That is both clean and uses modern Ruby semantics; however, it is not without its limitations. Let&#39;s consider the following 2 hashes:</p>

```ruby
  hash1 = {
    path: {
      to: {
        key: 'value'
      }
    }
  }
  hash2 = {
    path: {
      to: 'key'
    }
  }
```

<p>And let&#39;s also consider the following three keypaths:</p>

```ruby
  keypath1 = %i[path to key]
  keypath2 = %i[path to nested key]
  keypath3 = %i[path to key then another]
```

<p>What will happen in these six scenarios?</p>

```ruby
  access(hash1, keypath1)
  access(hash1, keypath2)
  access(hash1, keypath3)
  access(hash2, keypath1)
  access(hash2, keypath2)
  access(hash2, keypath3)
```

<hr>

<p>Well, here&#39;s the answer:</p>

```irb
  > access(hash1, keypath1)
  => "value"
  > access(hash1, keypath2)
  => nil
  > access(hash1, keypath3)
  TypeError: String does not have #dig method
  > access(hash2, keypath1)
  TypeError: String does not have #dig method
  > access(hash2, keypath2)
  TypeError: String does not have #dig method
  > access(hash2, keypath3)
  TypeError: String does not have #dig method
```

<p>Scenario 1 makes sense. The hash has those keys defined in that structure, so the value is accessed.</p>

<p>Scenario 2 also makes sense. The subhash returned from <code>hash[:path][:to]</code> does <em>not</em> have the key <code data-language='ruby'>:nested</code>, so a <code data-language='ruby'>nil</code> is returned.</p>

<p>But each of the other 4 scenarios throw this <code data-language='ruby'>TypeError</code>. First, let&#39;s answer why.</p>

<p>You can get this error simply. Call <code data-language='ruby'>&#39;foo&#39;.dig(:key)</code>. We recall that <code data-language='ruby'>dig</code> is an instance method on the <code data-language='ruby'>Hash</code> class. It is not an instance method on the <code>String</code> class. Thus, when we try to call that method on an instance of <code data-language='ruby'>String</code>, we get this error.</p>

<p>This error is being thrown in our final four scenarios because as soon as we hit a scalar value (a string in these cases), the implicit chained call to <code data-language='ruby'>dig</code> on that value throws the error. I say that it is the &quot;implicit chained call to <code data-language='ruby'>dig</code>&quot; because the <code data-language='ruby'>Hash#dig</code> method is implemented recursively.</p>

<p>So, the way <code data-language='ruby'>Hash#dig</code> works is that it will return a <code data-language='ruby'>nil</code> if it encounters a key that is not present in the current (sub-)hash that it is processing; however, if it encounters a key that <em>is present</em>, but that returns a scalar value, it will blow up.</p>

<hr>

<p>We need a function that won&#39;t blow up. We need a function that <em>either</em> returns the value <em>or</em> returns <code data-language='ruby'>nil</code>.</p>

<p>Maybe our original implementation of <code data-language='ruby'>access</code> would work?</p>

```ruby
  def access(hash, keypath)
    keypath.reduce(hash) { |memo, key| memo && memo[key] }
  end
```

```irb
  > access(hash1, keypath1)
  => "value"
  > access(hash1, keypath2)
  => nil
  > access(hash1, keypath3)
  TypeError: no implicit conversion of Symbol into Integer
  > access(hash2, keypath1)
  TypeError: no implicit conversion of Symbol into Integer
  > access(hash2, keypath2)
  TypeError: no implicit conversion of Symbol into Integer
  > access(hash2, keypath3)
  TypeError: no implicit conversion of Symbol into Integer
```

<p>Not quite (I leave the explanation of this error to the reader).</p>

<p>Using <code data-language='ruby'>Hash#fetch</code> instead of <code data-language='ruby'>Hash#dig</code> gives us a similar problem:</p>

```ruby
  def access(hash, keypath)
    keypath.reduce(hash) { |memo, key| memo.fetch(key, {}) }
  end
```

```irb
  > access(hash1, keypath1)
  => "value"
  > access(hash1, keypath2)
  => {}
  > access(hash1, keypath3)
  NoMethodError: undefined method `fetch' for "value":String
  > access(hash2, keypath1)
  NoMethodError: undefined method `fetch' for "key":String
  > access(hash2, keypath2)
  NoMethodError: undefined method `fetch' for "key":String
  > access(hash2, keypath3)
  NoMethodError: undefined method `fetch' for "key":String
```

<p>Clearly, what we need is a way to tentatively call the method; and ActiveSupport&#39;s <code data-language='ruby'>Object#try</code> fits the bill nicely. So, let&#39;s try pairing <code data-language='ruby'>Object#try</code> with <code data-language='ruby'>Hash#dig</code>:</p>

```ruby
  def access(hash, keypath)
    keypath.reduce(hash) { |memo, key| memo.try(:dig, key) }
  end
```

```irb
  > access(hash1, keypath1)
  => "value"
  > access(hash1, keypath2)
  => nil
  > access(hash1, keypath3)
  => nil
  > access(hash2, keypath1)
  => nil
  > access(hash2, keypath2)
  => nil
  > access(hash2, keypath3)
  => nil
```

<p>Success!</p>

<p>When you need to attempt to access a value from a nested/multidimensional hash given a keypath that may or may not match the shape of the hash, try and dig.</p>
