---
series: Stylish HTML
title: "Avoid layout shift with <code>scrollbar-gutter: stable</code>"
date: 2025-12-03
tags:
  - code
  - css
---

Want to avoid layout shift when you remove scrolling on popover or dialog opening? Use the [`scrollbar-gutter: stable`](https://developer.mozilla.org/en-US/docs/Web/CSS/scrollbar-gutter) CSS rule on your scroll container (likely `<body>`).

```css
body {
  scrollbar-gutter: stable;

  &:has(:popover-open) {
    overflow: hidden;
  }
}
```

The problem: when a popover opens and you hide the scrollbar with `overflow: hidden`, the content shifts horizontally to fill the space where the scrollbar was.

<img src="{{ '/images/scrollbar-layout-shift.gif' | relative_url }}" alt="A popover opening causes the page content to shift horizontally as the scrollbar disappears" style="width: 100%" />

The solution: `scrollbar-gutter: stable` reserves space for the scrollbar even when it's not visible, preventing the jarring horizontal shift.

<img src="{{ '/images/scrollbar-layout-shift-fixed.gif' | relative_url }}" alt="With scrollbar-gutter stable, the page content stays in place when the popover opens" style="width: 100%" />



- - -

## All posts in this series

* {:.bg-[var(--tw-prose-bullets)]}[Avoid layout shift with `scrollbar-gutter: stable`]({% link _posts/2025-12-03-scrollbar-gutter-stable.md %})
* [Prevent scrolling when a dialog is open]({% link _posts/2025-12-04-prevent-scroll-with-dialog-modal.md %})
* [Anchor popovers without distinct anchor names]({% link _posts/2025-12-05-anchor-popovers-with-attr.md %})
* [De-emphasize scrollbars in small containers]({% link _posts/2025-12-06-style-scrollbars-in-popovers.md %})
* [Auto-growing textareas with `field-sizing: content`]({% link _posts/2025-12-07-auto-growing-textareas.md %})
* [Dialog cancel buttons with `formmethod="dialog"`]({% link _posts/2025-12-08-dialog-cancel-buttons-with-formmethod.md %})
* [Dialog close buttons with `command="close"`]({% link _posts/2025-12-09-dialog-close-button-with-command.md %})
* [Light dismiss dialogs with `closedby`]({% link _posts/2025-12-10-dialog-light-dismiss-with-closedby.md %})
* [Open dialogs with `command` and `commandfor`]({% link _posts/2025-12-11-open-dialogs-with-command.md %})
