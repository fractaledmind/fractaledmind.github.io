---
series: Stylish HTML
title: "Dropdown menus with <code>popover</code> and <code>popovertarget</code>"
date: 2025-12-15
tags:
  - code
  - html
---

The [`popover`](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/popover) attribute and [`popovertarget`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button#popovertarget) give you dropdown menus with light-dismiss behavior—no JavaScript required.

```html
<button type="button" popovertarget="dropdown-menu">
  Options
</button>

<nav id="dropdown-menu" popover>
  <ul>
    <li><a href="/settings">Settings</a></li>
    <li><a href="/profile">Profile</a></li>
    <li><a href="/logout">Logout</a></li>
  </ul>
</nav>
```

Click the button—the menu opens. Click outside or press Escape—the menu closes. That's it.

What you get for free:

- **Light dismiss** — Clicking outside or pressing Escape closes the popover
- **Top-layer rendering** — Popovers render above all other content, no `z-index` battles
- **Focus management** — Focus moves into the popover and returns when closed
- **No scroll lock** — Unlike modal dialogs, the page remains scrollable

For breadcrumb navigation with dropdown switchers:

```html
<li>
  <a href="/org/acme">Acme Corp</a>
  <button type="button" popovertarget="org-switcher">▾</button>
  
  <nav id="org-switcher" popover>
    <ul>
      <li><a href="/org/acme">Acme Corp ✓</a></li>
      <li><a href="/org/globex">Globex Inc</a></li>
      <li><a href="/org/new">+ New organization</a></li>
    </ul>
  </nav>
</li>
```

Each breadcrumb segment can have its own popover for switching between items at that level—organizations, projects, environments—without any JavaScript toggle logic.

Combine with [CSS anchor positioning]({% link _tips/2025-12-05-anchor-popovers-with-attr.md %}) and [position fallbacks]({% link _tips/2025-12-14-position-try-fallbacks.md %}) for pixel-perfect dropdown placement.

