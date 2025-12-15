---
series: Stylish HTML
title: "De-emphasize scrollbars in small containers"
date: 2025-12-06
tags:
  - code
  - css
---

Have a small scroll container where you want to de-emphasize the scrollbar, like in a popover? Say hello to [`scrollbar-color`](https://developer.mozilla.org/en-US/docs/Web/CSS/scrollbar-color) and [`scrollbar-width`](https://developer.mozilla.org/en-US/docs/Web/CSS/scrollbar-width).

```css
::picker(select) {
  scrollbar-color: lightgray transparent;
  scrollbar-width: thin;
}
```

The `scrollbar-color` property sets the thumb and track colors (here, light gray on transparent), while `scrollbar-width` can be set to `thin` for a more subtle appearance.

Demo:

<img src="{{ '/images/scrollbar-styling.gif' | relative_url }}" alt="A select dropdown with a subtle, thin scrollbar" style="width: 100%" />
