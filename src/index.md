---
# Feel free to add content and custom Front Matter to this file.

layout: default
---

<figure class="h-32 w-32">
  <img class="rounded-full" src="{{ '/images/headshot-2024.jpg' | relative_url }}" alt="This is my headshot" />
</figure>

# Stephen Margheim

Hey there! 👋

I'm full-stack Ruby on Rails Software Engineer, an Engineering Manager, and general web denizen. This is my personal website where I document my journey as a full stack developer and/or manager, as well as publish tutorials/write-ups of things I've learned for myself and others.

<a href="{{ '/about' | relative_url }}" class="no-underline">
  <span class="underline">Learn more about me</span>
  <i>→</i>
</a>

<a href="{{ '/posts' | relative_url }}" class="no-underline">
  <span class="underline">Read my most recent posts</span>
  <i>→</i>
</a>

<a href="{{ '/speaking' | relative_url }}" class="no-underline">
  <span class="underline">Checkout my recent speaking opportunities</span>
  <i>→</i>
</a>

<div>
  <span class="bold text-[var(--tw-prose-links)]">Connect with me</span>
  <i>↓</i>
  {% render "socials" %}
</div>