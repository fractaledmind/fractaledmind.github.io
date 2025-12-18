---
series: Stylish HTML
title: "Anchor position fallbacks with <code>position-try-fallbacks</code>"
date: 2025-12-14
tags:
  - code
  - css
typefully_published: true
---

What happens when your anchored popover runs out of space? With [`position-try-fallbacks`](https://developer.mozilla.org/en-US/docs/Web/CSS/position-try-fallbacks), the browser automatically tries alternative positions—no JavaScript resize observers needed.

```css
[popover] {
  /* Primary position: bottom-right of anchor */
  position-area: span-right bottom;
  
  /* If that doesn't fit, try these in order */
  position-try-fallbacks: --bottom, --span-left-bottom;
}

@position-try --bottom {
  position-area: bottom;
}

@position-try --span-left-bottom {
  position-area: span-left bottom;
}
```

The [`position-area`](https://developer.mozilla.org/en-US/docs/Web/CSS/position-area) property positions the element relative to its anchor using a 3x3 grid. Values like `span-right bottom` mean "span the center and right columns, in the bottom row."

When the primary position causes overflow, the browser tries each fallback in order until one fits. Define fallbacks with [`@position-try`](https://developer.mozilla.org/en-US/docs/Web/CSS/@position-try) blocks.

Common position-area values:

- **`bottom`** — Centered below the anchor
- **`span-right bottom`** — Below, spanning center to right
- **`span-left bottom`** — Below, spanning left to center
- **`top`** — Centered above the anchor

Built-in flip fallbacks also exist:

```css
[popover] {
  position-area: bottom;
  /* Flip to top if bottom overflows */
  position-try-fallbacks: flip-block;
}
```

This gives you the adaptive positioning of JavaScript libraries like Floating UI, but with zero JavaScript and better performance.
