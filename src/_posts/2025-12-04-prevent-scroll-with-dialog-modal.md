---
series: Stylish HTML
title: "Prevent Scrolling when a Dialog is open"
date: 2025-12-04
tags:
  - code
  - css
---

Want to prevent scrolling when a modal dialog is open? Use the [`:modal`](https://developer.mozilla.org/en-US/docs/Web/CSS/:modal) pseudo-class with `body:has()` to disable scrolling purely in CSS—no JavaScript needed.

```css
body:has(dialog:modal) {
  overflow: hidden;
}
```

Demo:

<img src="{{ '/images/dialog-open-prevent-scroll.gif' | relative_url }}" alt="A modal dialog opens and the page behind it cannot be scrolled" style="width: 100%" />

The `:modal` pseudo-class matches elements that are in a state where they exclude all interaction with elements outside of it until the interaction has been dismissed. This includes dialogs opened with `showModal()`.



- - -

## All posts in this series

* [Avoid layout shift with `scrollbar-gutter: stable`]({% link _posts/2025-12-03-scrollbar-gutter-stable.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Prevent scrolling when a dialog is open]({% link _posts/2025-12-04-prevent-scroll-with-dialog-modal.md %})
* [Anchor popovers without distinct anchor names]({% link _posts/2025-12-05-anchor-popovers-with-attr.md %})
* [De-emphasize scrollbars in small containers]({% link _posts/2025-12-06-style-scrollbars-in-popovers.md %})
* [Auto-growing textareas with `field-sizing: content`]({% link _posts/2025-12-07-auto-growing-textareas.md %})
* [Dialog cancel buttons with `formmethod="dialog"`]({% link _posts/2025-12-08-dialog-cancel-buttons-with-formmethod.md %})
* [Dialog close buttons with `command="close"`]({% link _posts/2025-12-09-dialog-close-button-with-command.md %})
* [Light dismiss dialogs with `closedby`]({% link _posts/2025-12-10-dialog-light-dismiss-with-closedby.md %})
