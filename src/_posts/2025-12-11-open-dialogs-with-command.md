---
series: Stylish HTML
title: "Open dialogs with <code>command</code> and <code>commandfor</code>"
date: 2025-12-11
tags:
  - code
  - html
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
* {:.bg-[var(--tw-prose-bullets)]}[Open dialogs with `command` and `commandfor`]({% link _posts/2025-12-11-open-dialogs-with-command.md %})
