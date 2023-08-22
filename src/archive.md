---
layout: page
title: Archive
---

{% assign postsByYear = collections.archive.resources | group_by_exp: "post", "post.date | date: '%Y'" %}
{% for year in postsByYear %}
  <h2>{{ year.name }}</h2>
  <ul>
    {% for post in year.items %}
      <li>
        <a href="{{ post.relative_url }}">
          {{ post.data.title }}{% if post.data.subtitle %}: {{ post.data.subtitle }}{% endif %}
        </a>
      </li>
    {% endfor %}
  </ul>
{% endfor %}
