---
series: Design Tips
title:
date: 2025-04-12
tags:
  - code
  - css
  - responsive-design
---



<!--/summary-->

- - -


<button type="button" class="text-white bg-gray-800 hover:bg-gray-900 focus:outline-none focus:ring-4 focus:ring-gray-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-gray-800 dark:hover:bg-gray-700 dark:focus:ring-gray-700 dark:border-gray-700">Dark</button>



```css
@layer components {
  :where([ui=button]):not([ui-variant]) {
    --btn-bg: var(--color-zinc-900);
    --btn-border: var(--color-zinc-950)/90;
    --btn-hover-overlay: var(--color-white)/10;
    --btn-icon: var(--color-zinc-400);

    @apply
      border-transparent
      bg-(--btn-border)
      text-white
      active:[--btn-icon:var(--color-zinc-300)]
      dark:bg-(--btn-bg)
      dark:border-white/5
      dark:[--btn-bg:var(--color-zinc-600)]
      dark:[--btn-hover-overlay:var(--color-white)]/5;

    &:hover:not(:disabled) {
      @apply
        after:bg-(--btn-hover-overlay)
        [--btn-icon:var(--color-zinc-300)];
    }
    &::before {
      @apply
        absolute
        inset-0
        -z-10
        rounded-[calc(var(--radius-lg)-1px)]
        bg-(--btn-bg)
        shadow-sm
        dark:hidden
        disabled:shadow-none
    }
    &::after {
      @apply
        absolute
        inset-0
        -z-10
        rounded-[calc(var(--radius-lg)-1px)]
        shadow-[shadow:inset_0_1px_--theme(--color-white/15%)]
        active:bg-(--btn-hover-overlay)
        dark:-inset-px
        dark:rounded-lg
        disabled:shadow-none
    }
  }
  :where([ui=button]) {
    @apply
      relative
      isolate
      inline-flex
      items-baseline
      justify-center
      gap-x-2
      rounded-lg
      border
      text-base/6
      font-semibold
      px-[calc(--spacing(3.5)-1px)]
      py-[calc(--spacing(2.5)-1px)]
      sm:px-[calc(--spacing(3)-1px)]
      sm:py-[calc(--spacing(1.5)-1px)]
      sm:text-sm/6
      focus:outline-hidden
      focus:outline-2
      focus:outline-offset-2
      focus:outline-blue-500
      disabled:opacity-50
      *:data-[slot=icon]:-mx-0.5
      *:data-[slot=icon]:my-0.5
      *:data-[slot=icon]:size-5
      *:data-[slot=icon]:shrink-0
      *:data-[slot=icon]:self-center
      *:data-[slot=icon]:text-(--btn-icon)
      sm:*:data-[slot=icon]:my-1
      sm:*:data-[slot=icon]:size-4
      forced-colors:[--btn-icon:ButtonText]
      forced-colors:hover:[--btn-icon:ButtonText]
      dark:text-white
      cursor-default;
  }
}
```
