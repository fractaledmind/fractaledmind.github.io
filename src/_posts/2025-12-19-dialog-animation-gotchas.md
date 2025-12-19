---
title: Dialog Animation Gotchas
date: 2025-12-19
tags:
  - code
  - css
  - html
---

I spent way too long getting the animations right for my [dialog post]({% link _posts/2025-12-18-stylish-dialogs.md %}). Chrome's [documentation on entry/exit animations](https://developer.chrome.com/blog/entry-exit-animations) made it look simple—define your open state, your starting state, your closed state. Three blocks of CSS. Done.

The entry animation worked immediately. The exit was a disaster. The dialog snapped to full width mid-animation, jumped around, then vanished. The backdrop lingered after close, or disappeared instantly while the dialog was still fading. Nothing synced up.

I want to walk through each problem I hit and how I fixed it, partly as documentation for my future self, partly because I suspect these same issues will bite anyone trying to animate native dialogs.

<!--/summary-->

- - -

My first mistake was putting `@starting-style` in the wrong place. Chrome's docs show it as a separate block, but I tried nesting it inside the base `dialog` selector:

```css
dialog {
  opacity: 1;
  scale: 1;
  transition: /* ... */

  @starting-style {
    opacity: 0;
    scale: 0.95;
  }
}
```

Nothing. No animation.

The issue is that `@starting-style` defines where to animate *from* when an element enters a particular state. If you put it inside the base selector, it doesn't know what state you're entering. It needs to live inside `dialog[open]`:

```css
dialog[open] {
  opacity: 1;
  scale: 1;

  @starting-style {
    opacity: 0;
    scale: 0.95;
  }
}

dialog {
  transition: /* ... */
  opacity: 0;
  scale: 0.95;
}
```

The naming trips you up. "Starting style" sounds like "where this element starts"—the base state. But it means "where this element starts *when entering this specific state*."

Now the entry animation worked, but exit was still broken...

- - -

When the dialog closed, it snapped to full viewport width before animating out. I stared at this for a while before I thought to slow down the transition. Multiply your timings by 10x and you can actually *see* what's happening frame by frame.

The problem was obvious once I could watch it in slow motion. I had my layout styles on `dialog[open]`:

```css
dialog[open] {
  @apply flex w-full flex-col;
  @apply max-w-[calc(100vw-32px)];
  
  @variant sm {
    @apply max-w-md;
  }
}
```

The moment `[open]` gets removed, those constraints vanish. Mid-animation. The dialog loses `max-w-md` and expands while still fading out.

The fix is to put layout properties in the base selector. Only *animation* properties should differ between states:

```css
dialog {
  @apply flex w-full flex-col;
  @apply max-w-[calc(100vw-32px)];
  
  @variant sm {
    @apply max-w-md;
  }
  
  /* animation properties here */
}
```

This is the kind of thing that's obvious once you internalize it, but easy to miss when you're thinking about open vs. closed as entirely separate visual states. The dialog needs to maintain its structure throughout its entire lifecycle—including while it's animating away.

- - -

Next problem: the backdrop. It would fade in nicely, then stick around after the dialog closed. Or vanish instantly while the dialog was still animating.

The issue is that the backdrop's `overlay` and `display` durations need to match the dialog's. The color fade can be different, but the *visibility* timing has to stay in sync:

```css
dialog::backdrop {
  background-color: rgb(0 0 0 / 0);
  transition:
    background-color 0.05s ease-in-out,
    overlay 0.1s ease-in-out allow-discrete,
    display 0.1s ease-in-out allow-discrete;
}

dialog[open]::backdrop {
  background-color: rgb(0 0 0 / 0.2);
  transition:
    background-color 0.15s ease-in-out,
    overlay 0.2s ease-in-out allow-discrete,
    display 0.2s ease-in-out allow-discrete;

  @starting-style {
    background-color: rgb(0 0 0 / 0);
  }
}
```

Here the backdrop fades out quickly (0.05s) but stays *visible* for 0.1s while the dialog finishes its exit. The color and the visibility are decoupled, which gives you flexibility in how the animation feels without breaking the synchronization.

- - -

At this point I had working animations, but they mirrored each other—slide up on entry, slide down on exit. I wanted asymmetry: slide up on entry, scale down in place on exit. Sliding down on exit felt wrong to me; it implies the dialog is *going* somewhere, but it's not. It's disappearing. Scale-and-fade says "dismissed" without the false movement.

I tried different `transform` values for each state:

```css
dialog {
  transform: translateY(0) scale(0.95); /* Exit: just scale */
}

dialog[open] {
  transform: translateY(0) scale(1);
  
  @starting-style {
    transform: translateY(20px) scale(0.98); /* Entry: slide up */
  }
}
```

Both animations ended up as just scales. CSS transitions animate the shortest path—the exit always reverses from `dialog[open]` back to `dialog`. You can't get different paths with transitions alone.

Keyframes solve this by letting you define completely independent animations:

```css
@keyframes dialog-slide-up-scale-fade {
  from {
    opacity: 0;
    transform: translateY(20px) scale(0.98);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

@keyframes dialog-scale-down-fade {
  from {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
  to {
    opacity: 0;
    transform: translateY(0) scale(0.95);
  }
}

dialog {
  animation: dialog-scale-down-fade 0.1s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  transition:
    overlay 0.1s cubic-bezier(0.16, 1, 0.3, 1) allow-discrete,
    display 0.1s cubic-bezier(0.16, 1, 0.3, 1) allow-discrete;
}

dialog[open] {
  animation: dialog-slide-up-scale-fade 0.2s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  transition:
    overlay 0.2s cubic-bezier(0.16, 1, 0.3, 1) allow-discrete,
    display 0.2s cubic-bezier(0.16, 1, 0.3, 1) allow-discrete;

  @starting-style {
    animation: none;
  }
}
```

Entry and exit are now independent. Transitions still handle `overlay` and `display` (they need `allow-discrete` because they're discrete properties). The `@starting-style { animation: none; }` prevents the exit animation from firing on page load—without it, the dialog animates closed the moment the page renders.

- - -

One more issue: using `display: flex` on the base `dialog` meant it rendered briefly on page load. A flash of the styled dialog before it settled into its hidden state.

`pointer-events: none` fixed interaction but not the visual flash. The actual fix is to hide it properly:

```css
dialog {
  visibility: hidden;
  pointer-events: none;
}

dialog[open] {
  visibility: visible;
  pointer-events: auto;
}
```

- - -

Here's where I landed. Timing lives in CSS variables so changing entry duration cascades everywhere:

```css
dialog {
  --dialog-entry-duration: 0.2s;
  --dialog-exit-duration: calc(var(--dialog-entry-duration) / 2);
  --backdrop-entry-duration: calc(var(--dialog-entry-duration) * 0.75);
  --backdrop-exit-duration: calc(var(--dialog-exit-duration) / 2);
  --dialog-easing: cubic-bezier(0.16, 1, 0.3, 1);
  --backdrop-easing: ease-in-out;

  /* Layout stays constant throughout lifecycle */
  @apply flex w-full flex-col max-w-[calc(100vw-32px)];
  @variant sm { @apply max-w-md; }

  visibility: hidden;
  pointer-events: none;

  animation: dialog-scale-down-fade var(--dialog-exit-duration) var(--dialog-easing) forwards;
  transition:
    overlay var(--dialog-exit-duration) var(--dialog-easing) allow-discrete,
    display var(--dialog-exit-duration) var(--dialog-easing) allow-discrete;
}

dialog[open] {
  visibility: visible;
  pointer-events: auto;

  animation: dialog-slide-up-scale-fade var(--dialog-entry-duration) var(--dialog-easing) forwards;
  transition:
    overlay var(--dialog-entry-duration) var(--dialog-easing) allow-discrete,
    display var(--dialog-entry-duration) var(--dialog-easing) allow-discrete;

  @starting-style {
    animation: none;
  }
}

dialog::backdrop {
  background-color: rgb(0 0 0 / 0);
  transition:
    background-color var(--backdrop-exit-duration) var(--backdrop-easing),
    overlay var(--dialog-exit-duration) var(--backdrop-easing) allow-discrete,
    display var(--dialog-exit-duration) var(--backdrop-easing) allow-discrete;
}

dialog[open]::backdrop {
  background-color: rgb(0 0 0 / 0.2);
  transition:
    background-color var(--backdrop-entry-duration) var(--backdrop-easing),
    overlay var(--dialog-entry-duration) var(--backdrop-easing) allow-discrete,
    display var(--dialog-entry-duration) var(--backdrop-easing) allow-discrete;

  @starting-style {
    background-color: rgb(0 0 0 / 0);
  }
}
```

Exit runs at half speed (entrances should feel intentional; exits get out of the way). Backdrop color fades faster than dialog content. Backdrop visibility stays synced with dialog.

- - -

None of this is complicated once you understand it. But it took me hours to get here, mostly because the failure modes are so disorienting—things jumping, flickering, desynchronizing in ways that don't immediately point to the cause. The 10x slowdown trick was the breakthrough. Once I could see each frame, the fixes became obvious.

If you want to dig deeper into the CSS features at play here, MDN has solid documentation on [`@starting-style`](https://developer.mozilla.org/en-US/docs/Web/CSS/@starting-style), the [`overlay`](https://developer.mozilla.org/en-US/docs/Web/CSS/overlay) property, and [`allow-discrete`](https://developer.mozilla.org/en-US/docs/Web/CSS/transition-behavior). But honestly, the best way to learn this stuff is to break it, slow it down, and watch what happens.
