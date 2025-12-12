---
series: Stylish HTML
title: "Dialog enter animations with <code>@starting-style</code>"
date: 2025-12-12
tags:
  - code
  - css
---

Want smooth fade-in animations when your `<dialog>` opens? The [`@starting-style`](https://developer.mozilla.org/en-US/docs/Web/CSS/@starting-style) CSS rule defines the initial state when an element first appears—no JavaScript needed.

```css
dialog {
  opacity: 1;
  scale: 1;
  transition: opacity 0.2s ease-out, scale 0.2s ease-out;

  @starting-style {
    opacity: 0;
    scale: 0.95;
  }
}
```

Without `@starting-style`, the browser renders the dialog immediately in its final state. With it, the browser starts from `opacity: 0; scale: 0.95` and transitions to `opacity: 1; scale: 1`.

You can animate the backdrop too:

```css
dialog::backdrop {
  background-color: rgb(0 0 0 / 0.5);
  transition: background-color 0.2s ease-out;

  @starting-style {
    background-color: rgb(0 0 0 / 0);
  }
}
```

Demo:

<img src="{{ '/images/dialog-starting-style.gif' | relative_url }}" alt="A dialog opening with a smooth fade-in and scale animation" style="width: 100%" />



- - -

## All posts in this series

* [Avoid layout shift with `scrollbar-gutter: stable`]({% link _posts/2025-12-03-scrollbar-gutter-stable.md %})
* [Prevent scrolling when a dialog is open]({% link _posts/2025-12-04-prevent-scroll-with-dialog-modal.md %})
* [Anchor popovers without distinct anchor names]({% link _posts/2025-12-05-anchor-popovers-with-attr.md %})
* [De-emphasize scrollbars in small containers]({% link _posts/2025-12-06-style-scrollbars-in-popovers.md %})
* [Auto-growing textareas with `field-sizing: content`]({% link _posts/2025-12-07-auto-growing-textareas.md %})
* [Dialog cancel buttons with `formmethod="dialog"`]({% link _posts/2025-12-08-dialog-cancel-buttons-with-formmethod.md %})
* [Dialog close buttons with `command="close"`]({% link _posts/2025-12-09-dialog-close-button-with-command.md %})
* [Light dismiss dialogs with `closedby`]({% link _posts/2025-12-10-dialog-light-dismiss-with-closedby.md %})
* [Open dialogs with `command` and `commandfor`]({% link _posts/2025-12-11-open-dialogs-with-command.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Dialog enter animations with `@starting-style`]({% link _posts/2025-12-12-dialog-enter-animations-with-starting-style.md %})
