---
title: Writing Tailwind-compatible Semantic CSS
date: 2026-01-02
tags:
  - code
  - css
  - tailwind
---

Building [HTML UI](https://html-ui.com) forced me to figure out how to write reusable CSS classes that play nice with Tailwind. Along the way, I looked at how other libraries tackle this. Spoiler: most of them get it wrong.

<!--/summary-->

- - -

Let me show you two approaches I found, then I'll show you what I landed on.

Here's how [Basecoat](https://github.com/hunvreus/basecoat) defines a badge:

```css
@layer components {
  .badge,
  .badge-primary,
  .badge-secondary,
  .badge-destructive,
  .badge-outline {
    @apply inline-flex items-center justify-center rounded-full border px-2 py-0.5 text-xs font-medium w-fit whitespace-nowrap shrink-0 [&>svg]:size-3 gap-1 [&>svg]:pointer-events-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive transition-[color,box-shadow] overflow-hidden;
  }
}
```

One line. Every variant lumped together. State styles crammed in with bracket notation.

[DaisyUI](https://github.com/saadeghi/daisyui) does something kinda similar but also notably different:

```css
.badge {
  @layer daisyui.l1.l2.l3 {
    @apply rounded-selector inline-flex items-center justify-center gap-2 align-middle;
    color: var(--badge-fg);
    border: var(--border) solid var(--badge-color, var(--color-base-200));
    font-size: 0.875rem;
    width: fit-content;
    background-size: auto, calc(var(--noise) * 100%);
    background-image: none, var(--fx-noise);
    background-color: var(--badge-bg);
    --badge-bg: var(--badge-color, var(--color-base-100));
    --badge-fg: var(--color-base-content);
    --size: calc(var(--size-selector, 0.25rem) * 6);
    height: var(--size);
    padding-inline: calc(var(--size) / 2 - var(--border));
  }
}
```

Mixes `@apply` with raw CSS. Custom properties everywhere. Nested inside a layer with a bizarre naming scheme.

## What's Wrong

Both approaches share three problems:

| Problem | Why It Hurts |
|---------|--------------|
| **No tree-shaking** | `@layer` ships everything, used or not. Define 20 classes, ship 20 classes. |
| **No autocomplete** | Tailwind's IntelliSense doesn't know these classes exist. Developers can't discover them. |
| **Unreadable states** | All those `focus-visible:` and `dark:aria-invalid:` prefixes become a wall of noise. |

## My Approach

Here's how I write my badge class in HTML UI:

```css
@utility ui-badge {
  :where(&) {
    @apply inline-flex items-center justify-center rounded-full border px-2 py-0.5 text-xs font-medium w-fit whitespace-nowrap shrink-0 gap-1 transition-[color,box-shadow] overflow-hidden border-transparent bg-primary text-primary-foreground;

    & > svg {
      @apply size-3 pointer-events-none;
    }

    @variant hover {
      @apply bg-primary/90;
    }

    @variant focus-visible {
      @apply border-ring ring-ring/50 ring-[3px];
    }

    @variant aria-invalid {
      @apply ring-destructive/20 border-destructive;
    }
  }

  @variant dark {
    :where(&) {
      @variant aria-invalid {
        @apply ring-destructive/40;
      }
    }
  }
}
```

Same basic visual result. Completely different structure. Let me break down why this is better.

- - -

## `@utility` gives you tree-shaking and autocomplete

Classes defined with `@utility` only ship if they're used in your markup. Define twenty, use three, ship three. That's the essential Tailwind contract, and `@layer` breaks it.

`@utility` also registers with IntelliSense. Type your prefix in your editor and see every affordance. Discoverability matters. If developers can't find your class, they'll reinvent it inline.

## A prefix like `ui-` makes affordances obvious

When you see `.btn` in a codebase, you have no idea what you're dealing with. Is it Bootstrap? Some old semantic class with unpredictable specificity? A utility?

A prefix solves this. `ui-button` signals intent: this is a zero-specificity visual pattern designed to compose with utilities. It's not last decade's semantic CSS.

The prefix also makes autocomplete useful. Type `ui-` and you see every affordance in the system. Pick whatever convention works for your team—`af-`, `look-`, whatever—but having *a* convention communicates that these classes play by different rules.

## `:where()` gives you zero specificity

Utilities in `@utility` live in Tailwind's utilities layer—highest priority. That's normally what you want. But affordance classes should be *overridable* by utilities.

`:where()` contributes zero specificity. So `:where(.ui-badge)` has specificity `0,0,0`, while `bg-red-500` has `0,1,0`. The utility always wins:

```html
<span class="ui-badge bg-red-500">Error</span>
```

No `!important`. No cascade conflicts. The affordance provides defaults; utilities customize.

## `@variant` gives you readable state styles

Compare the Basecoat approach:

```css
@apply focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40;
```

To this:

```css
@variant focus-visible {
  @apply border-ring ring-ring/50 ring-[3px];
}

@variant aria-invalid {
  @apply ring-destructive/20 border-destructive;
}

@variant dark {
  :where(&) {
    @variant aria-invalid {
      @apply ring-destructive/40;
    }
  }
}
```

Each state gets its own block. You can see at a glance what changes on focus, what changes when invalid, what changes in dark mode. The structure matches how you *think* about states.

There's also a practical reason: `@apply hover:bg-red-500` [can break in Svelte/Vue `<style>` blocks](https://github.com/tailwindlabs/tailwindcss/discussions/17993) because the colon gets parsed as CSS syntax before Tailwind processes it. `@variant` sidesteps this entirely.

## `@apply` makes compatibility a non-issue

You might wonder why I use `@apply` instead of raw CSS. The answer is compatibility.

When you write `@apply bg-primary text-sm px-2`, you're referencing the user's Tailwind theme. Their colors. Their spacing scale. Their typography. If they've customized `primary` to be orange instead of indigo, your affordance automatically uses orange. If they use a non-standard spacing scale, `px-2` resolves to whatever *they* defined.

DaisyUI's approach—defining its own custom properties like `--badge-fg` and `--color-base-200`—creates a parallel design system. Users have to map their tokens to DaisyUI's tokens. That's friction.

`@apply` eliminates that friction. Your affordances speak the same language as the user's utilities because they *are* the user's utilities, just composed.

- - -

Tailwind v4's `@utility`, `@apply`, and `@variant` directives aren't just new syntax. Combined with `:where()`, they let you write semantic CSS classes that are discoverable, tree-shakeable, readable, and composable with utilities.

That's the approach. Now go build something.
