---
series: Stylish HTML
title: "Auto-growing textareas with <code>field-sizing: content</code>"
date: 2025-12-07
tags:
  - code
  - css
---

Coming in the next version of Safari, and already in Chrome and Edge, you can now create `<textarea>`s that auto-grow with the [`field-sizing: content`](https://developer.mozilla.org/en-US/docs/Web/CSS/field-sizing) rule.

```css
textarea {
  field-sizing: content;
  min-block-size: attr(rows rlh);
}
```

The `min-block-size: attr(rows rlh)` ensures the textarea still respects its `rows` attribute as a minimum height, using the `rlh` unit (root line height).

Demo:

<img src="{{ '/images/field-sizing-content.gif' | relative_url }}" alt="A textarea that automatically grows as the user types more content" style="width: 100%" />



- - -

## All posts in this series

* [Avoid layout shift with `scrollbar-gutter: stable`]({% link _posts/2025-12-03-scrollbar-gutter-stable.md %})
* [Prevent scrolling when a dialog is open]({% link _posts/2025-12-04-prevent-scroll-with-dialog-modal.md %})
* [Anchor popovers without distinct anchor names]({% link _posts/2025-12-05-anchor-popovers-with-attr.md %})
* [De-emphasize scrollbars in small containers]({% link _posts/2025-12-06-style-scrollbars-in-popovers.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Auto-growing textareas with `field-sizing: content`]({% link _posts/2025-12-07-auto-growing-textareas.md %})
* [Dialog cancel buttons with `formmethod="dialog"`]({% link _posts/2025-12-08-dialog-cancel-buttons-with-formmethod.md %})
* [Dialog close buttons with `command="close"`]({% link _posts/2025-12-09-dialog-close-button-with-command.md %})
* [Light dismiss dialogs with `closedby`]({% link _posts/2025-12-10-dialog-light-dismiss-with-closedby.md %})
