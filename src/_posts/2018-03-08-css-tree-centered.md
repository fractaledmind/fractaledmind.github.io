---
title: Building Pure CSS Trees (<em>part 4</em>)
date: 2018-03-08
tags:
  - code
  - tutorial
  - css
  - trees
---

The last we left our pure-CSS tree component, it could render both [horizontally oriented]({% link _posts/2018-03-05-css-tree.md %}) as well as [vertically oriented]({% link _posts/2018-03-06-css-tree-vertical.md %}) _as well as_ the [inverse direction]({% link _posts/2018-03-07-css-tree-inverses.md %}) for either. With each orientation now capable of being rendered in either direction, might we be able to build a tree component that could put the root node in the center of the graph and have half of the descendant graph render to left and have to the right (for the horizontal orientation) or half to the top and half to the bottom (for the vertical orientation)? 

I will be honest, I was actually pleasantly surprised at how simple this was. Our foundation is solid, so there is little we need to add. Let's start with the vertical tree first this time. We want to add a `.-centered` modifier that will work in conjunction with the `.-vertical` modifier to create a bi-directional vertical tree.

In the HTML structure, our centered tree will need to only have on child `<li>` of our outermost `<ul>`, which will be the center of the tree. If we start simply with the (S)CSS we have right now and update our HTML structure, we get this:

<p data-height="300" data-theme-id="0" data-slug-hash="MWZwvMv" data-default-tab="result" data-user="smargh" data-embed-version="2" data-pen-title="css-tree-vertical-centered__1" class="codepen">See the Pen <a href="https://codepen.io/smargh/pen/MWZwvMv/">css-tree-vertical-centered__1</a> by Stephen Margheim (<a href="https://codepen.io/smargh">@smargh</a>) on <a href="https://codepen.io">CodePen</a>.</p>

Our first two children (`1.1` and `1.2`) look connected properly, but the next two children (`1.3` and `1.4`) are hanging out at the bottom of the tree disconnected. What we want is to move the first two children to the top (invert their direction) and allow the second two children to connect at the bottom.

We start crafting our `.-centered` modifier by targeting our central node (`> li:only-child`) and then its last two children (`> ul:first-of-type:nth-last-child(2)`). We can then essentially bring in the inversion code:

<p data-height="300" data-theme-id="0" data-slug-hash="GRPJvVK" data-default-tab="result" data-user="smargh" data-embed-version="2" data-pen-title="css-tree-vertical-centered__2" class="codepen">See the Pen <a href="https://codepen.io/smargh/pen/GRPJvVK/">css-tree-vertical-centered__2</a> by Stephen Margheim (<a href="https://codepen.io/smargh">@smargh</a>) on <a href="https://codepen.io">CodePen</a>.</p>

`1.1` and `1.2` are now inverted, but are sitting at the bottom of the tree with our primary node (`1`) still at the top. We can focus next on reordering our sub-trees to get them flowing vertically in the correct order:

<p data-height="300" data-theme-id="0" data-slug-hash="RwEPLbX" data-default-tab="result" data-user="smargh" data-embed-version="2" data-pen-title="css-tree-vertical-centered__3" class="codepen">See the Pen <a href="https://codepen.io/smargh/pen/RwEPLbX/">css-tree-vertical-centered__3</a> by Stephen Margheim (<a href="https://codepen.io/smargh">@smargh</a>) on <a href="https://codepen.io">CodePen</a>.</p>

This gets us very close, as we now only need to reorder our primary node label to put it in the middle

<p data-height="300" data-theme-id="0" data-slug-hash="WMqGBe" data-default-tab="result" data-user="smargh" data-embed-version="2" data-pen-title="css-tree-vertical-centered" class="codepen">See the Pen <a href="https://codepen.io/smargh/pen/WMqGBe/">css-tree-vertical-centered</a> by Stephen Margheim (<a href="https://codepen.io/smargh">@smargh</a>) on <a href="https://codepen.io">CodePen</a>.</p>

Wonderful! Our `.-vertical.-centered` combined implementation looks lovely.

I won't walk thru the steps, as they are functionally the same, for the horizontal direction. Instead, let's just marvel at the final result:

<p data-height="250" data-theme-id="0" data-slug-hash="zRVKWB" data-default-tab="result" data-user="smargh" data-embed-version="2" data-pen-title="css-tree-horizontal-centered" class="codepen">See the Pen <a href="https://codepen.io/smargh/pen/zRVKWB/">css-tree-horizontal-centered</a> by Stephen Margheim (<a href="https://codepen.io/smargh">@smargh</a>) on <a href="https://codepen.io">CodePen</a>.</p>

As always, inspect the SCSS tab in the CodePens to see the source code for this implementation.

In the next part of this journey, I want to look over all of our SCSS and refactor things to consolidate and simplify our code.

- - -

## All posts in this series

* [Part 1 — horizontally oriented trees]({% link _posts/2018-03-05-css-tree.md %})
* [Part 2 — vertically oriented trees]({% link _posts/2018-03-06-css-tree-vertical.md %})
* [Part 3 — inverse directions]({% link _posts/2018-03-07-css-tree-inverses.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Part 4 — centered trees]({% link _posts/2018-03-08-css-tree-centered.md %})
* [Part 5 — tree experiments]({% link _posts/2018-03-09-css-tree-experiments.md %})
