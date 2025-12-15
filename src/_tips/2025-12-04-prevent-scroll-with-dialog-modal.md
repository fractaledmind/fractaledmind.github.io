---
series: Stylish HTML
title: "Prevent Scrolling when a Dialog is open"
date: 2025-12-04
tags:
  - code
  - css
---

Want to prevent scrolling when a modal dialog is open? Use the [`:modal`](https://developer.mozilla.org/en-US/docs/Web/CSS/:modal) pseudo-class with `body:has()` to disable scrolling purely in CSS—no JavaScript needed.

```css
body:has(dialog:modal) {
  overflow: hidden;
}
```

Demo:

<img src="{{ '/images/dialog-open-prevent-scroll.gif' | relative_url }}" alt="A modal dialog opens and the page behind it cannot be scrolled" style="width: 100%" />

The `:modal` pseudo-class matches elements that are in a state where they exclude all interaction with elements outside of it until the interaction has been dismissed. This includes dialogs opened with `showModal()`.
