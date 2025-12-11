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

Most recently, I've been working on in-depth video course on Rails + SQLite for beginners called [High Leverage Rails](https://highleveragerails.com). Check it out if you're interested in learning Rails how to take advantage of the power of Rails and SQLite to kickstart your dreams.

### Like what you’re reading here? If so:

<script src="https://f.convertkit.com/ckjs/ck.5.js"></script>
<form action="https://app.kit.com/forms/8864509/subscriptions" 
      method="post" 
      data-sv-form="8864509" 
      data-uid="3828f413d7">
  <ul data-element="errors"></ul>
  <input type="email" name="email_address" placeholder="Enter your email..." required class="search-input" style="min-width: 50%;">
  <span>and</span>
  <button data-element="submit" style="color: var(--tw-prose-links); font-weight: 500;">
    <span class="underline">Subscribe</span>
    <i>➹</i>
  </button> 
</form>

<hr>

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