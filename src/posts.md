---
layout: page
title: Posts
paginate:
  collection: posts
  title: ':title'
---

{% render "posts", collection: paginator.resources %}

{% render "pagination", paginator: paginator %}