---
series: Stylish HTML
title: "Dialog close buttons with <code>command=\"close\"</code>"
date: 2025-12-09
tags:
  - code
  - html
---

Continuing with closing `<dialog>`s, in addition to `formmethod="dialog"` you can also implement a dialog close button in the header with an invoker [`command="close"`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button#command). Perfect way to close a dialog without a `<form>`.

```html
<dialog id="example-dialog" aria-labelledby="dialog-title" aria-describedby="dialog-desc">
  <header>
    <hgroup>
      <h2 id="dialog-title">Refund payment</h2>
      <p id="dialog-desc">
        Are you sure you want to refund this payment?
        The funds will be returned to the customer's account.
      </p>
    </hgroup>
    <button
      type="button"
      commandfor="example-dialog"
      command="close"
      aria-label="Close dialog"
    >&times;</button>
  </header>
</dialog>
```

The `commandfor` attribute points to the dialog's ID, and `command="close"` tells the browser to close it when clicked—no JavaScript required.

Demo:

<img src="{{ '/images/dialog-command-close.gif' | relative_url }}" alt="A dialog with a close button in the header that closes the dialog when clicked" style="width: 100%" />



- - -

## All posts in this series

* [Avoid layout shift with `scrollbar-gutter: stable`]({% link _posts/2025-12-03-scrollbar-gutter-stable.md %})
* [Prevent scrolling when a dialog is open]({% link _posts/2025-12-04-prevent-scroll-with-dialog-modal.md %})
* [Anchor popovers without distinct anchor names]({% link _posts/2025-12-05-anchor-popovers-with-attr.md %})
* [De-emphasize scrollbars in small containers]({% link _posts/2025-12-06-style-scrollbars-in-popovers.md %})
* [Auto-growing textareas with `field-sizing: content`]({% link _posts/2025-12-07-auto-growing-textareas.md %})
* [Dialog cancel buttons with `formmethod="dialog"`]({% link _posts/2025-12-08-dialog-cancel-buttons-with-formmethod.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Dialog close buttons with `command="close"`]({% link _posts/2025-12-09-dialog-close-button-with-command.md %})
