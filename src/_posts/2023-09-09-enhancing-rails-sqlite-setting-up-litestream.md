---
title: Enhancing your Rails app with SQLite
subtitle: Setting up Litestream
date: 2023-09-09
tags:
  - code
  - ruby
  - rails
  - sqlite
published: true
---

This is the next in a collection of posts where I want to highlight ways we can use [SQLite](https://www.sqlite.org/index.html) as the database engine for our [Rails](https://rubyonrails.org) applications without giving up key features or power. In this post, I want to discuss one of the most often discussed disadvantages of SQLite—disaster recovery—and how to address it.

<!--/summary-->

- - -

[Ben Johnson](https://twitter.com/benbjohnson?ref=fractaledmind.github.io) is one of my favorite people in the SQLite ecosystem, and he put the point well:

> So why is SQLite considered a “toy” database in the application development world and not a production database?
> The biggest problem with using SQLite in production is disaster recovery. If your server dies, so does your data. That’s… not good.

The fact that SQLite uses a file on the local filesystem is one of the great double-edged sword that makes it so divisive. On the one hand, having a local file completely remove network latency from queries, which is often the primary performance bottleneck for web applications. Additionally, having your database simply be a single file allows for unique possibilities when it comes to managing your application database, like using [branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %}). Plus, this makes the operational complexity of your web application noticably simpler, as you don't need to run a separate server for you database. In future posts in this series, I will get into other benefits that come from SQLite's simplicity as a normal file on the filesystem.

However, simply being a file on the filesystem is also SQLite's primary weakness. Persistent data storage needs to be persistent; otherwise, it isn't so useful. And I've personally experienced the danger here. I once, somewhat mindlessly while waiting for another application to deploy, renamed an application in a 3rd-party platform-as-a-service provider's dashboard, just to make the app names more consistent. I didn't know that this action in the web dashboard would lead to the <abbr title="platform as a service">PaaS</abbr> using `rm -rf` on the folder that contained my application on their servers to then redeploy under a new folder name. I am using SQLite as my production database for this app, and while I had the database stored in the `/storage` directory to keep it safe across deployments, that didn't help at all when the entire parent directory was wiped. That one mindless update in a web UI completely wiped away about 1 years worth of production data. I tried a number of recovery techniques, but nothing worked. The data was lost.

I tell this story because I don't want to gloss over this point—without a clear and strong disaster recovery plan, using SQLite as your production database is **_dangerous_** and probably foolish. There are many benefits to SQLite, and I still happily use SQLite as my production database for many applications, including the one above. I ensure, however, that I **always** have a disaster recovery setup.

In what follows, I want to lay out the backup and recovery setup that I use, and provide you the tools to set this up for yourself.

- - -

The quote from [Ben Johnson](https://twitter.com/benbjohnson?ref=fractaledmind.github.io) above comes from a [blog post](https://litestream.io/blog/why-i-built-litestream/) on why he created the [`Litestream`](https://litestream.io) tool. `Litestream` is an **_essential_** tool for someone interested in unlocking the power of SQLite for their web application to know and use. So, what is `Litestream`? In a single sentence,

> Litestream is a streaming replication tool for SQLite databases.

Let's dig into what that means more concretely. From Ben's introductory blog post, we get this fuller description:

> Litestream is a tool that runs in a separate process and continuously replicates a SQLite database to Amazon S3 [or another storage provider]. You can get up and running with a few lines of configuration. Then you can set-it-and-forget-it and get back to writing code.

Put simply, `Litestream` is your SQLite disaster recovery plan, and it is simple, robust, and resilient. For the miniscule cost of a cloud storage bucket, you can get effectively point-in-time backups of your SQLite database(s).[^1] And it is straight-forward to setup.

The [documentation](https://litestream.io/getting-started/) provides guides on installing `Litestream` on [macOS](https://litestream.io/install/mac/), [Linux (Debian)](https://litestream.io/install/debian/), or [building from source](https://litestream.io/install/source/). Personally, I deploy to a Linux (Debian) server, so I will be sharing that approach.

With the package installed on your production server, you then need to get it running. Again, you have multiple options, each laid out well in the documentation. You can either run the process [in a Docker container](https://litestream.io/guides/docker/), [in a Kubernetes cluster](https://litestream.io/guides/kubernetes/), [as a Systemd service](https://litestream.io/guides/systemd/), or [as a Windows service](https://litestream.io/guides/windows/). In my case, I run `Litestream` as a Systemd service, so we will follow that path.

Finally, with the package installed and running, you need to configure it to talk to your storage provider. `Litestream` supports a wide array of providers—[Amazon S3](https://litestream.io/guides/s3/), [Azure Blob Storage](https://litestream.io/guides/azure/), [Backblaze B2](https://litestream.io/guides/backblaze/), [DigitalOcean Spaces](https://litestream.io/guides/digitalocean/), [Scaleway Object Storage](https://litestream.io/guides/scaleway/), [Google Cloud Storage](https://litestream.io/guides/gcs/), [Linode Object Storage](https://litestream.io/guides/linode/), and [an SFTP Server](https://litestream.io/guides/sftp/). In my case, I use DigitalOcean Spaces.

Hopefully, you can see that `Litestream` is quite flexible and can be used across a multitude of different deployment situations and storage providers. I, however, only have experience with my setup. So, I will share that, with as much detail as possible, to help you hopefully get everything setup yourself.

- - -

I use [Hatchbox.io](https://hatchbox.io) to host my Rails applications. When using SQLite as your production database, you simply [can't use Heroku](https://devcenter.heroku.com/articles/sqlite3). But, I have fallen out of love with Heroku generally, after a decade under Salesforce's stewardship. I love Hatchbox because it allows me to "deploy to servers that I own", which mitigates the cost overhead that many <abbr title="platform as a service">PaaS</abbr> providers entails, plus it tailor-made for Rails applications. It is run by [Chris Oliver](https://twitter.com/excid3?ref=fractaledmind.github.io) from [GoRails](https://gorails.com/) and [Bilal Budhani](https://twitter.com/BilalBudhani?ref=fractaledmind.github.io), and they offer quick and useful customer support. Salespitch aside (just a joke, I have no affiliate relationship with Hatchbox), Hatchbox is a great service, but since it mostly sits on top of servers you bring it, there is nothing in the setup of `Litestream` that is Hatchbox-specific.

In my case, I have used both DigitalOcean droplets as well as Hetzner servers through Hatchbox. In either case, I am bringing Linux machines that run Ubuntu—a Debian-based <abbr title="operating system">OS</abbr>. Since `Litestream` provides Debian package files, it is straight-forward to install `Litestream` using the `dpkg` utility.[^2] Moreover, using a Debian-based <abbr title="operating system">OS</abbr> allows us to use `systemd` to run the `Litestream` process on our behalf.

Here is the Bash script I use to install and run `Litestream` on all of my servers:[^3]

```shell
#!/usr/bin/env bash
set -e

# Load environment
source /home/deploy/.bashrc

# Determine architecture of current env
arch=$(dpkg --print-architecture)
# Manually set the Litestream version number we are using
version="v0.3.11"

# Download the latest .deb file
wget "https://github.com/benbjohnson/litestream/releases/download/$version/litestream-$version-linux-$arch.deb"

# Install that .deb file using dpkg
sudo dpkg -i "litestream-$version-linux-$arch.deb"

# Verify it is installed
echo "Litestream version:"
litestream version

# Enable Litestream to run continuously as a background service
sudo systemctl enable litestream

# Start Litestream running continuously as a background service
sudo systemctl start litestream

# Verify the service is running
echo "Litestream service logs:"
sudo journalctl -u litestream
```

As you can see, the setup is straight-forward. I have run this script on both DigitalOcean and Hetzner servers with no problems. It relies on pre-installed system utilities like `dpkg`, `wget`, and `systemd` so no additional setup is required. Plus, it is a small script, so it is easy to share and use and understand.

If you aren't using a Debian-based <abbr title="operating system">OS</abbr>, you will need a different setup script, but Linux and Ubuntu are quite popular, so odds are this script can be useful for you.

Once you have `Litestream` installed and running, the only thing left is to configure it to start replicating your database(s). Once again, the docs have [a page](https://litestream.io/reference/config/) dedicated to configuring `Litestream`. The summary, though, is that you will need to create an `/etc/litestream.yml` file and then enter your YAML configuration. The basic structure of the configuration is straight-forward (you may be sensing a trend here, and this is another wonderful thing about `Litestream`—it does straight-forward things straight-forwardly). You provide an array of `dbs`, each with an array of `replicas`. So, you can have your server's `Litestream` process backing up multiple SQLite database files, plus each database file can be streamed to multiple storage providers.

In my case, I use a single server for a single app, which I backup to a single storage provider. In the simplest case, I use a single SQLite file for the storage backend of my Rails app's `ActiveRecord` models. Thus, I only have the one database. In more interesting cases (which I will be writing more about in the future), I use [Litestack](https://github.com/oldmoe/litestack) to actually have SQLite back `ActionCable`, `ActiveSupport::Cache`, and `ActiveJob`, such that I have four or more SQLite database files per app to backup.

I won't cover how to create a cloud storage bucket. The `Litestream` docs do a good job of that on their own. Instead, let's focus on the configuration you would have on your server. Since I am using DigitalOcean Spaces as my storage provider, I followed [the instructions](https://litestream.io/guides/digitalocean/) from the `Litestream` docs. You will need an `access-key-id` and a `secret-access-key` to allow `Litestream` to connect to your storage provider. The configuration file supports setting those values globally as well as on a per-replica basis. To make adding replicas easier in the future, I default to setting them on a per-replica basis. Thus, my configuration file looks like this:

```yaml
# /etc/litestream.yml
dbs:
  - path: /home/deploy/application-name/current/storage/production.sqlite3
    replicas:
      - url: s3://bucket-name.litestream.region.digitaloceanspaces.com/production
        access-key-id: xxxxxxxxxxxxxxxxxxxx
        secret-access-key: xxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Again, straight-forward. All you need to do is point `Litestream` at your database file, then point it at your storage bucket (with access credentials). It handles everything else.

Since our installation script starts the `Litestream` process immediately after installation, we will likely be creating the configuration file next. Once you have gotten your configuration file setup properly, you will need to restart the `Litestream` process to pick up your new config file. As we are using `systemd`, this is as simple as:

```shell
sudo systemctl restart litestream
```

With `Litestream` installed, configured, and running, you are ready to go. If you write to your database and then visit your storage bucket, you will see that `Litestream` has already written data there. And since no backup is viable until we have verified that we can recover with it, let us simulate a disaster and run through the recovery steps.

I like to simply rename my database file to mimic a deletion. If we imagine that we moved our `/home/deploy/application-name/current/storage/production.sqlite3` database file to `/home/deploy/application-name/current/storage/-deleted.sqlite3`, how can we recover our `production.sqlite3` file with `Litestream`? From our server's command line, we need to run

```shell
litestream restore production.sqlite3
```

That's it. We don't have the provide the entire file path, we don't need any esoteric command line arguments, just `litestream restore`. This command will find the database in the configuration file and restore the most recent copy it has from its storage replica. Confirm that the file is present then run

```shell
sqlite3 production.sqlite3
```

to inspect the contents of the database and check that the most recent data from before the "deletion" is present.

Once you have confirmed that your recovery process is up and running, you are good to go. Using `Litestream` we have now mitigated the primary weakness with using SQLite in production for our web application persistence layer. We can now enjoy the <abbr title="developer experience">DX</abbr> benefits that come with using SQLite without the constant worry about disaster recovery.[^4]

- - -

## All posts in this series

* [Part 1 — branch-specific databases]({% link _posts/2023-09-06-enhancing-rails-sqlite-branch-databases.md %})
* [Part 2 — fine-tuning SQLite configuration]({% link _posts/2023-09-07-enhancing-rails-sqlite-fine-tuning.md %})
* [Part 3 — loading extensions]({% link _posts/2023-09-08-enhancing-rails-sqlite-loading-extensions.md %})
* {:.bg-[var(--tw-prose-bullets)]}[Part 4 — setting up `Litestream`]({% link _posts/2023-09-09-enhancing-rails-sqlite-setting-up-litestream.md %})
* [Part 5 — optimizing compilation]({% link _posts/2023-09-10-enhancing-rails-sqlite-optimizing-compilation.md %})
* [Part 6 — array columns]({% link _posts/2023-09-12-enhancing-rails-sqlite-array-columns.md %})
* [Part 7 — local snapshots]({% link _posts/2023-09-14-enhancing-rails-sqlite-local-snapshots.md %})

- - -

[^1]: For those of you interested in _how_ `Litestream` works, the documentation has a very [understandable page](https://litestream.io/how-it-works/). I would heartily recommend just reading that in its entirety.
[^2]: For an introduction to `dpkg`, I would recommend [this article](https://www.digitalocean.com/community/tutorials/dpkg-command-in-linux). Otherwise, the short description from the `man` page hopefully provides enough of a sense: "dpkg is a tool to install, build, remove and manage Debian packages."
[^3]: As of the time of this post (September 9<sup>th</sup>, 2023), the latest release of `Litestream` is version 0.3.11. If you run this script at some point in the future and there is a newer release, replace the `version` variable with that version number. You can always find the most recent release on the project's [GitHub Releases page](https://github.com/benbjohnson/litestream/releases).
[^4]: One alternative for a disaster recovery plan is to use remote attached storage, like AWS EBS or similar. From your application's point of view, this is still a local filesystem, but if your server dies, the data doesn't. You can then "recover" the data by simply reattaching the storage to another server. The key details with this solution is to ensure that your memory-map is large enough to ensure that reads are basically as fast as with true local storage, plus make sure that you set the `synchronous` pragma to `NORMAL` to minimize `fsync` calls on writes, as these will be much slower with the attached storage. Perhaps most importantly, though, don't even get tempted by the idea of using a remote filesystem like NFS. But, as one of my [SQLite guru's](https://twitter.com/oldmoe?ref=fractaledmind.github.io) has [said](https://twitter.com/oldmoe/status/1699870046871343516): "<em style="color: var(--tw-prose-quotes); font-weight: 500;">[W]ith attached storage you get durability and availability, and SQLite can be tuned so it gets very close to local storage performance wise. [Plus,] Google & AWS offer auto instance recovery, so if your instance goes down another one is spawned and the storage is reattached, this happens in seconds and delivers a pretty high level of availability for your SQLite powered apps.</em>"
