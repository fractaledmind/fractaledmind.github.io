---
title: Building Pure CSS Trees (<em>part 5</em>)
date: 2018-03-09
tags:
  - code
  - tutorial
  - css
  - trees
---

After the first 4 parts of our series, we have some flexible (S)CSS that will render nested lists as trees. It can render [horizontal trees]({% link _posts/2018-03-05-css-tree.md %}), [vertical trees]({% link _posts/2018-03-06-css-tree-vertical.md %}), [trees going from top-to-bottom or bottom-to-top, left-to-right or right-to-left]({% link _posts/2018-03-07-css-tree-inverses.md %}) , and even [bracket-style centered trees]({% link _posts/2018-03-08-css-tree-centered.md %}).

All of this flexibility (and the SCSS code) can be seen in this comprehensive demo:

<p data-height="1000" data-theme-id="0" data-slug-hash="WzGeVo" data-default-tab="result" data-user="smargh" data-embed-version="2" data-pen-title="css-trees" class="codepen">See the Pen <a href="https://codepen.io/smargh/pen/WzGeVo/">css-trees</a> by Stephen Margheim (<a href="https://codepen.io/smargh">@smargh</a>) on <a href="https://codepen.io">CodePen</a>.</p>

- - -

This covers the basic needs of rendering trees, but I thought it might be fun to experiment a little with some edge cases.

The first experiment that came to mind was rendering a nested list as a "folder-style" list:

<p data-height="520" data-theme-id="0" data-slug-hash="vPraeq" data-default-tab="result" data-user="smargh" data-embed-version="2" data-pen-title="css-trees__stacked" class="codepen">See the Pen <a href="https://codepen.io/smargh/pen/vPraeq/">css-trees__stacked</a> by Stephen Margheim (<a href="https://codepen.io/smargh">@smargh</a>) on <a href="https://codepen.io">CodePen</a>.</p>

This is an alteration, primarily, of the `.-vertical` modifier. Fundamentally, we use that foundation, set `align-items: start` on the `li` selector and style the _child-to-parent_ connector, the _sibling-to-sibling_ selector, and the _sibling-to-sibling:last-child_ selector.

As with all of these demos, I haven't extracted out the "magic numbers" into variables; though I have made sure to keep things consistent such that this shouldn't be too difficult as an exercise for the reader.

- - -

Another fun experiment was to see if I could mix _horizontal_ and _vertical_ orientations for sub-trees. This is likely easier to understand by looking at the demo:

<p data-height="520" data-theme-id="0" data-slug-hash="BryNRx" data-default-tab="result" data-user="smargh" data-embed-version="2" data-pen-title="css-trees__mixed__1" class="codepen">See the Pen <a href="https://codepen.io/smargh/pen/BryNRx/">css-trees__mixed__1</a> by Stephen Margheim (<a href="https://codepen.io/smargh">@smargh</a>) on <a href="https://codepen.io">CodePen</a>.</p>

In this first demo, the tree is _primarily_ in the **horizontal** orientation, so both `1.1` and `1.2` are laid out as we would expect for the `.-horizontal` modifier. The wrinkle comes when we throw the `.-vertical` modifier on `1.3` and `1.3` only. Here, we want the `1.3` sub-tree to render itself in a **vertical** orientation.

Interestingly, getting the modifiers to work on sub-trees immediately works for bi-directional trees as well:

<p data-height="520" data-theme-id="0" data-slug-hash="VwqLxBE" data-default-tab="result" data-user="smargh" data-embed-version="2" data-pen-title="css-trees__mixed__2" class="codepen">See the Pen <a href="https://codepen.io/smargh/pen/VwqLxBE/">css-trees__mixed__2</a> by Stephen Margheim (<a href="https://codepen.io/smargh">@smargh</a>) on <a href="https://codepen.io">CodePen</a>.</p>

As always, check out the (S)CSS in the CodePen to dig more into the details. And, if you have any questions, feel free to reach out to me on Twitter <a href="http://twitter.com/fractaledmind?ref=fractaledmind.github.io">@fractaledmind</a>. As you might have gathered, I think building tree structures with CSS is super-dope, so I'm always down to talk more about it.

- - -

Well, that's it for this series on CSS trees. I genuinely hope you enjoyed it and found something interesting. As always, more to come.

- - -

## All posts in this series

* [Part 1 — horizontally oriented trees]({% link _posts/2018-03-05-css-tree.md %})
* [Part 2 — vertically oriented trees]({% link _posts/2018-03-06-css-tree-vertical.md %})
* [Part 3 — inverse directions]({% link _posts/2018-03-07-css-tree-inverses.md %})
* [Part 4 — centered trees]({% link _posts/2018-03-08-css-tree-centered.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Part 5 — tree experiments]({% link _posts/2018-03-09-css-tree-experiments.md %})
