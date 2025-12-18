---
title: Stylish <code>&lt;dialog&gt;</code>s
date: 2025-12-18
tags:
  - code
  - html
  - css
  - tailwind
---

[Campsite](https://github.com/campsite/campsite) has some of my favorite UI styling on the web. Naturally, I cracked open their source hoping to learn something. What I found: React components rendering `<div>`s inside `<div>`s, with piles of JavaScript doing what `<dialog>` does for free.

So I borrowed their visual design and rebuilt it with semantic HTML and CSS using [affordance classes]({% link _posts/2025-12-01-ui-affordances.md %}). I want to walk you through all of the choices I've made and how it all comes together.

<!--/summary-->

- - -

## The HTML

Here's the markup structure I use for a full-featured dialog:

```html
<dialog id="example-dialog" class="ui/dialog" 
        aria-labelledby="example-dialog-title" 
        aria-describedby="example-dialog-desc" 
        closedby="any">
  <header>
    <hgroup>
      <h2 id="example-dialog-title">Basic Dialog</h2>
      <p id="example-dialog-desc">This is a basic dialog with header, content, and footer sections.</p>
    </hgroup>
    <button type="button" class="ui/button/plain aspect-square" 
            commandfor="example-dialog" command="close" 
            aria-label="Close dialog">&times;</button>
  </header>
  <form method="POST" action="#">
    <article>
      <p>
        Dialog content goes here. This area can contain forms, text, images, 
        or any other content. The native <code>&lt;dialog&gt;</code> element 
        handles focus management and accessibility automatically.
      </p>
    </article>
    <footer>
      <button class="ui/button/flat" type="submit" 
              formmethod="dialog" formnovalidate value="cancel">Cancel</button>
      <button class="ui/button/primary" type="submit" autofocus>Confirm</button>
    </footer>
  </form>
</dialog>
```

### Semantic Elements

Yes, I'm a semantic HTML nerd. `<header>`, `<article>`, `<footer>` instead of `<div>`s everywhere. The structure is obvious when you revisit the code six months later, and you can target these elements directly in CSS without inventing class names.

### The Form Wrapper

The body and footer are wrapped in a `<form>`. This might seem odd at first, but it unlocks key functionality. Dialogs often need to *do* something—create a resource, update settings, submit data. Wrapping in a form means your dialog is ready for that from the start. And for simple confirmations, [`method=dialog`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form#method) on the form (or [`formmethod=dialog`]({% link _tips/2025-12-08-dialog-cancel-buttons-with-formmethod.md %}) on a button) closes the dialog without any network request.

### Two Close Mechanisms

The header's × button uses [`command=close`]({% link _tips/2025-12-09-dialog-close-button-with-command.md %}) because it's outside the form. The footer's Cancel button uses `formmethod=dialog` because it's inside—a submit that closes without hitting the network.

### Focus Handling

The confirm button has [`autofocus`](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/autofocus). When the dialog opens, focus moves there immediately—keyboard users land on the primary action, one Enter key away.

### Light Dismiss

The [`closedby=any`]({% link _tips/2025-12-10-dialog-light-dismiss-with-closedby.md %}) attribute enables "light dismiss"—clicking the backdrop closes the dialog. Combined with the browser's built-in Escape key handling, users have multiple intuitive ways to close. No JavaScript event listeners required.

### Accessibility

The [`aria-labelledby`](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-labelledby) and [`aria-describedby`](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-describedby) attributes connect the dialog to its heading and description. Screen readers announce both immediately when the dialog opens, giving users full context before they need to act.

For confirmation dialogs specifically, add [`role=alertdialog`](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/alertdialog_role). This signals that the dialog communicates an important message requiring a user response—distinct from a generic dialog that might just display information or offer a form. The browser and assistive technologies treat alert dialogs with appropriate urgency.

```html
<dialog id="confirm-delete" 
        role="alertdialog"
        aria-labelledby="confirm-title" 
        aria-describedby="confirm-desc">
  <!-- ... -->
</dialog>
```

- - -

## The CSS Architecture

The styles use Tailwind v4's `@utility` directive to create tree-shakeable, autocomplete-friendly utility classes. Here's the structure:

```css
@import "tailwindcss";

@theme {
  --shadow-dialog: 0px 0px 3.5px rgba(0, 0, 0, 0.04), 
    0px 0px 10px rgba(0, 0, 0, 0.04),
    0px 0px 24px rgba(0, 0, 0, 0.05), 
    0px 0px 80px rgba(0, 0, 0, 0.08);
  --shadow-dialog-dark: inset 0 0.5px 0 rgb(255 255 255 / 0.08),
    inset 0 0 1px rgb(255 255 255 / 0.24), 
    0 0 0 0.5px rgb(0 0 0 / 1),
    0px 0px 4px rgba(0, 0, 0, 0.08), 
    0px 0px 10px rgba(0, 0, 0, 0.12),
    0px 0px 24px rgba(0, 0, 0, 0.16), 
    0px 0px 80px rgba(0, 0, 0, 0.2);
}
```

I borrowed these layered shadows directly from Campsite. The multiple shadows at different blur radii create a more natural, ambient lighting effect—the kind that makes people think you hired a designer. In dark mode, inset shadows add an inner glow that gives the panel depth.

- - -

## The Base Dialog Utility

```css
@utility ui/dialog {
  :where(&) {
    @apply rounded-lg border-none bg-white p-0 text-zinc-900 shadow-dialog;
    @apply isolate flex w-full flex-col;
    @apply max-w-[calc(100vw-32px)] min-w-sm;
    @apply pointer-events-none invisible;
  
    @apply m-auto;
    @apply max-h-[calc(100dvh-env(safe-area-inset-bottom,0)-env(safe-area-inset-top,0)-32px)];
  
    @variant sm {
      @apply max-w-md;
    }
  
    @variant focus {
      @apply outline-0;
    }
  
    @variant open {
      @apply pointer-events-auto visible;
    }
  
    @variant dark {
      @apply bg-zinc-900 text-zinc-50 shadow-dialog-dark;
    }
  }
}
```

### The Visibility Problem

A `<dialog>` with `display: flex` stays visible even when closed—the browser's default `display: none` gets overridden. The fix: `pointer-events-none` and `invisible`. The dialog stays in the DOM but users can't see or interact with it. When `[open]` applies, we flip both back. This also prevents a flash of dialog content on page load.

### Sizing Constraints

The `max-w-[calc(100vw-32px)]` ensures the dialog never touches the screen edges—always 16px of breathing room on each side. The `min-w-sm` (24rem) prevents the dialog from becoming uncomfortably narrow on larger screens.

For height, `max-h-[calc(100dvh-env(safe-area-inset-bottom,0)-env(safe-area-inset-top,0)-32px)]` does more work. The [`dvh` unit](https://developer.mozilla.org/en-US/docs/Web/CSS/length#dynamic_viewport_units) (dynamic viewport height) accounts for mobile browser chrome that appears and disappears. The [`env(safe-area-inset-*)`](https://developer.mozilla.org/en-US/docs/Web/CSS/env) functions respect the notch and home indicator on modern phones. Together, they ensure the dialog fits the *actual* available space, not just the theoretical viewport.

### Stacking Context

The [`isolate`](https://developer.mozilla.org/en-US/docs/Web/CSS/isolation) class creates a new stacking context. Any `z-index` values inside the dialog stay contained—dropdowns or tooltips won't escape and interfere with elements outside.

### Why `focus` Instead of `focus-visible`

The focus variant removes the outline entirely. You might expect [`:focus-visible`](https://developer.mozilla.org/en-US/docs/Web/CSS/:focus-visible) here, but `autofocus` on dialog buttons triggers [`:focus`](https://developer.mozilla.org/en-US/docs/Web/CSS/:focus), not `:focus-visible`. If you only style `focus-visible`, autofocused elements remain unstyled.

- - -

## Slot Classes and Semantic Selectors

Now for a part I'm quite pleased with. We define independent "slot" utilities that can apply to any element:

```css
@utility dialog/header {
  :where(&) {
    @apply relative flex-none rounded-t-lg p-4 text-sm;

    &:has(> button[command="close"]) {
      @apply pr-12;
    }
  }
}

@utility dialog/title {
  :where(&) {
    @apply m-0 flex-1 font-semibold;
  }
}

@utility dialog/description {
  :where(&) {
    @apply m-0 mt-0.5 text-zinc-600;

    @variant dark {
      @apply text-zinc-300;
    }
  }
}

@utility dialog/content {
  :where(&) {
    @apply flex flex-1 flex-col overflow-y-auto p-4 pt-0 text-sm;
  }
}

@utility dialog/footer {
  :where(&) {
    @apply flex items-center rounded-b-lg border-t border-black/10 p-3;

    @variant dark {
      @apply border-white/12;
    }
  }
}
```

Then the parent `ui/dialog` utility applies these to semantic elements automatically:

```css
@utility ui/dialog {
  /* ... base styles ... */

  :where(& > header) {
    @apply dialog/header;
  }

  :where(& header hgroup :is(h1, h2, h3, h4, h5, h6)) {
    @apply dialog/title;
  }

  :where(& header hgroup p) {
    @apply dialog/description;
  }

  :where(& form > article) {
    @apply dialog/content;
  }

  :where(& form > footer) {
    @apply dialog/footer;
  }
}
```

Write semantic HTML, get automatic styling. Or apply `dialog/content` directly to a `<div>` when your framework generates custom markup.

The [`:where()`](https://developer.mozilla.org/en-US/docs/Web/CSS/:where) wrapper keeps specificity at zero. Without it, these nested selectors would have higher specificity than single utility classes, and you'd be fighting your own styles every time you needed to customize something. 

- - -

## Animations

Most dialog implementations just fade in and out. That's fine, but we can do better.

```css
@keyframes dialog-slide-up-scale-fade {
  from {
    opacity: 0;
    transform: translateY(20px) scale(0.98);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

@keyframes dialog-scale-down-fade {
  from {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
  to {
    opacity: 0;
    transform: translateY(0) scale(0.95);
  }
}
```

### Asymmetric Motion

Entry slides up and scales in. Exit just scales down and fades. Sliding down on exit felt wrong—it implies the dialog is *going* somewhere, but it's not. It's disappearing. Scale-down-and-fade says "dismissed" without false movement.

### Timing Differences

```css
@utility ui/dialog {
  --dialog-entry-duration: 0.2s;
  --dialog-exit-duration: calc(var(--dialog-entry-duration) * 0.75);
  --backdrop-entry-duration: calc(var(--dialog-entry-duration) * 0.2);
  --backdrop-exit-duration: calc(var(--dialog-exit-duration) * 0.75);
}
```

Exit animations run at 75% the duration of entry. Entrances should feel intentional; exits should get out of the way.

The backdrop animates even faster. On entry, it appears almost instantly (20% of dialog duration), then the dialog follows—the dialog emerges from the dimmed background rather than appearing on top of it. On exit, the backdrop fades before the dialog finishes so you never see the dialog floating against a fully-bright background.

### The Technical Details

```css
@utility ui/dialog {
  animation: dialog-scale-down-fade var(--dialog-exit-duration) var(--dialog-easing) forwards;
  transition:
    overlay var(--dialog-exit-duration) var(--dialog-easing) allow-discrete,
    display var(--dialog-exit-duration) var(--dialog-easing) allow-discrete;

  @variant open {
    animation: dialog-slide-up-scale-fade var(--dialog-entry-duration) var(--dialog-easing) forwards;

    @starting-style {
      animation: none;
    }
  }
}
```

The [`allow-discrete`]({% link _tips/2025-12-13-dialog-exit-animations-with-allow-discrete.md %}) keyword on `display` and `overlay` is essential. These are discrete properties—they can't interpolate between values. The keyword tells the browser to keep the element visible during the exit animation, only flipping to `display: none` after the animation completes. Without it, your exit animation just... doesn't happen. The dialog vanishes instantly.

The [`@starting-style`]({% link _tips/2025-12-12-dialog-enter-animations-with-starting-style.md %}) rule defines where the animation begins. Without it, the browser renders the dialog immediately in its final state. Same problem, opposite direction—no entry animation.

- - -

## Button Styles

The demo includes button styles, but those deserve their own post. Coming soon.

- - -

## Browser Support

| Feature | Chrome | Safari | Firefox |
|---------|--------|--------|---------|
| `command`/`commandfor` | 135+ | 26.2+ | 144+ |
| `@starting-style` | 117+ | 17.5+ | 129+ |
| `closedby` | 134+ | Not yet | 141+ |
| `allow-discrete` | 117+ | 17.4+ | 129+ |

For production today, you can use polyfills if needed:
- [`invokers-polyfill`](https://github.com/keithamus/invokers-polyfill) for command/commandfor
- [`dialog-closedby-polyfill`](https://github.com/nicjansma/dialog-closedby-polyfill) for closedby

- - -

## Interactive Demo

Here's a working demo. Try opening it, then close it different ways: click the × button, click Cancel, click Confirm, press Escape, or click the backdrop.

<style>
  @keyframes dialog-slide-up-scale-fade {
    from {
      opacity: 0;
      transform: translateY(20px) scale(0.98);
    }
    to {
      opacity: 1;
      transform: translateY(0) scale(1);
    }
  }
  @keyframes dialog-scale-down-fade {
    from {
      opacity: 1;
      transform: translateY(0) scale(1);
    }
    to {
      opacity: 0;
      transform: translateY(0) scale(0.95);
    }
  }
  
  .ui\/dialog {
    pointer-events: none;
    visibility: hidden;
    isolation: isolate;
    margin: auto;
    max-height: calc(100dvh - env(safe-area-inset-bottom,0) - env(safe-area-inset-top,0) - 32px);
    display: flex;
    width: 100%;
    max-width: calc(100vw - 32px);
    min-width: 24rem;
    flex-direction: column;
    border-radius: 0.5rem;
    border-style: none;
    background-color: white;
    padding: 0;
    color: #18181b;
    box-shadow: 0px 0px 3.5px rgba(0, 0, 0, 0.04), 0px 0px 10px rgba(0, 0, 0, 0.04), 0px 0px 24px rgba(0, 0, 0, 0.05), 0px 0px 80px rgba(0, 0, 0, 0.08);
    --dialog-entry-duration: 0.2s;
    --dialog-exit-duration: calc(var(--dialog-entry-duration) * 0.75);
    --backdrop-entry-duration: calc(var(--dialog-entry-duration) * 0.2);
    --backdrop-exit-duration: calc(var(--dialog-exit-duration) * 0.75);
    --dialog-easing: cubic-bezier(0.16, 1, 0.3, 1);
    --backdrop-easing: ease-in-out;
    animation: dialog-scale-down-fade var(--dialog-exit-duration) var(--dialog-easing) forwards;
    transition: overlay var(--dialog-exit-duration) var(--dialog-easing) allow-discrete, display var(--dialog-exit-duration) var(--dialog-easing) allow-discrete;
  }
  @media (width >= 40rem) {
    .ui\/dialog {
      max-width: 28rem;
    }
  }
  .ui\/dialog:focus {
    outline-width: 0px;
  }
  .ui\/dialog:is([open], :popover-open, :open) {
    pointer-events: auto;
    visibility: visible;
    animation: dialog-slide-up-scale-fade var(--dialog-entry-duration) var(--dialog-easing) forwards;
    transition: overlay var(--dialog-entry-duration) var(--dialog-easing) allow-discrete, display var(--dialog-entry-duration) var(--dialog-easing) allow-discrete;
    @starting-style {
      animation: none;
    }
  }
  .ui\/dialog::backdrop {
    background-color: rgb(0 0 0 / 0);
    transition: background-color var(--backdrop-exit-duration) var(--backdrop-easing), overlay var(--dialog-exit-duration) var(--backdrop-easing) allow-discrete, display var(--dialog-exit-duration) var(--backdrop-easing) allow-discrete;
  }
  .ui\/dialog[open]::backdrop {
    background-color: rgb(0 0 0 / 0.2);
    transition: background-color var(--backdrop-entry-duration) var(--backdrop-easing), overlay var(--dialog-entry-duration) var(--backdrop-easing) allow-discrete, display var(--dialog-entry-duration) var(--backdrop-easing) allow-discrete;
    @starting-style {
      background-color: rgb(0 0 0 / 0);
    }
  }
  
  /* Dark mode */
  .ui\/dialog.dark {
    background-color: #18181b;
    color: #fafafa;
    box-shadow: inset 0 0.5px 0 rgb(255 255 255 / 0.08), inset 0 0 1px rgb(255 255 255 / 0.24), 0 0 0 0.5px rgb(0 0 0 / 1), 0px 0px 4px rgba(0, 0, 0, 0.08), 0px 0px 10px rgba(0, 0, 0, 0.12), 0px 0px 24px rgba(0, 0, 0, 0.16), 0px 0px 80px rgba(0, 0, 0, 0.2);
  }
  .ui\/dialog.dark::backdrop {
    background-color: rgb(0 0 0 / 0);
  }
  .ui\/dialog.dark[open]::backdrop {
    background-color: rgb(0 0 0 / 0.6);
    @starting-style {
      background-color: rgb(0 0 0 / 0);
    }
  }
  
  /* Dialog header */
  .ui\/dialog > header {
    position: relative;
    flex: none;
    border-top-left-radius: 0.5rem;
    border-top-right-radius: 0.5rem;
    padding: 1rem;
    font-size: 0.875rem;
  }
  .ui\/dialog > header:has(> button[command="close"]) {
    padding-right: 3rem;
  }
  .ui\/dialog header hgroup {
    display: flex;
    flex-direction: column;
    gap: 0.125rem;
  }
  .ui\/dialog header hgroup :is(h1, h2, h3, h4, h5, h6) {
    margin: 0;
    flex: 1;
    font-weight: 600;
  }
  .ui\/dialog header hgroup p {
    margin: 0;
    margin-top: 0.125rem;
    color: #52525b;
  }
  .ui\/dialog.dark header hgroup p {
    color: #d4d4d8;
  }
  .ui\/dialog header > button[command="close"] {
    position: absolute;
    top: 0.75rem;
    right: 0.75rem;
    font-size: 1rem;
  }
  
  /* Dialog form/content/footer */
  .ui\/dialog > form {
    display: flex;
    min-height: 0;
    flex: 1;
    flex-direction: column;
  }
  .ui\/dialog form > article {
    display: flex;
    flex: 1;
    flex-direction: column;
    overflow-y: auto;
    padding: 1rem;
    padding-top: 0;
    font-size: 0.875rem;
  }
  .ui\/dialog form > article p {
    margin: 0;
  }
  .ui\/dialog form > footer {
    margin: 0;
    display: flex;
    list-style-type: none;
    align-items: center;
    justify-content: flex-end;
    gap: 0.5rem;
    padding: 0;
    border-bottom-right-radius: 0.5rem;
    border-bottom-left-radius: 0.5rem;
    border-top: 1px solid rgb(0 0 0 / 0.1);
    padding: 0.75rem;
  }
  .ui\/dialog.dark form > footer {
    border-color: rgb(255 255 255 / 0.12);
  }
  
  /* Button styles */
  .ui\/button {
    position: relative;
    display: inline-flex;
    flex-shrink: 0;
    align-items: center;
    justify-content: center;
    font-weight: 500;
    outline-width: 0px;
    user-select: none;
    height: 30px;
    border-radius: 0.375rem;
    padding-inline: 0.625rem;
    font-size: 0.875rem;
    cursor: pointer;
    border: 1px solid transparent;
    background-color: white;
    color: #18181b;
    box-shadow: 0px 1px 1px -1px rgb(0 0 0 / 0.08), 0px 2px 2px -1px rgb(0 0 0 / 0.08), 0px 0px 0px 1px rgb(0 0 0 / 0.06), inset 0px 1px 0px #fff, inset 0px 1px 2px 1px #fff, inset 0px 1px 2px rgb(0 0 0 / 0.06);
  }
  .ui\/button:hover {
    background-color: #f4f4f5;
  }
  .ui\/button:focus-visible {
    outline: 2px solid #3b82f6;
    outline-offset: 2px;
  }
  .ui\/button.dark {
    background-color: #3f3f46;
    color: #fafafa;
    box-shadow: 0px 0px 0px 0.5px rgb(0 0 0 / 0.4), 0px 1px 1px -1px rgb(0 0 0 / 0.12), 0px 2px 2px -1px rgb(0 0 0 / 0.12), inset 0px 0.5px 0px rgb(255 255 255 / 0.06), inset 0px 0px 1px 0px rgb(255 255 255 / 0.16), inset 0px -6px 12px -4px rgb(0 0 0 / 0.16);
  }
  .ui\/button.dark:hover {
    background-color: #52525b;
  }
  .ui\/button.dark:focus-visible {
    outline-color: white;
  }
  
  .ui\/button\/plain {
    position: relative;
    display: inline-flex;
    flex-shrink: 0;
    align-items: center;
    justify-content: center;
    font-weight: 500;
    outline-width: 0px;
    user-select: none;
    height: 30px;
    border-radius: 0.375rem;
    padding-inline: 0.625rem;
    font-size: 0.875rem;
    cursor: pointer;
    border: none;
    background-color: transparent;
    color: #18181b;
    box-shadow: none;
  }
  .ui\/button\/plain:hover {
    background-color: rgb(0 0 0 / 0.06);
  }
  .ui\/button\/plain:focus-visible {
    outline: 2px solid #3b82f6;
    outline-offset: 2px;
  }
  .ui\/button\/plain.dark {
    color: #fafafa;
  }
  .ui\/button\/plain.dark:hover {
    background-color: rgb(255 255 255 / 0.08);
  }
  .ui\/button\/plain.dark:focus-visible {
    outline-color: white;
  }
  
  .ui\/button\/flat {
    position: relative;
    display: inline-flex;
    flex-shrink: 0;
    align-items: center;
    justify-content: center;
    font-weight: 500;
    outline-width: 0px;
    user-select: none;
    height: 30px;
    border-radius: 0.375rem;
    padding-inline: 0.625rem;
    font-size: 0.875rem;
    cursor: pointer;
    border: none;
    background-color: rgb(0 0 0 / 0.06);
    color: #18181b;
    box-shadow: none;
  }
  .ui\/button\/flat:hover {
    background-color: rgb(0 0 0 / 0.08);
  }
  .ui\/button\/flat:focus-visible {
    outline: 2px solid #3b82f6;
    outline-offset: 2px;
  }
  .ui\/button\/flat.dark {
    background-color: rgb(255 255 255 / 0.08);
    color: #fafafa;
  }
  .ui\/button\/flat.dark:hover {
    background-color: rgb(255 255 255 / 0.1);
  }
  .ui\/button\/flat.dark:focus-visible {
    outline-color: white;
  }
  
  .ui\/button\/primary {
    position: relative;
    display: inline-flex;
    flex-shrink: 0;
    align-items: center;
    justify-content: center;
    font-weight: 500;
    outline-width: 0px;
    user-select: none;
    height: 30px;
    border-radius: 0.375rem;
    padding-inline: 0.625rem;
    font-size: 0.875rem;
    cursor: pointer;
    border: none;
    background-color: #27272a;
    color: #fafafa;
    box-shadow: none;
  }
  .ui\/button\/primary:hover {
    background-color: #3f3f46;
  }
  .ui\/button\/primary:focus-visible {
    outline: 2px solid #3b82f6;
    outline-offset: 2px;
  }
  .ui\/button\/primary.dark {
    background-color: #f4f4f5;
    color: #18181b;
  }
  .ui\/button\/primary.dark:hover {
    background-color: #e4e4e7;
  }
  .ui\/button\/primary.dark:focus-visible {
    outline-color: white;
  }
  
  /* Event log */
  .demo-log-area {
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
  #stylish-demo-log {
    display: block;
    max-height: 10rem;
    min-height: 5rem;
    overflow-y: auto;
    padding: 1rem;
    scrollbar-color: #3f3f46 transparent;
    scrollbar-width: thin;
  }
  #stylish-demo-log-list {
    margin: 0;
    list-style: none;
    padding: 0;
  }
  #stylish-demo-log-list li {
    display: flex;
    gap: 1rem;
  }
  #stylish-demo-log-list li + li {
    margin-top: 0.5rem;
  }
  #stylish-demo-log-list p {
    flex: 1;
    margin: 0;
    font-size: 0.75rem;
    line-height: 1.25rem;
    color: #a1a1aa;
  }
  #stylish-demo-log-list time {
    flex: none;
    font-size: 0.75rem;
    line-height: 1.25rem;
    color: #a1a1aa;
  }
  #stylish-demo-log-list .log-label {
    font-weight: 500;
    color: white;
  }
  #stylish-demo-log-list code {
    border-radius: 0.25rem;
    background-color: rgba(255, 255, 255, 0.1);
    padding: 0.125rem 0.375rem;
    color: #60a5fa;
  }
</style>

<script src="https://unpkg.com/invokers-polyfill" type="module"></script>
<script src="https://unpkg.com/@nicjansma/dialog-closedby-polyfill" type="module"></script>

<div class="not-prose overflow-hidden rounded-lg bg-zinc-900">
  <div class="flex justify-center p-6">
    <button class="ui/button dark" commandfor="stylish-demo-dialog" command="show-modal">
      Open Dialog
    </button>
  </div>
  
  <dialog id="stylish-demo-dialog" class="ui/dialog dark" closedby="any" 
          aria-labelledby="stylish-demo-title" aria-describedby="stylish-demo-desc">
    <header>
      <hgroup>
        <h2 id="stylish-demo-title">Basic Dialog</h2>
        <p id="stylish-demo-desc">This dialog demonstrates the styling patterns from this post.</p>
      </hgroup>
      <button type="button" class="ui/button/plain dark aspect-square" commandfor="stylish-demo-dialog" command="close" aria-label="Close dialog">&times;</button>
    </header>
    <form method="POST" action="#">
      <article>
        <p>
          Dialog content goes here. Try closing this dialog different ways: click the × button, 
          click Cancel, click Confirm, press Escape, or click the backdrop.
        </p>
      </article>
      <footer>
        <button class="ui/button/flat dark" type="submit" formmethod="dialog" formnovalidate value="cancel">Cancel</button>
        <button class="ui/button/primary dark" type="submit" formmethod="dialog" value="confirm" autofocus>Confirm</button>
      </footer>
    </form>
  </dialog>

  <div class="demo-log-area">
    <p class="demo-log-title">Event Log</p>
    <output id="stylish-demo-log" aria-live="polite">
      <ul role="list" id="stylish-demo-log-list"></ul>
    </output>
  </div>
</div>

<script>
  (function() {
    const dialog = document.getElementById('stylish-demo-dialog');
    const log = document.getElementById('stylish-demo-log-list');
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

Want to experiment? [Explore the full demo on Tailwind Play](https://play.tailwindcss.com/BFs63aoh9G?file=css) where you can tweak the styles and see how everything fits together.

- - -

## What's Next

Dialogs are just one piece. I'm building out a full set of [affordance classes]({% link _posts/2025-12-01-ui-affordances.md %})—buttons, forms, menus, popovers, tabs, tables. Designer-quality styling, browser-native behavior. The kind of UI that makes people ask who you hired. So be on the lookout for more like this 👀.
