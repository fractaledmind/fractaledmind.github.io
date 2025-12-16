---
series: Stylish HTML
title: "Auto-growing textareas with <code>field-sizing: content</code>"
date: 2025-12-07
tags:
  - code
  - css
typefully_published: true
---

Coming in the next version of Safari, and already in Chrome and Edge, you can now create `<textarea>`s that auto-grow with the [`field-sizing: content`](https://developer.mozilla.org/en-US/docs/Web/CSS/field-sizing) rule.

```css
textarea {
  field-sizing: content;
  min-block-size: attr(rows rlh);
}
```

The `min-block-size: attr(rows rlh)` ensures the textarea still respects its `rows` attribute as a minimum height, using the `rlh` unit (root line height).

Demo:

<img src="{{ '/images/field-sizing-content.gif' | relative_url }}" alt="A textarea that automatically grows as the user types more content" style="width: 100%" />
