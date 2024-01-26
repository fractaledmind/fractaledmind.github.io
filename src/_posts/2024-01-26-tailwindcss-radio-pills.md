---
title: Radio Pills with Tailwind
date: 2024-01-26
tags:
  - code
  - tailwind
  - til
---

<img src="{{ '/images/tailwind-radio-pills.png' | relative_url }}" alt="" style="width: 100%" />

Here is a quick tip on building "radio pills" with [TailwindCSS](http://tailwindcss.com/), inspired by [Scott O'Hara's brilliant work](https://scottaohara.github.io/a11y_styled_form_controls/src/radio-button--pill/). The goal here is to make an accessible form element that also has visual polish and purpose.[^1]

<!--/summary-->

- - -

This won't be like a recipe on some blog, where I drone on and on for paragraphs about my childhood. Here's the CodePen, enjoy:

<p class="codepen" data-height="300" data-default-tab="html,result" data-slug-hash="xxydrNj" data-user="smargh" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/smargh/pen/xxydrNj">
  Tailwind CSS - Radio Pills</a> by Stephen Margheim (<a href="https://codepen.io/smargh">@smargh</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>

And, if you want to apply this to a Rails form, here's the basic idea:

```erb
<fieldset class="inline-block whitespace-nowrap p-px border-2 rounded-full focus-within:outline focus-within:outline-blue-400">
  <%= form.collection_radio_buttons(:attribute, ["Option 1", "Option 2"], :itself, :itself) do |builder| %>
    <span class="relative inline-block">
      <%= builder.radio_button class: "sr-only peer" %>
      <%= builder.label(class: "border-2 border-transparent rounded-full block py-1 px-2 peer-checked:bg-blue-500 peer-checked:text-white hover:bg-blue-200 hover:border-blue-500") %>
    </span>
  <% end %>
</fieldset>
```

- - -

[^1]: If you want to explore more styled form controls that are still well-structured and accessible, Scott has [a wonderful collection](https://scottaohara.github.io/a11y_styled_form_controls/) that is well worth your time.
