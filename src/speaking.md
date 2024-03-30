---
layout: page
title: Speaking Opportunities
---

<ul class="list-none !pl-0">
  {% for opportunity in site.data.speaking %}
    <li class="border-t border-dashed border-[var(--tw-prose-body)] py-16">
      <aside role="note" class="text-[var(--tw-prose-captions)] !text-sm lg:!text-base mb-4">
        <time datetime="{{ opportunity.date | date: "%Y-%m-%dT%H:%M:%SZ" }}">{{ opportunity.date | date: "%B %d, %Y" }}</time>
        · <a href="{{ opportunity.show.link }}" class="no-underline font-normal text-inherit italic hover:underline">{{ opportunity.show.name }}</a>
        {% if opportunity.type == "upcoming" %}
        · <span>upcoming</span>
        {% endif %}
      </aside>
      <h2 class="!text-2xl !mt-0">
        {% if opportunity.type == "podcast" %}
        <span>🎙️</span>
        {% elsif opportunity.type == "talk" %}
        <span>📺️</span>
        {% elsif opportunity.type == "presentation" %}
        <span>📽️</span>
        {%- elsif opportunity.type == "upcoming" -%}
        <span>🎟</span>
        {% endif %}
        <a href="{{ opportunity.episode.link }}">{{ opportunity.episode.name }}</a>
      </h2>
      {% if opportunity.description %}
      <p>{{ opportunity.description }}</p>
      {% endif %}

      <a href="{{ opportunity.episode.link }}" class="no-underline">
        <span class="underline">
          {%- if opportunity.type == "podcast" -%}
          Listen
          {%- elsif opportunity.type == "talk" -%}
          Watch
          {%- elsif opportunity.type == "presentation" -%}
          Read
          {%- elsif opportunity.type == "upcoming" -%}
          Tickets
          {%- endif -%}
        </span>
        &hellip;
      </a>
    </li>
  {% endfor %}
</ul>
