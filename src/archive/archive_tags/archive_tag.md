---
layout: page
title: Archived posts with tag <code>:prototype-term</code>
prototype:
  collection: archive
  term: archive_tag
pagination:
  title: ':title'
---

<a href="{{ '/archive' | relative_url }}" class="no-underline">
  <i>←</i>
  <span class="underline">All archived posts</span>
</a>

{% render "posts", collection: paginator.resources %}

{% render "pagination", paginator: paginator %}
