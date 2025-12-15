---
series: Stylish HTML
title: "Dialog exit animations with <code>allow-discrete</code>"
date: 2025-12-13
tags:
  - code
  - css
---

Enter animations are easy with `@starting-style`, but exit animations need [`transition-behavior: allow-discrete`](https://developer.mozilla.org/en-US/docs/Web/CSS/transition-behavior) to work. Most CSS properties are continuous—opacity can be 0.5, colors can blend. But `display` is discrete: it's either `none` or `block`, with no intermediate values.

The `allow-discrete` keyword tells the browser to apply transition timing even for discrete properties. For closing animations, the browser keeps the element visible, runs the exit transition, then flips to `display: none` only after the transition completes.

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
```

The `overlay` property controls whether the dialog stays in the [top layer](https://developer.mozilla.org/en-US/docs/Glossary/Top_layer) during the transition—without it, the dialog would immediately drop behind other content.

Don't forget the backdrop:

```css
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

Demo:

<img src="{{ '/images/dialog-allow-discrete.gif' | relative_url }}" alt="A dialog closing with a smooth fade-out animation" style="width: 100%" />
