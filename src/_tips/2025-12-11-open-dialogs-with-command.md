---
series: Stylish HTML
title: "Open dialogs with <code>command</code> and <code>commandfor</code>"
date: 2025-12-11
tags:
  - code
  - html
typefully_published: true
---

The [`command`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button#command) attribute lets you open `<dialog>`s declaratively—no JavaScript required. Use `command="show-modal"` for modal dialogs or `command="show"` for non-modal ones.

```html
<!-- Modal dialog (with backdrop, traps focus) -->
<button type="button" commandfor="modal-dialog" command="show-modal">
  Open Modal
</button>

<!-- Non-modal dialog (no backdrop, doesn't trap focus) -->
<button type="button" commandfor="modeless-dialog" command="show">
  Open Dialog
</button>

<dialog id="modal-dialog">
  <p>I'm a modal dialog with a backdrop.</p>
  <button type="button" commandfor="modal-dialog" command="close">Close</button>
</dialog>

<dialog id="modeless-dialog">
  <p>I'm a non-modal dialog. You can still interact with the page.</p>
  <button type="button" commandfor="modeless-dialog" command="close">Close</button>
</dialog>
```

The `commandfor` attribute points to the dialog's ID. When clicked, `show-modal` calls [`showModal()`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement/showModal) and `show` calls [`show()`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement/show).

Modal dialogs:
- Display a `::backdrop` pseudo-element
- Trap focus inside the dialog
- Close on Escape key
- Block interaction with the rest of the page

Non-modal dialogs:
- No backdrop
- Don't trap focus
- Don't close on Escape by default
- Allow interaction with the rest of the page

Demo:

<img src="{{ '/images/dialog-command-show.gif' | relative_url }}" alt="Two buttons opening modal and non-modal dialogs respectively" style="width: 100%" />
