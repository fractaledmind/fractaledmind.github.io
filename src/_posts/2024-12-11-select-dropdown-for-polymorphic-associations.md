---
title: Select dropdown for polymorphic associations
date: 2024-12-10
tags:
  - code
  - ruby
  - rails
---

When building a CRUD-oriented web application with Ruby on Rails, most things are pretty straightforward. Your tables, models, controllers, and views all naturally align, and you can lean on the Rails scaffolds. One gap, however, is dealing with polymorphic associations in your forms. Let's explore how [global IDs](https://github.com/rails/globalid) can provide us with a simple solution.

<!--/summary-->

- - -

For this blog post, let's consider building an app that has `Post`s that have polymorphic `content`, where a post's content can be either an `Article` or a `Video`.

We can scaffold such a resource with the Rails CLI:

```shell
bin/rails generate scaffold Post title:string! content:belongs_to{polymorphic}
```

This command will create a migration file like this:

```ruby
class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.belongs_to :content, polymorphic: true, null: false

      t.timestamps
    end
  end
end
```

And a model file like this:

```ruby
class Post < ApplicationRecord
  belongs_to :content, polymorphic: true
end
```

These both look great, and are how you should build [polymorphic associations](https://guides.rubyonrails.org/association_basics.html#polymorphic-associations). The issue arises when we view the scaffolded `_form` partial:

```erb
<%= form_with(model: post) do |form| %>
  <% if post.errors.any? %>
    <div style="color: red">
      <h2><%= pluralize(post.errors.count, "error") %> prohibited this post from being saved:</h2>

      <ul>
        <% post.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= form.label :title, style: "display: block" %>
    <%= form.text_field :title %>
  </div>

  <div> <!-- [tl! highlight:3] -->
    <%= form.label :content_id, style: "display: block" %>
    <%= form.text_field :content_id %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
```

This form is _not_ production-ready. We should never ask users to enter table IDs into forms. Were this a simple `belongs_to` association, I would always reach first for a [`form.collection_select`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormOptionsHelper.html#method-i-collection_select) and replace this `text_field` with something like:

```erb
<div>
  <%= form.label :content_id, style: "display: block" %>
  <%= form.collection_select(:content_id, Content.all, :id, :public_name, prompt: true) %>
</div>
```

With a polymorphic association like we have, however, this won't work because we don't have a single `Content` model. Yes, we could potentially reach for [delegated types](https://api.rubyonrails.org/classes/ActiveRecord/DelegatedType.html) instead of a polymorphic association, but sometimes a straight polymorphic association is what is best for the database schema. So, how can we build a simple yet elegant form experience for a polymorphic association?

I won't bury the lede; my answer is to reach for [global IDs](https://github.com/rails/globalid). Let me explain why. Simple means no (or very few) moving parts. I don't want two dependent `<select>`s, where the user first selects the type and then the second select only shows the subset of options that are of that type; that requires Javascript and that shouldn't be a requirement for a simple default. Elegant means easy to use and straightforward to build. Having one form field and a diff of no more than 10 lines of code is a good rule of thumb for elegance in this scenario. A solution built on top of global IDs allow me to build a simple and elegant solution.

Let's start with the form field. Instead of two dependent `<select>`s, let's build a single `<select>` with grouped options. This allows the user to clearly see that this is a polymorphic association as well as which type each option is. Here is the example of a grouped select from the [MDN docs on `optgroup`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/optgroup):

<div markdown="0">
  <label for="dino-select">Choose a dinosaur:</label>
  <select id="dino-select" style="color: black">
    <optgroup label="Theropods">
      <option>Tyrannosaurus</option>
      <option>Velociraptor</option>
      <option>Deinonychus</option>
    </optgroup>
    <optgroup label="Sauropods">
      <option>Diplodocus</option>
      <option>Saltasaurus</option>
      <option>Apatosaurus</option>
    </optgroup>
  </select>
</div>

Our list of options are grouped with non-selectable headers. Rails has a companion form helper for building such `<select>`s with the [`grouped_collection_select`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormOptionsHelper.html#method-i-grouped_collection_select) helper, which requires passing a single collection that can be nested via getter methods. The example in the docs are continents that have many countries each of which has many cities, so you can do `form.grouped_collection_select(:country_id, @continents, :countries, :name, :id, :name)`. With our polymorphic association, we can't easy get a single collection of all possible `content` values, so instead of using `grouped_collection_select`, we can drop down and use [`grouped_options_for_select`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormOptionsHelper.html#method-i-grouped_options_for_select) helper instead with our class `form.select`

```erb
<div>
  <%= form.label :content_gid, style: "display: block" %>
  <%= form.select(:content_gid,
        grouped_options_for_select(
          [
            [ 'Articles',
              Article
                .order(:title)
                .map { |it| [it.title, it.to_gid.to_s] } ],
            [ 'Videos',
              Video
                .order(:title)
                .map { |it| [it.title, it.to_gid.to_s] } ]
          ]
        )) %>
</div>
```

Here we build up our grouped options and pass that as the choices to the `form.select` helper. Our grouped options is a basic array of arrays, where each top-level array is a group. A group has first a string heading and then an inner array of choice tuples. This is where we turn to global IDs. A choice tuple takes a _label_ and then a _value_. The label is what is shown to users and the value is what is sent back to the server. Our values need to encode both the `id` and the `type` of this particular choice for the post's `content`. And this is precisely what global IDs provide us. As the [`globalid` docs](https://github.com/rails/globalid) state:

> A Global ID is an app wide URI that uniquely identifies a model instance:
>```
>gid://YourApp/Some::Model/id
>```
> This is helpful when you need a single identifier to reference different classes of objects.

By encoding both the class name and the ID, global IDs provide all of the information we need to set our polymorphic association. All we need is a new accessor on our model to get and set our association via global IDs:

```ruby
class Post < ApplicationRecord
  belongs_to :content, polymorphic: true

  def content_gid
    content&.to_gid
  end

  def content_gid=(gid)
    self.content = GlobalID::Locator.locate gid
  end
end
```

Easy enough! In addition to our `Post#content_id` accessor we add a `Post#content_gid` accessor whose getter returns the associated `content`'s global ID and whose setter takes a global ID and uses it to set the full `content` association.

So, instead of using a flat collection of choices in a `<select>` for a standard `belongs_to` association via the `content_id` field, when I am working with a _polymorphic_ association I reach for a grouped collection of choices via the `content_gid` field.

If you want to ensure that _every_ ActiveRecord model with a polymorphic `belongs_to` association has this `*_gid` accessor, you can add the following initializer to your Rails app:

```ruby
# config/initializers/polymorphic_belongs_to_gid.rb
ActiveSupport.on_load(:active_record) do
  module_parent.const_get('Associations::Builder::BelongsTo').class_eval do
    def self.define_accessors(model, reflection)
      super

      return unless reflection.polymorphic?

      mixin = model.generated_association_methods
      name = reflection.name

      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_gid
          public_send(:#{name})&.to_gid
        end

        def #{name}_gid=(global_id)
          value = GlobalID::Locator.locate global_id
          association(:#{name}).writer(value)
        end
      CODE
    end
  end
end
```

This patches Active Record's association builder to additionally define the `*_gid` accessors for polymorphic `belongs_to` associations. This way, you can always reach for `*_gid` accessors when working with polymorphic associations.
