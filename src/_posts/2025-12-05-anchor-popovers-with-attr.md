---
series: Stylish HTML
title: "Anchor Popovers without distinct Anchor Names"
date: 2025-12-05
tags:
  - code
  - css
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



- - -

## All posts in this series

* [Avoid layout shift with `scrollbar-gutter: stable`]({% link _posts/2025-12-03-scrollbar-gutter-stable.md %})
* [Prevent scrolling when a dialog is open]({% link _posts/2025-12-04-prevent-scroll-with-dialog-modal.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Anchor popovers without distinct anchor names]({% link _posts/2025-12-05-anchor-popovers-with-attr.md %})
* [De-emphasize scrollbars in small containers]({% link _posts/2025-12-06-style-scrollbars-in-popovers.md %})
* [Auto-growing textareas with `field-sizing: content`]({% link _posts/2025-12-07-auto-growing-textareas.md %})
* [Dialog cancel buttons with `formmethod="dialog"`]({% link _posts/2025-12-08-dialog-cancel-buttons-with-formmethod.md %})
* [Dialog close buttons with `command="close"`]({% link _posts/2025-12-09-dialog-close-button-with-command.md %})
* [Light dismiss dialogs with `closedby`]({% link _posts/2025-12-10-dialog-light-dismiss-with-closedby.md %})
