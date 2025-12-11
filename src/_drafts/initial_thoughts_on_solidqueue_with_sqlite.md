---
series: SQLite on Rails
title: Initial thoughts on <code>SolidQueue</code> with SQLite
date: 2023-12-30
tags:
  - code
  - ruby
  - rails
  - sqlite
---

I personally have used (and loved) [Hatchbox](https://hatchbox.io) for years. Hatchbox is essentially an “Ops-as-a-Service”. You bring your own server, whether a DigitalOcean droplet or a Hetzner VPS or something else, and their platform will configure the server, deploy the repo, and generally take care of going from “I don’t have an app on the internet” to “I do have an app on the internet”. Let's walk through, step by step, how to deploy a Rails app to production with Hatchbox.

<!--/summary-->

- - -
