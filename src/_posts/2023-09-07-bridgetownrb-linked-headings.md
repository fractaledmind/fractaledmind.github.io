---
title: Linked headings in your BridgetownRB site
date: 2023-09-07
tags:
  - code
  - ruby
  - bridgetown
---

[BridgetownRB](https://www.bridgetownrb.com) is a powerful and flexible "progressive site generator" written in Ruby. I use it to publish this blog. One feature that I wanted to support with my blog is having headings that provide a quick anchor link to that section of the page. In this post, I want to walk you through the simple steps to add this feature to a Bridgetown site.

<!--/summary-->

- - -

Before we jump into the code, let's ensure that we are all on the same page about the feature we are building. I want headings to behave like this:

<figure>
  <img src="{{ '/images/linked-headers.gif' | relative_url }}" alt="A video of a heading in a website that reveals a # on hover which is an anchor link to that particular heading" class="p-2" />
</figure>

That is, I want headings that reveal a `#` on hover which is an anchor link to that particular section of the page. This is common interaction, perhaps most commonly seen in GitHub README's.

With its [plugin system](https://www.bridgetownrb.com/docs/plugins), Bridgetown is easy to extend. In our case, we want to create a plugin that will inspect and manipulate the generated HTML of a page. Bridgetown provides the [Inspector API](https://www.bridgetownrb.com/docs/plugins/inspectors) for precisely this use-case.

To create a local plugin, all we need to do is create a new Ruby file in the `/plugins/builders` directory. Following the Bridgetown convention, we will name our inspector plugin class `Builders::Inspectors`:

```ruby
# /plugins/builders/inspectors.rb
class Builders::Inspectors < SiteBuilder
  def build
    inspect_html do |document|
      # ...
    end
  end
end
```

Bridgetown will automatically load this plugin when it runs, so this is literally all we need to do in order to get our plugin setup and used. The only thing left is to write the logic for manipulating our headings.

The `inspect_html` method that Bridgetown provides yields a [`Nokogiri`](https://nokogiri.org/) `document` object to our block. We can use the [`#css`](https://nokogiri.org/rdoc/Nokogiri/XML/Searchable.html#method-i-css) method to find our page headings. In our case, we only want content headings, which means we only want headings under the `<main>` tag and only non-`<h1>` headings. Moreover, we can only link to a heading if it has an `id` attribute. So, we need a CSS selector like so: `main h2[id],h3[id],h4[id],h5[id],h6[id]`. This finds precisely the headings we are after. For each heading, we then simply want to append an `<a>` tag with an `href` that points to the anchor link for that heading's `id`. Let's write this up in Ruby:

```ruby
class Builders::Inspectors < SiteBuilder
  def build
    inspect_html do |document|
      document.css("main h2[id],h3[id],h4[id],h5[id],h6[id]").each do |heading|
        heading << %(
          <a href="##{heading[:id]}" class="anchor" aria-hidden="true">#</a>
        )
      end
    end
  end
end
```

We add the `.anchor` class to allow us to style this `#` as we desire and the `aria-hidden="true"` attribute to remove this link from the accessibility tree, since this link provides no utility to screen readers.

With our anchor links appended to our headings, we only need to style the interaction. We want the `#` to be visually hidden by default, only shown when hovering the heading, and to not have the standard link underline text. This can be accomplished with the following CSS:

```css
[aria-hidden="true"] {
  visibility: hidden;
}

.anchor {
  text-decoration: none;
}

h2:hover .anchor,
h3:hover .anchor,
h4:hover .anchor,
h5:hover .anchor,
h6:hover .anchor {
  visibility: visible;
}
```

Nothing too fancy or complicated, but it gets the job done. Add this CSS to your `/frontend/styles/index.css` file, or some component file imported into `index.css` and you are good to go.

These two additions are all you need to setup linked headings in your current or next Bridgetown site. If you enjoyed this tip, please do reach out on Twitter [@fractaledmind](http://twitter.com/fractaledmind?ref=fractaledmind.github.io).

> You can find the files we have written throughout this post in [this Gist](https://gist.github.com/fractaledmind/7b52e7e84b396780dcb99f5e0c81f4e6)