---
series: Stylish HTML
title: "Dialog exit animations with <code>allow-discrete</code>"
date: 2025-12-13
tags:
  - code
  - css
---

Enter animations are easy with `@starting-style`, but exit animations need [`transition-behavior: allow-discrete`](https://developer.mozilla.org/en-US/docs/Web/CSS/transition-behavior) to work. Most CSS properties are continuous—opacity can be 0.5, colors can blend. But `display` is discrete: it's either `none` or `block`, with no intermediate values.

The `allow-discrete` keyword tells the browser to apply transition timing even for discrete properties. For closing animations, the browser keeps the element visible, runs the exit transition, then flips to `display: none` only after the transition completes.

```css
dialog {
  opacity: 1;
  scale: 1;

  transition:
    opacity 0.2s ease-out,
    scale 0.2s ease-out,
    overlay 0.2s ease-out allow-discrete,
    display 0.2s ease-out allow-discrete;

  @starting-style {
    opacity: 0;
    scale: 0.95;
  }
}

dialog:not([open]) {
  opacity: 0;
  scale: 0.95;
}
```

The `overlay` property controls whether the dialog stays in the [top layer](https://developer.mozilla.org/en-US/docs/Glossary/Top_layer) during the transition—without it, the dialog would immediately drop behind other content.

Don't forget the backdrop:

```css
dialog::backdrop {
  background-color: rgb(0 0 0 / 0.5);
  transition:
    background-color 0.2s ease-out,
    overlay 0.2s ease-out allow-discrete,
    display 0.2s ease-out allow-discrete;

  @starting-style {
    background-color: rgb(0 0 0 / 0);
  }
}

dialog:not([open])::backdrop {
  background-color: rgb(0 0 0 / 0);
}
```

Demo:

<img src="{{ '/images/dialog-allow-discrete.gif' | relative_url }}" alt="A dialog closing with a smooth fade-out animation" style="width: 100%" />



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
* [Dialog enter animations with `@starting-style`]({% link _posts/2025-12-12-dialog-enter-animations-with-starting-style.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Dialog exit animations with `allow-discrete`]({% link _posts/2025-12-13-dialog-exit-animations-with-allow-discrete.md %})
