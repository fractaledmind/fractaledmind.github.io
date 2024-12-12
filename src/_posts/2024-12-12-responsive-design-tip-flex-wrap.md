---
series: Responsive Design Tips
title: "Always use <code>flex-wrap: wrap</code> on flex containers"
date: 2024-12-12
tags:
  - code
  - css
  - responsive-design
---

I spent a bit of time this morning make some [improvements]({% link _posts/2024-12-11-sqlite-directory-updates.md %}) to [sqlite.directory](https://sqlite.directory), and I found myself needing to make a number of fixes around the mobile responsiveness of the UI. So, I thought I would take a moment to catalog a few common patterns and tips I have found useful when working with responsive design. This first tip was one that I found myself using quite a bit today.

<!--/summary-->

- - -

I use flex containers a ton; I love them. But, I find myself overlooking the same responsive detail time and time again—I don't properly handle wrapping. Let's take a real example from the [sqlite.directory](https://sqlite.directory) header:

<p class="codepen" data-height="300" data-default-tab="result" data-slug-hash="raBMxRJ" data-user="smargh" style="width: 300px; height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/smargh/pen/raBMxRJ">
    responsive design tip: flex-wrap (before)</a> by Stephen Margheim (<a href="https://codepen.io/smargh">@smargh</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>

As you can see, on a smaller screen, the website title/logo and the user info are smashed together. Just ugly. I fixed this issue in [this commit](https://github.com/fractaledmind/sqlite.directory/commit/07a5a3d12ee4fc8945c120c0cff86ce5663282c3) where I made these two simple changes:

```html
<header class="w-full max-w-6xl mx-auto py-4 mb-4 text-lg flex justify-between items-center border-b"> <!-- [tl! remove:1] -->
  <h2 class="flex items-center gap-2">
<header class="w-full max-w-6xl mx-auto py-4 mb-4 text-lg flex justify-between items-center flex-wrap gap-y-2 border-b"> <!-- [tl! add:1] -->
  <h2 class="flex items-center gap-2 whitespace-nowrap">
    <%= link_to root_path, class: "group" do %>
      <%= image_tag "/icon.svg", class: "inline-block" %>
      <code class="">
        <span class="text-blue-500 group-hover:underline decoration-blue-500">sqlite</span>
        <span class="inline-block group-hover:animate-bouncing -mx-3">.</span>
        <span class="text-black group-hover:underline decoration-black">directory</span>
      </code>
    <% end %>
  </h2>

  <div class="inline-flex items-center gap-2"> <!-- [tl! remove] -->
  <div class="ml-auto inline-flex items-center gap-2"> <!-- [tl! add] -->
```

The result speaks for itself:

<p class="codepen" data-height="300" data-default-tab="result" data-slug-hash="raBMxoJ" data-user="smargh" style="width: 300px; height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/smargh/pen/raBMxoJ">
    responsive design tip: flex-wrap (after)</a> by Stephen Margheim (<a href="https://codepen.io/smargh">@smargh</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>

Let's break down the changes precisely:

1. Add `flex-wrap gap-y-2` to the `<header>` flex container
2. Add `whitespace-nowrap` to the `<h2>` containing the website title/logo
3. Add `ml-auto` to the `<div>` containing the user info

The first change is the most important. By adding `flex-wrap` to the flex container, we allow the children to wrap to the next line when the container is too small. This is a simple change that can make a big difference in the responsiveness of your UI.

Next, we simply manage the wrapping more elegantly. We tell the website title/logo to not wrap its text with `whitespace-nowrap`, and we tell the user info to always sit to the right with `ml-auto`.

All combined, we get a much more pleasant mobile experience. I hope this tip helps you as much as it has helped me. Happy coding!