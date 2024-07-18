---
title: How to deploy a Hatchbox app
date: 2023-12-28
tags:
  - code
  - rails
  - hatchbox
---

I personally have used (and loved) [Hatchbox](https://hatchbox.io) for years. Hatchbox is essentially an “Ops-as-a-Service”. You bring your own server, whether a DigitalOcean droplet or a Hetzner VPS or something else, and their platform will configure the server, deploy the repo, and generally take care of going from “I don’t have an app on the internet” to “I do have an app on the internet”. Let's walk through, step by step, how to deploy a Rails app to production with Hatchbox.

<!--/summary-->

- - -

<img src="{{ '/images/rubyconftw/018.jpg' | relative_url }}" alt="" style="width: 100%" />

When you begin, you need to create what Hatchbox calls a “cluster”. They need to support applications that have maybe 3 servers running instances of the web app, two different servers running two different instances of Redis, each with different eviction policies, and one primary database server alongside one replica database server. Thus, they have clusters. One of my favorite aspects of a SQLite on Rails application is that we don’t need a complex network of interconnected servers to run our application. And especially at the beginning, when just trying to create something from nothing, being able to get a fully-functioning application without having to figure out all of these operational details can be the difference between shipping in days vs shipping in months.

Anyway, we will create our cluster, and use DigitalOcean as our hosting provider. In the end, our cluster will only have one server, but we need to conform to Hatchbox’s view of the world nonetheless.

<img loading="lazy" src="{{ '/images/rubyconftw/019.jpg' | relative_url }}" alt="" style="width: 100%" />

We then need to connect our DigitalOcean account, to grant Hatchbox the ability to manage our DigitalOcean droplets on our behalf.

<img loading="lazy" src="{{ '/images/rubyconftw/020.jpg' | relative_url }}" alt="" style="width: 100%" />

This will take us to a DigitalOcean OAuth page where we authorize Hatchbox for whichever DigitalOcean team account we want.

<img loading="lazy" src="{{ '/images/rubyconftw/021.jpg' | relative_url }}" alt="" style="width: 100%" />

Once we have authorized Hatchbox,

<img loading="lazy" src="{{ '/images/rubyconftw/022.jpg' | relative_url }}" alt="" style="width: 100%" />

We can start configuring our cluster. We first need to choose the region that our cluster will be hosted in.

<img loading="lazy" src="{{ '/images/rubyconftw/023.jpg' | relative_url }}" alt="" style="width: 100%" />

DigitalOcean offers a number of different region options.

<img loading="lazy" src="{{ '/images/rubyconftw/024.jpg' | relative_url }}" alt="" style="width: 100%" />

Let’s choose Frankfurt for now. Pretty nicely centrally located.

<img loading="lazy" src="{{ '/images/rubyconftw/025.jpg' | relative_url }}" alt="" style="width: 100%" />

With that, our cluster is created, and so we need to add a server to our cluster next.

<img loading="lazy" src="{{ '/images/rubyconftw/026.jpg' | relative_url }}" alt="" style="width: 100%" />

As Hatchbox will remind us, we minimally need a server with two core responsibilities—run our web app and run cron.

<img loading="lazy" src="{{ '/images/rubyconftw/027.jpg' | relative_url }}" alt="" style="width: 100%" />

Let’s create a single server with both responsibilities.

<img loading="lazy" src="{{ '/images/rubyconftw/028.jpg' | relative_url }}" alt="" style="width: 100%" />

With that done, we can consider what size of server we want.

<img loading="lazy" src="{{ '/images/rubyconftw/029.jpg' | relative_url }}" alt="" style="width: 100%" />

DigitalOcean’s Frankfurt region has a number of different server size options.

<img loading="lazy" src="{{ '/images/rubyconftw/030.jpg' | relative_url }}" alt="" style="width: 100%" />

The largest option in this region goes up to 32GB of RAM, 8 CPUs, and is $192 a month. For our MVP though, let’s start with the smallest, simplest, cheapest option.

<img loading="lazy" src="{{ '/images/rubyconftw/031.jpg' | relative_url }}" alt="" style="width: 100%" />

Now, Hatchbox will begin creating and provisioning our server.

<img loading="lazy" src="{{ '/images/rubyconftw/032.jpg' | relative_url }}" alt="" style="width: 100%" />

You can tail the logs of what precisely Hatchbox is doing if you’d like.

<img loading="lazy" src="{{ '/images/rubyconftw/033.jpg' | relative_url }}" alt="" style="width: 100%" />

But once it has created the server on Digital Ocean, it will begin provisioning it.

<img loading="lazy" src="{{ '/images/rubyconftw/034.jpg' | relative_url }}" alt="" style="width: 100%" />

That can take some time—in this case around 10 minutes, but once it is done, we can begin creating our App to deploy to this server on this cluster.

<img loading="lazy" src="{{ '/images/rubyconftw/035.jpg' | relative_url }}" alt="" style="width: 100%" />

When we navigate to the “Apps” tab, we can create a new app.

<img loading="lazy" src="{{ '/images/rubyconftw/036.jpg' | relative_url }}" alt="" style="width: 100%" />

You give the app a name and choose which cluster it should be deployed to.

<img loading="lazy" src="{{ '/images/rubyconftw/037.jpg' | relative_url }}" alt="" style="width: 100%" />

We want our new app to deploy to our new cluster.

<img loading="lazy" src="{{ '/images/rubyconftw/038.jpg' | relative_url }}" alt="" style="width: 100%" />

When we tell Hatchbox to create this app,

<img loading="lazy" src="{{ '/images/rubyconftw/039.jpg' | relative_url }}" alt="" style="width: 100%" />

it will ask us for the repository information. If you are just starting, you can connect their GitHub app to your GitHub account.

<img loading="lazy" src="{{ '/images/rubyconftw/040.jpg' | relative_url }}" alt="" style="width: 100%" />

Or, if you are using some other git host, or you have already installed their GitHub app

<img loading="lazy" src="{{ '/images/rubyconftw/041.jpg' | relative_url }}" alt="" style="width: 100%" />

You can just choose that.

<img loading="lazy" src="{{ '/images/rubyconftw/042.jpg' | relative_url }}" alt="" style="width: 100%" />

Provide the repo name and branch name, and that’s it.

<img loading="lazy" src="{{ '/images/rubyconftw/043.jpg' | relative_url }}" alt="" style="width: 100%" />

Now, we just need to deploy our new app to our new server.

<img loading="lazy" src="{{ '/images/rubyconftw/044.jpg' | relative_url }}" alt="" style="width: 100%" />

Again, Hatchbox handles the details here. And, again, you can tail the logs to see precisely what it is doing if you’d like.

<img loading="lazy" src="{{ '/images/rubyconftw/045.jpg' | relative_url }}" alt="" style="width: 100%" />

After a few minutes, your app will be deployed. You can now view that app running on a Hatchbox subdomain.

Congrats! As quickly and easily as that, you have a production Rails application running. And I really want to emphasize just how quick and easy that was. In this demo, I am deploying a Rails application that uses SQLite as its database engine, so I am not using Hatchbox's database management features. But if you are using PostgreSQL, MySQL, or Redis, Hatchbox will automatically provision and manage those for you. And if you are using a different database engine, you can still use Hatchbox, but you will need to manage that database yourself.

- - -

This doesn't cover all of Hatchbox's features, but it does cover every single screen used when deploying an application. I hope you found this useful. As always, if you have any questions or comments, just hit me up on Twitter [@fractaledmind](http://twitter.com/fractaledmind?ref=fractaledmind.github.io).
