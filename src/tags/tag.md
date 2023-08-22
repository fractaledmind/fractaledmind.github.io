---
layout: page
title: Posts with tag :prototype-term
prototype:
  collection: posts
  term: tag
---

<a href="{{ '/' | relative_url }}" class="no-underline">
  <i>←</i>
  <span class="underline">All blog posts</span>
</a>

{% render "posts", collection: paginator.resources %}

{% render "pagination", paginator: paginator %}
