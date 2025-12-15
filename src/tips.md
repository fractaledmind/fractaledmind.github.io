---
layout: page
title: Tips
paginate:
  collection: tips
  per_page: 5
  title: ':title'
---

{% render "tips_feed", collection: paginator.resources %}

{% render "pagination", paginator: paginator %}
