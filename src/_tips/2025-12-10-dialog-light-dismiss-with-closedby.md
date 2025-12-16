---
series: Stylish HTML
title: "Light dismiss dialogs with <code>closedby</code>"
date: 2025-12-10
tags:
  - code
  - html
typefully_published: true
---

The [`closedby`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/dialog#closedby) attribute gives you declarative control over how users can dismiss a `<dialog>`. Want users to close by clicking outside? Set `closedby="any"`. Need to force them through your buttons? Use `closedby="none"`.

```html
<!-- Light dismiss: Esc key OR clicking outside -->
<dialog id="light-dismiss-dialog" closedby="any">
  <p>Click outside or press Esc to close me.</p>
  <button type="button" commandfor="light-dismiss-dialog" command="close">
    Or close manually
  </button>
</dialog>

<!-- Platform dismiss only: Esc key, no clicking outside -->
<dialog id="platform-dismiss-dialog" closedby="closerequest">
  <p>Press Esc to close, but clicking outside won't work.</p>
  <button type="button" commandfor="platform-dismiss-dialog" command="close">
    Close
  </button>
</dialog>

<!-- Developer dismiss only: buttons/forms only -->
<dialog id="strict-dialog" closedby="none">
  <p>You must use the button to close this dialog.</p>
  <button type="button" commandfor="strict-dialog" command="close">
    Close
  </button>
</dialog>
```

The three values:

- **`any`** — Light dismiss (clicking outside), platform actions (Esc key), and developer mechanisms (buttons)
- **`closerequest`** — Platform actions and developer mechanisms only (no clicking outside)
- **`none`** — Developer mechanisms only (buttons must be used)

By default, modal dialogs behave as `closerequest` (Esc closes them) and non-modal dialogs behave as `none`. The `closedby` attribute lets you override these defaults—finally giving us the "click outside to close" pattern without JavaScript.

Demo:

<img src="{{ '/images/dialog-closedby-any.gif' | relative_url }}" alt="Two buttons opening modal and non-modal dialogs respectively" style="width: 100%" />
