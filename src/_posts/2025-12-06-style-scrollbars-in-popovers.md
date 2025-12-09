---
series: Stylish HTML
title: "De-emphasize scrollbars in small containers"
date: 2025-12-06
tags:
  - code
  - css
---

Have a small scroll container where you want to de-emphasize the scrollbar, like in a popover? Say hello to [`scrollbar-color`](https://developer.mozilla.org/en-US/docs/Web/CSS/scrollbar-color) and [`scrollbar-width`](https://developer.mozilla.org/en-US/docs/Web/CSS/scrollbar-width).

```css
::picker(select) {
  scrollbar-color: lightgray transparent;
  scrollbar-width: thin;
}
```

The `scrollbar-color` property sets the thumb and track colors (here, light gray on transparent), while `scrollbar-width` can be set to `thin` for a more subtle appearance.

Demo:

<img src="{{ '/images/scrollbar-styling.gif' | relative_url }}" alt="A select dropdown with a subtle, thin scrollbar" style="width: 100%" />



- - -

## All posts in this series

* [Avoid layout shift with `scrollbar-gutter: stable`]({% link _posts/2025-12-03-scrollbar-gutter-stable.md %})
* [Prevent scrolling when a dialog is open]({% link _posts/2025-12-04-prevent-scroll-with-dialog-modal.md %})
* [Anchor popovers without distinct anchor names]({% link _posts/2025-12-05-anchor-popovers-with-attr.md %})
* {:.bg-[var(--tw-prose-bullets)]}[De-emphasize scrollbars in small containers]({% link _posts/2025-12-06-style-scrollbars-in-popovers.md %})
* [Auto-growing textareas with `field-sizing: content`]({% link _posts/2025-12-07-auto-growing-textareas.md %})
* [Dialog cancel buttons with `formmethod="dialog"`]({% link _posts/2025-12-08-dialog-cancel-buttons-with-formmethod.md %})
* [Dialog close buttons with `command="close"`]({% link _posts/2025-12-09-dialog-close-button-with-command.md %})
