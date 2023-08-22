---
layout: page
title: Posts with tag <code>:prototype-term</code>
prototype:
  collection: posts
  term: tag
---

<a href="{{ '/posts' | relative_url }}" class="no-underline">
  <i>←</i>
  <span class="underline">All blog posts</span>
</a>

{% render "posts", collection: paginator.resources %}

{% render "pagination", paginator: paginator %}
