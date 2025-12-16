---
series: Stylish HTML
title: "Anchor Popovers without distinct Anchor Names"
date: 2025-12-05
tags:
  - code
  - css
typefully_published: true
---

Double-dashed IDs and the enhanced [`attr()`](https://developer.mozilla.org/en-US/docs/Web/CSS/attr) CSS function allow us to bind `popovertarget`s with their `popover`s without having to create distinct [`anchor-name`](https://developer.mozilla.org/en-US/docs/Web/CSS/anchor-name)s.

```html
<button popovertarget="--dropdown-example"></button>
<div id="--dropdown-example" popover></div>
```

```css
[popovertarget] {
  /* Dynamically generate anchor-name from the popovertarget attribute value */
  anchor-name: attr(popovertarget type(<custom-ident>));
}

[popover] {
  /* Dynamically bind to anchor using the menu's id attribute */
  position-anchor: attr(id type(<custom-ident>));

  /* Position at bottom of anchor, aligned to left edge */
  top: anchor(bottom);
  left: anchor(left);
}
```

The key insight is using `attr()` with `type(<custom-ident>)` to dynamically read attribute values as CSS identifiers. This lets you use the same ID value for both the `popovertarget` attribute and the `anchor-name`/`position-anchor` properties.

Demo:

<img src="{{ '/images/dropdown-anchored.gif' | relative_url }}" alt="A dropdown popover anchored to a button, positioned at the bottom-left edge" style="width: 100%" />
