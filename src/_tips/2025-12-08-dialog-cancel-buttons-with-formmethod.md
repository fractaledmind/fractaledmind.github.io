---
series: Stylish HTML
title: "Dialog cancel buttons with <code>formmethod=\"dialog\"</code>"
date: 2025-12-08
tags:
  - code
  - html
typefully_published: true
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
