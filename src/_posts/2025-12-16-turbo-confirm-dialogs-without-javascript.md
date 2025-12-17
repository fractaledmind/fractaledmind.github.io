---
title: Confirmation dialogs with zero JavaScript
date: 2025-12-26
tags:
  - code
  - html
  - css
  - rails
---

Turbo's `data-turbo-confirm` attribute is convenient for quick confirmation dialogs, but the native `confirm()` prompt it triggers looks dated and out of place. If you want a styled confirmation dialog that matches your app's design, the [traditional](https://turbo.hotwired.dev/handbook/drive#requiring-confirmation-for-a-visit) [approach](https://gorails.com/episodes/custom-hotwire-turbo-confirm-modals) [recommends](https://www.beflagrant.com/blog/turbo-confirmation-bias-2024-01-10) a lot of JavaScript—a Stimulus controller to open and close the dialog, event listeners for keyboard handling, and coordination between the trigger and the modal.

But, recent browser updates have changed the game. [Invoker Commands](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes/command) landed in Chrome 131 and Safari 18.4, giving us declarative dialog control. Combined with [`@starting-style`](https://developer.mozilla.org/en-US/docs/Web/CSS/@starting-style) for animations, we can now build beautiful, animated confirmation dialogs without writing any JavaScript.

<!--/summary-->

| Feature         | How                                      |
|-----------------|------------------------------------------|
| Open dialog     | `command="show-modal"` on a button       |
| Close dialog    | `command="close"` on cancel button       |
| Escape key      | Built-in browser behavior                |
| Light dismiss   | `closedby="any"` attribute               |
| Enter animation | `@starting-style` CSS rule               |
| Exit animation  | `allow-discrete` on `display` transition |

- - -

Let's imagine we wanted a confirmation dialog for when a user decides to delete an item in our app. Here is how we could build such a dialog today using modern browser features with zero JavaScript:

```erb
<button type="button" commandfor="delete-item-dialog" command="show-modal">
  Delete this item
</button>

<dialog id="delete-item-dialog" closedby="any" role="alertdialog"
        aria-labelledby="dialog-title" aria-describedby="dialog-desc">
  <header>
    <hgroup>
      <h3 id="dialog-title">Delete this item?</h3>
      <p id="dialog-desc">Are you sure you want to permanently delete this item?</p>
    </hgroup>
  </header>
  
  <footer>
    <button type="button" commandfor="delete-item-dialog" command="close">
      Cancel
    </button>
    <%= button_to item_path(item), method: :delete do %>
      Delete item
    <% end %>
  </footer>
</dialog>
```

The [`command`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button#command) attribute tells the browser what action to perform, and `commandfor` specifies the target element by `id`. With `command="show-modal"`, clicking the button calls [`showModal()`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement/showModal) on the target dialog. The cancel button uses `command="close"` to call the dialog's [`close()` method](https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement/close). Note the cancel button is `type="button"`, not `type="submit"`—we don't want it participating in any form submission.

Modal dialogs opened with `showModal()` automatically close on Escape. The browser handles it. Adding [`closedby="any"`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dialog#closedby) enables "light dismiss"—clicking the backdrop closes the dialog too.

The `aria-labelledby` and `aria-describedby` attributes connect the dialog to its heading and description. Screen reader users hear both the title and explanatory text announced immediately, giving them full context before making a decision. And `role="alertdialog"`	signals the dialog is a confirmation window communicating an important message that requires a user response.

So much functionality with nothing but declarative HTML! I love it.

- - -

## Adding Animations with `@starting-style`

For a polished feel, add smooth enter/exit transitions. With [`@starting-style`](https://developer.mozilla.org/en-US/docs/Web/CSS/@starting-style) and [`allow-discrete`](https://developer.mozilla.org/en-US/docs/Web/CSS/transition-behavior), we can animate dialogs purely in CSS.

The `@starting-style` rule defines the initial state when an element first appears. Without it, the browser renders the dialog immediately in its final state. With it, the browser starts from `opacity: 0; scale: 0.95` and transitions to `opacity: 1; scale: 1`, for example.

For exit animations, we need `transition-behavior: allow-discrete` on `display` and `overlay`. Most CSS properties are continuous—opacity can be 0.5, colors can blend. But `display` is discrete: it's either `none` or `block`, with no intermediate values. Historically, this meant `display` changes couldn't animate.

The `allow-discrete` keyword tells the browser to apply transition timing even for discrete properties. For closing animations, the browser keeps the element visible, runs the exit transition, then flips to `display: none` only after the transition completes. The `overlay` property works similarly—it controls whether the dialog stays in the [top layer](https://developer.mozilla.org/en-US/docs/Glossary/Top_layer) during the transition.

<details markdown="1">
  <summary>Example CSS</summary>

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
</details>

- - -

## Browser Support

| Feature | Chrome | Safari | Firefox | Can I Use |
|---------|--------|--------|---------|:---------:|
| `command` | 135+ | 26.2+ | 144+ | [link](https://caniuse.com/mdn-api_htmlbuttonelement_command) |
| `commandfor` | 135+ | 26.2+ | 144+ | [link](https://caniuse.com/mdn-html_elements_button_commandfor) |
| `@starting-style` | 117+ | 17.5+ | 129+ | [link](https://caniuse.com/mdn-css_at-rules_starting-style) |
| `closedby` | 134+ | Not yet | 141+ | [link](https://caniuse.com/mdn-html_elements_dialog_closedby) |

Safari support for `closedby` is still pending. For production use today, add a polyfill: [`dialog-closedby-polyfill`](https://github.com/fractaledmind/dialog-closedby-polyfill)

If you need invoker command support for older browsers, there is also a polyfill for that: [`invokers-polyfill`](https://github.com/keithamus/invokers-polyfill)

Both polyfills are small and only run when native support is missing.

- - -

## Integrating with Turbo's Confirm System

Now, what if you want to keep using Turbo's `data-turbo-confirm` attribute while getting a styled native dialog?

Turbo provides [`Turbo.config.forms.confirm`](https://turbo.hotwired.dev/reference/drive#turbo.config.forms.confirm) for exactly this. [Mikael Henriksson has an excellent writeup](https://mhenrixon.com/articles/turbo-confirm) on this approach and Chris Oliver has [a GoRails video](https://gorails.com/episodes/custom-hotwire-turbo-confirm-modals) as well.

First, add a dialog template to your layout, which you can of course style however you'd like using whatever CSS tooling you have in your app:

```erb
<%# app/views/layouts/application.html.erb %>
<dialog id="turbo-confirm-dialog" closedby="any"
        aria-labelledby="turbo-confirm-title" aria-describedby="turbo-confirm-message">
  <header>
    <hgroup>
      <h3 id="turbo-confirm-title">Confirm</h3>
      <p id="turbo-confirm-message"></p>
    </hgroup>
  </header>
  
  <footer>
    <button type="button" commandfor="turbo-confirm-dialog" command="close">
      Cancel
    </button>
    <form method="dialog">
      <button type="submit" value="confirm">
        Confirm
      </button>
    </form>
  </footer>
</dialog>
```

The Confirm button is `type="submit"` inside a `<form method="dialog">`. When submitted, the browser closes the dialog and sets [`returnValue`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement/returnValue) to the button's `value` attribute. This is how we detect which button was pressed—no JavaScript event coordination needed.

Then configure Turbo:

```javascript
const dialog = document.getElementById("turbo-confirm-dialog")
const messageElement = document.getElementById("turbo-confirm-message")
const confirmButton = dialog?.querySelector("button[value='confirm']")

Turbo.config.forms.confirm = (message, element, submitter) => {
  // Fall back to native confirm if dialog isn't in the DOM
  if (!dialog) return Promise.resolve(confirm(message))

  messageElement.textContent = message
  
  // Allow custom button text via data-turbo-confirm-button
  const buttonText = submitter?.dataset.turboConfirmButton || "Confirm"
  confirmButton.textContent = buttonText
  
  dialog.showModal()

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => {
      resolve(dialog.returnValue === "confirm")
    }, { once: true })
  })
}
```

The JavaScript does only three things: 

1. set the message text, 
2. customize the button text if provided, and 
3. open the dialog. 

Everything else—closing on button click, closing on Escape, closing on backdrop click, determining which button was pressed—is handled by the platform.

The fallback to native `confirm()` ensures your app still works if the dialog element is missing (e.g., on a different layout or error page).

`Turbo.config.forms.confirm` expects a function returning a Promise that resolves to `true` (proceed) or `false` (cancel). The function receives three arguments: the confirmation message, the element with the `data-turbo-confirm` attribute, and the submitter element. We listen for the `close` event and check `returnValue`. Write this handler once, add one dialog to your layout, and every `data-turbo-confirm` in your app uses it.

You can customize the confirm button text per-trigger using `data-turbo-confirm-button`:

```erb
<%= button_to item_path(item), 
              method: :delete,
              data: { 
                turbo_confirm: "Are you sure you want to delete this item?",
                turbo_confirm_button: "Delete item"
              } do %>
  Delete
<% end %>
```

This produces a more contextual confirmation dialog with "Delete item" instead of a generic "Confirm" button—better UX that makes the action clear.

- - -

## Addendum: Preventing Background Scroll

One common modal requirement is preventing page scroll while the dialog is open:

```css
body:has(dialog:modal) {
  overflow: hidden;
}
```

The [`:modal`](https://developer.mozilla.org/en-US/docs/Web/CSS/:modal) pseudo-class matches dialogs opened with `showModal()`. Combined with `:has()`, this selector targets the body only when a modal dialog is open. When the dialog opens, scrolling stops. When it closes, scrolling resumes. The browser handles the coordination.

- - -

## Appendix: Interactive Demo

Here's a working demo showing how different close mechanisms work. Try clicking "Delete Item", then close it different ways: click Cancel, click Delete, press Escape, or click the backdrop. Notice how `returnValue` is only `"confirm"` when you click the Delete button.

<style>
  /* Demo container */
  .demo-container {
    overflow: hidden;
    border-radius: 0.375rem;
    background-color: #27272a;
  }
  .demo-trigger-area {
    padding: 1.5rem;
  }
  
  /* Trigger button */
  .demo-trigger-btn {
    display: block;
    margin-left: auto;
    margin-right: auto;
    border-radius: 0.375rem;
    background-color: rgb(239 68 68 / 0.2);
    padding: 0.5rem 0.75rem;
    font-size: 0.875rem;
    font-weight: 600;
    color: #f87171;
    border: none;
    cursor: pointer;
  }
  .demo-trigger-btn:hover {
    background-color: rgb(239 68 68 / 0.3);
  }
  
  /* Dialog */
  #demo-confirm-dialog {
    border-radius: 0.5rem;
    background-color: #27272a;
    padding: 1.5rem;
    text-align: left;
    box-shadow: 0 25px 50px -12px rgb(0 0 0 / 0.25);
    border: none;
    outline: 1px solid rgb(255 255 255 / 0.1);
    outline-offset: -1px;
    margin-top: 33dvh;
    width: 100%;
    max-width: 32rem;
    
    /* Animation */
    opacity: 1;
    scale: 1;
    transition: 
      opacity 0.2s ease-out,
      scale 0.2s ease-out,
      overlay 0.2s ease-out allow-discrete,
      display 0.2s ease-out allow-discrete;
  }
  #demo-confirm-dialog[open] {
    @starting-style {
      opacity: 0;
      scale: 0.95;
    }
  }
  #demo-confirm-dialog:not([open]) {
    opacity: 0;
    scale: 0.95;
  }
  #demo-confirm-dialog::backdrop {
    background-color: rgb(0 0 0 / 0.5);
    transition: 
      background-color 0.2s ease-out,
      overlay 0.2s ease-out allow-discrete,
      display 0.2s ease-out allow-discrete;
  }
  #demo-confirm-dialog[open]::backdrop {
    @starting-style {
      background-color: rgb(0 0 0 / 0);
    }
  }
  #demo-confirm-dialog:not([open])::backdrop {
    background-color: rgb(0 0 0 / 0);
  }
  
  /* Dialog header */
  #demo-confirm-dialog header hgroup {
    text-align: left;
    margin: 0;
  }
  #demo-dialog-title {
    font-size: 1rem;
    font-weight: 600;
    color: white;
    margin: 0;
  }
  #demo-dialog-desc {
    margin: 0.5rem 0 0 0;
    font-size: 0.875rem;
    color: #a1a1aa;
  }
  
  /* Dialog footer */
  #demo-confirm-dialog footer {
    margin-top: 1rem;
    display: flex;
    flex-direction: row;
    gap: 0.75rem;
  }
  #demo-confirm-dialog footer form {
    margin: 0;
  }
  
  /* Cancel button */
  .demo-cancel-btn {
    display: inline-flex;
    justify-content: center;
    border-radius: 0.375rem;
    background-color: rgb(255 255 255 / 0.1);
    padding: 0.5rem 0.75rem;
    font-size: 0.875rem;
    font-weight: 600;
    color: white;
    box-shadow: inset 0 0 0 1px rgb(255 255 255 / 0.05);
    border: none;
    cursor: pointer;
  }
  .demo-cancel-btn:hover {
    background-color: rgb(255 255 255 / 0.2);
  }
  
  /* Delete/Confirm button */
  .demo-confirm-btn {
    display: inline-flex;
    justify-content: center;
    border-radius: 0.375rem;
    background-color: #ef4444;
    padding: 0.5rem 0.75rem;
    font-size: 0.875rem;
    font-weight: 600;
    color: white;
    border: none;
    cursor: pointer;
  }
  .demo-confirm-btn:hover {
    background-color: #f87171;
  }
  
  /* Event log area */
  .demo-log-area {
    margin-top: 1rem;
    overflow: hidden;
    border-top: 1px solid #3f3f46;
  }
  .demo-log-title {
    margin: 0;
    padding: 0.5rem 1rem;
    font-size: 0.875rem;
    font-weight: 600;
    color: white;
  }
  #demo-log {
    display: block;
    max-height: 10rem;
    min-height: 5rem;
    overflow-y: auto;
    padding: 1rem;
    scrollbar-color: #3f3f46 transparent;
    scrollbar-width: thin;
  }
  #demo-log-list {
    margin: 0;
    list-style: none;
    padding: 0;
  }
  #demo-log-list li {
    position: relative;
    display: flex;
    gap: 1rem;
  }
  #demo-log-list li + li {
    margin-top: 0.5rem;
  }
  #demo-log-list p {
    flex: 1 1 auto;
    padding: 0.125rem 0;
    font-size: 0.75rem;
    line-height: 1.25rem;
    color: #a1a1aa;
    margin: 0;
  }
  #demo-log-list time {
    flex: none;
    padding: 0.125rem 0;
    font-size: 0.75rem;
    line-height: 1.25rem;
    color: #a1a1aa;
  }
  #demo-log-list .log-label {
    font-weight: 500;
    color: white;
  }
  #demo-log-list code {
    border-radius: 0.25rem;
    background-color: rgb(255 255 255 / 0.1);
    padding: 0.125rem 0.375rem;
    color: #60a5fa;
  }
</style>

<script src="https://unpkg.com/invokers-polyfill" type="module"></script>
<script src="https://unpkg.com/@fractaledmind/dialog-closedby-polyfill" type="module"></script>

<div class="demo-container not-prose">
  <div class="demo-trigger-area">
    <button class="demo-trigger-btn" commandfor="demo-confirm-dialog" command="show-modal">
      Delete Item
    </button>
    <dialog id="demo-confirm-dialog" closedby="any" aria-labelledby="demo-dialog-title" aria-describedby="demo-dialog-desc">
      <header>
        <hgroup>
          <h3 id="demo-dialog-title">Delete this item?</h3>
          <p id="demo-dialog-desc">This action cannot be undone.</p>
        </hgroup>
      </header>
      <footer>
        <button type="button" class="demo-cancel-btn" commandfor="demo-confirm-dialog" command="close" autofocus>
          Cancel
        </button>
        <form method="dialog">
          <button type="submit" class="demo-confirm-btn" value="confirm">
            Delete
          </button>
        </form>
      </footer>
    </dialog>
  </div>

  <div class="demo-log-area">
    <p class="demo-log-title">Event Log</p>
    <output id="demo-log" aria-live="polite">
      <ul role="list" id="demo-log-list"></ul>
    </output>
  </div>
</div>

<script>
  (function() {
    const dialog = document.getElementById('demo-confirm-dialog');
    const log = document.getElementById('demo-log-list');
    if (!dialog || !log) return;

    function logEvent(message) {
      const time = new Date().toLocaleTimeString();
      const entry = document.createElement('li');
      entry.innerHTML = `
        <p>${message}</p>
        <time>${time}</time>
      `;
      log.prepend(entry);
    }

    dialog.addEventListener('toggle', function(event) {
      console.log(event)
      if (event.newState === 'open') {
        dialog.returnValue = '';
        logEvent('<span class="log-label">toggle</span> event — newState: <code>open</code>');
      } else {
        logEvent('<span class="log-label">toggle</span> event — newState: <code>closed</code>');
      }
    });

    dialog.addEventListener('close', function() {
      const returnValue = dialog.returnValue || '(empty)';
      logEvent('<span class="log-label">close</span> event — returnValue: <code>' + returnValue + '</code>');
    });

    dialog.addEventListener('cancel', function() {
      logEvent('<span class="log-label">cancel</span> event (Escape key)');
    });
  })();
</script>
