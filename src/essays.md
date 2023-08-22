---
layout: page
title: Essays
---

{% assign essaysByYear = collections.essays.resources | group_by_exp: "essay", "essay.date | date: '%Y'" %}
{% for year in essaysByYear %}
  <h2>{{ year.name }}</h2>
  <ul>
    {% for essay in year.items %}
      <li>
        <a href="{{ essay.relative_url }}">
          {{ essay.data.title }}{% if essay.data.subtitle %}: {{ essay.data.subtitle }}{% endif %}
          {{ essay.data.date | date: "%Y" }}
        </a>
      </li>
    {% endfor %}
  </ul>
{% endfor %}
