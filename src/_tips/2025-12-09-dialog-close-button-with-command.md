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
