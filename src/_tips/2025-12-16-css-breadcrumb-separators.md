---
series: Stylish HTML
title: "Breadcrumb separators with <code>::after</code>"
date: 2025-12-16
tags:
  - code
  - css
typefully_published: true
---

Breadcrumb separators belong in CSS, not HTML. Using [`::after`](https://developer.mozilla.org/en-US/docs/Web/CSS/::after) pseudo-elements keeps your markup semantic and makes separators trivial to change globally.

```html
<nav aria-label="Breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/products">Products</a></li>
    <li><a href="/products/widgets">Widgets</a></li>
  </ol>
</nav>
```

```css
nav > ol {
  display: flex;
}

nav > ol > li:not(:last-child)::after {
  content: " / ";
  color: #9ca3af;
  padding: 0 0.5em;
}
```

The `:not(:last-child)` selector ensures no trailing separator after the final item.

Want different separators? Just change the `content` value:

```css
/* Chevron */
li:not(:last-child)::after {
  content: " › ";
}

/* Arrow */
li:not(:last-child)::after {
  content: " → ";
}

/* Pipe */
li:not(:last-child)::after {
  content: " | ";
}
```

For icon separators, use a background image instead:

```css
li:not(:last-child)::after {
  content: "";
  width: 1em;
  height: 1em;
  background: url("data:image/svg+xml,...") center / contain no-repeat;
}
```

This pattern works for any horizontal list needing separators—breadcrumbs, tag lists, or inline metadata.
