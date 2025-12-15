---
series: Stylish HTML
title: "Dialog enter animations with <code>@starting-style</code>"
date: 2025-12-12
tags:
  - code
  - css
---

Want smooth fade-in animations when your `<dialog>` opens? The [`@starting-style`](https://developer.mozilla.org/en-US/docs/Web/CSS/@starting-style) CSS rule defines the initial state when an element first appears—no JavaScript needed.

```css
dialog {
  opacity: 1;
  scale: 1;
  transition: opacity 0.2s ease-out, scale 0.2s ease-out;

  @starting-style {
    opacity: 0;
    scale: 0.95;
  }
}
```

Without `@starting-style`, the browser renders the dialog immediately in its final state. With it, the browser starts from `opacity: 0; scale: 0.95` and transitions to `opacity: 1; scale: 1`.

You can animate the backdrop too:

```css
dialog::backdrop {
  background-color: rgb(0 0 0 / 0.5);
  transition: background-color 0.2s ease-out;

  @starting-style {
    background-color: rgb(0 0 0 / 0);
  }
}
```

Demo:

<img src="{{ '/images/dialog-starting-style.gif' | relative_url }}" alt="A dialog opening with a smooth fade-in and scale animation" style="width: 100%" />
