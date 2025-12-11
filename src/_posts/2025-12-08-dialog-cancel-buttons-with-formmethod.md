---
series: Stylish HTML
title: "Dialog cancel buttons with <code>formmethod=\"dialog\"</code>"
date: 2025-12-08
tags:
  - code
  - html
---

`<dialog>`s with forms have a simple HTML-only way to implement "Cancel" buttons. In addition to `POST` and `GET`, `<form>`s inside of `<dialog>`s can make use of the [`dialog` method](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button#formmethod). This allows the submit button to close the dialog without submitting the form to the backend.

```html
<dialog id="example-dialog">
  <form method="POST" action="/confirmations">
    <footer>
      <button type="submit" formmethod="dialog" formnovalidate value="cancel">
        Cancel
      </button>
      <button type="submit">
        Confirm
      </button>
    </footer>
  </form>
</dialog>
```

The `formmethod="dialog"` attribute on the cancel button overrides the form's method, closing the dialog instead of submitting. The `formnovalidate` attribute ensures validation doesn't block the cancel action.

Demo:

<img src="{{ '/images/formmethod-dialog.gif' | relative_url }}" alt="A confirmation dialog with Cancel and Confirm buttons, where Cancel closes the dialog without submitting" style="width: 100%" />



- - -

## All posts in this series

* [Avoid layout shift with `scrollbar-gutter: stable`]({% link _posts/2025-12-03-scrollbar-gutter-stable.md %})
* [Prevent scrolling when a dialog is open]({% link _posts/2025-12-04-prevent-scroll-with-dialog-modal.md %})
* [Anchor popovers without distinct anchor names]({% link _posts/2025-12-05-anchor-popovers-with-attr.md %})
* [De-emphasize scrollbars in small containers]({% link _posts/2025-12-06-style-scrollbars-in-popovers.md %})
* [Auto-growing textareas with `field-sizing: content`]({% link _posts/2025-12-07-auto-growing-textareas.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Dialog cancel buttons with `formmethod="dialog"`]({% link _posts/2025-12-08-dialog-cancel-buttons-with-formmethod.md %})
* [Dialog close buttons with `command="close"`]({% link _posts/2025-12-09-dialog-close-button-with-command.md %})
* [Light dismiss dialogs with `closedby`]({% link _posts/2025-12-10-dialog-light-dismiss-with-closedby.md %})
