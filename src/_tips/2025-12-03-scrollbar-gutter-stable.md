---
series: Stylish HTML
title: "Avoid layout shift with <code>scrollbar-gutter: stable</code>"
date: 2025-12-03
tags:
  - code
  - css
---

Want to avoid layout shift when you remove scrolling on popover or dialog opening? Use the [`scrollbar-gutter: stable`](https://developer.mozilla.org/en-US/docs/Web/CSS/scrollbar-gutter) CSS rule on your scroll container (likely `<body>`).

```css
body {
  scrollbar-gutter: stable;

  &:has(:popover-open) {
    overflow: hidden;
  }
}
```

The problem: when a popover opens and you hide the scrollbar with `overflow: hidden`, the content shifts horizontally to fill the space where the scrollbar was.

<img src="{{ '/images/scrollbar-layout-shift.gif' | relative_url }}" alt="A popover opening causes the page content to shift horizontally as the scrollbar disappears" style="width: 100%" />

The solution: `scrollbar-gutter: stable` reserves space for the scrollbar even when it's not visible, preventing the jarring horizontal shift.

<img src="{{ '/images/scrollbar-layout-shift-fixed.gif' | relative_url }}" alt="With scrollbar-gutter stable, the page content stays in place when the popover opens" style="width: 100%" />
