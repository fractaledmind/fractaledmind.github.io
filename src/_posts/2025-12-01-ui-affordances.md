---
title: "Affordances: The Missing Layer in Frontend Architecture"
date: 2025-12-01
tags:
  - code
  - css
  - frontend
---

I was building a form with a file input. Nothing fancy—just a place for users to upload a document. I wanted the trigger to look like the other buttons on the page: the same subtle shadows, the same hover effects, the same spacing. I was using [Catalyst](https://catalyst.tailwindui.com), the component kit from Tailwind Labs, so I had a `<Button>` component with all those styles baked in.

But I couldn't use it.

A file input needs a `<label>` as its clickable element—that's how you style file inputs without fighting the browser's native UI. But Catalyst's `<Button>` component only renders as a `<button>` element or a `<Link>`. There's no way to apply those styles to a `<label>`.

Some component libraries offer escape hatches—props like `asChild` or `render` that let you swap out the underlying element. But these props don't just pass through styles; they pass through the component's *behavior* too. That's fine when you want both. But when you just need the *look*—when you need an element to *appear* clickable while retaining its own native semantics—components leave you stuck.

This isn't a bug in Catalyst. It's a structural limitation of components as an abstraction. **Components are poor vehicles for purely visual styles.** And once you see this, you start seeing it everywhere.

-----

## Three Things, One Name

Consider the word "button." In frontend development, it actually refers to three genuinely distinct things:

1. The `<button>` **element** — native HTML semantics and behavior
2. The `Button` **component** — your library's encapsulation of structure, behavior, and possibly styles
3. The `button` **visual pattern** — rounded corners, padding, solid background, hover states; what makes something *look* clickable

When you need to make a `<label>` look like a `<button>`, you can't reach for an element or a component.

The same is true for text inputs. There's the element, the component, and the visual pattern—the border, the focus ring, the placeholder styling—that makes something *look* like a place to type. You might need that pattern on a `<textarea>`, a `<select>`, or a custom autocomplete built on a different element entirely.

These visual patterns have a name in design theory: **affordances**—visual signals that communicate how an element can be interacted with. The term comes from Don Norman's *The Design of Everyday Things*, where he described how the shape of a door handle tells you whether to push or pull. In interfaces, affordances are what make a button look pressable, an input look typeable, a link look clickable.

The standard frontend architecture today needs to add this as the fourth conceptual layer:

| Layer           | What It Is                              | Example                        |
|-----------------|-----------------------------------------|--------------------------------|
| **Tokens**      | Atomic design values                    | `--color-indigo-600`, `--spacing-4` |
| **Utilities**   | Single-purpose classes                  | `p-4`, `text-red-500`          |
| **Affordances** | Element-independent visual patterns     | `.ui-button`, `.ui-input`, `.ui-card` |
| **Components**  | Encapsulated structure + behavior       | `<Button>`, `<Dialog>`         |

Most libraries today bury affordances inside components. That's the friction I hit with that file input—and I suspect you've hit it too. Isolating and naming the affordance layer restores the needed flexibility.

-----

## Unnecessary Pain

I love utility classes. I advocate for Tailwind in every team I work with. But when you don't have an affordance layer and your team enforces a utility-only approach, every element that needs to look interactive gets its own pile of the same classes:

```html
<label class="inline-flex items-center rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600">
  Upload file
</label>
```

And every other element that needs that same treatment—an `<a>` styled as a button, a `<summary>`, a `<div role="button">`—gets its own copy of those same fourteen classes.

This creates three concrete problems. First, there's no single source of truth. When the design changes—when `blue-600` becomes `indigo-600`, or the border radius shifts from `rounded-md` to `rounded-lg`—you're hunting through your codebase for every instance. Find-and-replace helps, but only if the classes appear in the same order, with the same formatting, across every file. They won't.

Second, the abstraction leaks into component APIs. Without an affordance layer, you end up passing styling props through components or accepting arbitrary `className` strings that get merged in unpredictable ways. The component boundary, which should encapsulate complexity, becomes a surface for styling conflicts.

Third, consistency degrades over time. One developer uses `hover:bg-indigo-500`. Another uses `hover:bg-indigo-600`. A third forgets the focus styles entirely. No single element is *wrong*, but the product slowly becomes a patchwork. There's no abstraction enforcing that "things which afford clicking should look like *this*."

Beyond the pain of such a utility-only approach, we also feel the need to isolate purely presentational styles from purely behavioral components. That's why headless libraries—[Base UI](https://base-ui.com), [Headless UI](https://headlessui.com), [Radix UI](https://www.radix-ui.com)—have swept through the frontend community like wildfire. We know behavior and styling need to be decoupled.

Headless libraries solved half the problem. They gave us components that handle accessibility, keyboard navigation, focus management—all the behavioral complexity—without dictating appearance.

But they left the styling half unsolved. Without a clear concept for that layer, most developers just inline utilities everywhere. And that brings us right back to the problems above: no single source of truth, leaky component APIs, consistency drift.

Affordances solve this other half.

-----

## "We Tried That. It Didn't Work."

I hear the objection already: "Isn't this just... semantic CSS classes? We tried that."

You're right that we tried it. But "it didn't work" deserves unpacking.

The problem with traditional semantic classes like `.btn` wasn't the concept—it was the execution. In a utility-first world, semantic classes create specificity conflicts. If you write `.btn { background: blue; }`, that rule has a specificity of `0,1,0`. When you try to customize with a utility like `bg-red-500`, the utility *also* has specificity `0,1,0`. Order-dependent chaos ensues. You end up fighting the cascade instead of working with it.

Many developers who were burned by Bootstrap's specificity nightmares found Tailwind and subsequently internalized "never write semantic classes" as a hard rule. That lesson may have been correct *at the time*, but the platform has evolved.

CSS now has [cascade layers](https://developer.mozilla.org/en-US/docs/Web/CSS/@layer)—a feature designed precisely for this problem. Layers let you define explicit priority ordering for groups of styles, independent of specificity or source order. Styles in later layers always beat styles in earlier layers, regardless of selector specificity.

This means you can put affordances in a layer that sits *below* utilities:

```css
@layer affordances, utilities;

@layer affordances {
  .ui-button {
    display: inline-flex;
    align-items: center;
    padding: var(--spacing-2) var(--spacing-4);
    border-radius: var(--rounded-md);
    background-color: var(--color-indigo-600);
    color: var(--color-white);
    font-size: var(--text-sm);
    font-weight: var(--font-semibold);
    box-shadow: var(--shadow-sm);

    &:hover {
      background-color: var(--color-indigo-500);
    }

    &:focus-visible {
      outline: 2px solid var(--color-indigo-600);
      outline-offset: 2px;
    }
  }
}
```

Now any utility in the `utilities` layer will override `.ui-button`, no matter how specific the affordance selector is. Tailwind v4 already uses layers internally, so your utilities will naturally win.

For extra safety—or if you're working with CSS that doesn't use layers—you can also wrap selectors in [`:where()` pseudo-class](https://developer.mozilla.org/en-US/docs/Web/CSS/:where), which contributes zero specificity:

```css
@layer affordances {
  :where(.ui-button) {
    /* ... */
  }
}
```

Now `.ui-button` has zero specificity *and* lives in a lower layer. Belt and suspenders.

```html
<button class="ui-button bg-red-600 hover:bg-red-500">Delete</button>
```

The `bg-red-600` utility wins. No `!important`, no specificity wars, no awkward workarounds. The affordance provides sensible defaults; utilities customize as needed.

{:.notice}
**NOTE:** I use the `ui-` prefix to distinguish affordance classes from old-school semantic classes. When you see `.btn`, you might reasonably wonder if it's a Bootstrap remnant with unpredictable specificity. When you see `.ui-button`, the prefix signals intent: this is a low-specificity visual pattern designed to compose with utilities. Pick whatever convention works for your team: `af-`, `look-`, or just go unprefixed if you're starting fresh—but having *a* convention helps communicate that these aren't last decade's semantic classes.

This isn't a return to 2015. It's a genuinely new capability. Cascade layers and `:where()` achieved broad browser support in 2022, and we're only now catching up to what they enable. The tooling is ready. It's time for our concepts, terminology, and best practices to follow.

-----

## In Practice

Remember that file input from the opening? Here's how it looks with an affordance layer:

```html
<label for="document-upload" class="ui-button">
  Choose file
</label>
<input type="file" id="document-upload" class="sr-only" />
```

That's it. The `<label>` gets the button affordance. The `<input>` is visually hidden but remains accessible. The `<label>` retains its native behavior—clicking it still triggers the file picker. No component gymnastics, no escape hatches, no fighting the framework.

If Catalyst shipped a `.ui-button` affordance class alongside its `<Button>` component, I never would have been stuck. The component could still encapsulate behavior for the common case. But when I needed just the *look*—for a `<label>`, a `<summary>`, an `<a>`, whatever—I'd have a clean path forward.

"What about primary, secondary, and destructive button variants?" I hear you ask. You have two options.

The first is to define variant affordance classes:

```css
@layer affordances {
  :where(.ui-button-secondary) {
    background-color: var(--color-gray-100);
    color: var(--color-gray-900);
    &:hover { background-color: var(--color-gray-200); }
  }

  :where(.ui-button-danger) {
    background-color: var(--color-red-600);
    &:hover { background-color: var(--color-red-500); }
  }
}
```

The second is to use a base affordance and compose with utilities:

```html
<button class="ui-button bg-red-600 hover:bg-red-500">Delete</button>
```

I prefer the composition approach for one-offs and the variant classes for patterns that repeat across your codebase. The zero-specificity foundation makes both work seamlessly.

-----

## A Call to Library Authors

If you maintain a component library, consider this: **ship affordances alongside your components**.

Your `<Button>` component is valuable. It handles click events, loading states, disabled styling, maybe even analytics. Keep all of that.

But also ship a `.ui-button` class (or whatever naming convention you prefer) that carries *just* the visual treatment. Let developers apply that class to any element they need. Use `@layer` and `:where()` to ensure it composes cleanly with utilities.

The same goes for inputs, cards, badges, and every other visual pattern in your system. The component is the opinionated, full-featured path. The affordance is the escape hatch—the flexibility that lets developers solve problems you didn't anticipate.

This is the shift I'm advocating for: stop treating visual patterns as implementation details of components. Expose them as first-class primitives. Use `:where()` to make them composable with utilities. Let developers apply them to any element, for any reason, without gymnastics.

-----

## The Way Forward

The `<button>` element, the `Button` component, and the `.ui-button` affordance are three different things. Modern frontend architecture should treat them that way.

We've spent years learning to separate concerns—content from presentation, structure from styling, behavior from appearance. Headless libraries gave us behavioral components without visual opinions. But we stopped halfway. We decoupled behavior from styling, then immediately coupled styling back to specific elements by inlining utilities everywhere.

Affordances complete the separation. They give us reusable visual patterns that work with any element, compose cleanly with utilities, and provide a single source of truth for how interactive elements should look.

With `@layer` and `:where()`, we finally have the technical foundation to make this work without specificity conflicts. The only thing missing is the shift in how we think about our CSS architecture.
