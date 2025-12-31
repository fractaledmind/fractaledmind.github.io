---
title: "2025 in review"
date: 2025-12-31
tags:
  - life
---

On September 23rd, 2025, in a Berlin hospital room, I became a dad. Emma Elanor Margheim entered the world and promptly rearranged every priority I thought I had.

She's currently asleep, so let me tell you about the rest of the year.

<!--/summary-->

- - -

## Becoming a Family

The year began with a milestone: on January 13th, Geniya became a German citizen. After oodles of paperwork and appointments and waiting, she walked out of the Ausländerbehörde as a dual citizen. We celebrated with sushi.

<button type="button" class="thumbnail" popovertarget="geniya-citizenship-jpeg" aria-label="">
  <img src="{{ '/images/geniya-citizenship.jpeg' | relative_url }}" alt="Young woman standing between European Union, German, and Berlin flags holding a Berlin certificate, smiling in an official setting." style="width: 33%; margin-inline: auto;" />
</button>
<dialog class="lightbox" id="geniya-citizenship-jpeg" popover>
  <img src="{{ '/images/geniya-citizenship.jpeg' | relative_url }}" alt="" />
</dialog>

By spring, we knew Emma was on the way. In June, we escaped to Südtirol for a babymoon—a last hurrah of lazy mornings and mountain views before our family of 2 become a family of 3. We hiked (more like walking, but in nature), ate too much, and tried to imagine what life would look like in a few months.

<button type="button" class="thumbnail" popovertarget="babymoon-jpeg" aria-label="">
  <img src="{{ '/images/babymoon.jpeg' | relative_url }}" alt="Two people resting on a lakeside bench, sneakers facing turquoise water, forested mountains and blue sky with a few clouds in the background." style="width: 33%; margin-inline: auto;" />
</button>
<dialog class="lightbox" id="babymoon-jpeg" popover>
  <img src="{{ '/images/babymoon.jpeg' | relative_url }}" alt="" />
</dialog>

Then September 23rd arrived, and we began to find out.

<button type="button" class="thumbnail" popovertarget="emma-elanor-jpeg" aria-label="">
  <img src="{{ '/images/emma-elanor.jpeg' | relative_url }}" alt="Adult hands cradling a newborn foot with hospital ID band; baby's heel has hospital tag with her name and date of birth." style="width: 33%; margin-inline: auto;" />
</button>
<dialog class="lightbox" id="emma-elanor-jpeg" popover>
  <img src="{{ '/images/emma-elanor.jpeg' | relative_url }}" alt="" />
</dialog>

What I didn't fully appreciate until living it: Germany's support system for new parents is remarkable, coming from someone raised in the States and just simply unaware of what the whole process could look like. A midwife—a Hebamme as they are called here—visited our apartment every single day for the first week after Emma was born. Then weekly for the next two months. She checked on Emma, checked on Geniya, answered our endless questions, and made those early weeks survivable. No bills. No insurance negotiations. Just care.

Looking ahead, knowing that universal childcare exists here—that Emma will have a spot in a Kita—takes an enormous weight off our planning. Starting a family in Germany has meant never once worrying about medical debt. That peace of mind is hard to overstate.

In November, my parents flew over from the States to meet their grand-daughter. A week of them holding Emma, of showing them our Berlin neighborhood, of watching my dad figure out the U-Bahn. It was the first time they'd seen our new life here up close; it was cozy and fun.

- - -

## The Career Arc

2025 marked my second job change in just over two years. I'd joined [Test IO](https://test.io) when I moved to Berlin in 2019 and spent five years there—as a senior engineer, then team lead, then engineering manager, and eventually director leading 40+ engineers across five teams. Near the end of 2024, I moved to [Prevail.ai](https://prevail.ai) as a Senior Engineer; I wanted to get back into writing code daily. Smaller team, different challenges, back to building.

Then in November this year, another shift: Principal Engineer at [Impruvon Health](https://impruvon.com). Healthcare tech, Ruby and Rails on the backend, real problems affecting real patients. The onboarding was dense—calls about integrations, architecture discussions, first tasks shipping within weeks. I'm still ramping up, but I'm contributing. Feels good.

The through-line across all of it: I keep finding my way back to Rails, to Ruby, to teams trying to build something that matters.

- - -

## High Leverage Rails

The biggest project I shipped this year wasn't code—it was a course.

In February, I launched [High Leverage Rails](https://highleverage.dev) with [Aaron Francis](https://aaronfrancis.com) and [Try Hard Studios](https://tryhardstudios.com). It's a comprehensive course on building production-ready Rails applications with SQLite—the database I've been advocating for years.

The thesis: learn the fundamentals deeply, and you can build anything quickly. The age of the starter kit is ending. Responsibility requires understanding.

Working with Aaron was a highlight. He's built an incredible media operation, and collaborating on something at that scale pushed me in new directions. [Hatchbox](https://hatchbox.io) and [Honeybadger](https://honeybadger.io) came on as sponsors. The launch went well. And now there are developers out there building real applications with Rails and SQLite because of something I made. Wild.

- - -

## Open Source

My open source work this year centered on a few key projects:

[**Acidic Job**](https://github.com/fractaledmind/acidic_job) continued to evolve—durable execution workflows for Active Job. The idea is simple: background jobs should be resilient to failures, restarts, and chaos. The implementation is... less simple. But it's getting there, with RC releases throughout the year.

[**Chaotic Job**](https://github.com/fractaledmind/chaotic_job) emerged as a companion gem for testing job resilience. It lets you simulate failures, timeouts, and all the ways jobs can go wrong—so you can prove your workflows handle them correctly. I talked about it at Tropical on Rails and ChicagoRuby.

[**Solid Errors**](https://github.com/fractaledmind/solid_errors) hit v0.7.0 in June—a database-backed exception tracker for Rails. This release was special because it was almost entirely community-driven. PRs from contributors, issues identified by users, a release that felt collaborative.

[**Litestream Ruby**](https://github.com/fractaledmind/litestream-ruby) got similar treatment—v0.13.0 shipped with all community contributions. The SQLite ecosystem keeps growing.

And then there's [**Plume**](https://github.com/yippee-fun/plume), my SQL parser for SQLite's dialect. I spent months on this—learning parser patterns, hitting 37,000+ passing tests, creating syntax diagrams. It became my RubyKaigi talk and remains one of the most technically challenging things I've built.

- - -

## My Ruby Triathlon

In April, I gave three talks on three continents in three consecutive weeks:

1. [**Tropical on Rails**](https://www.tropicalonrails.com) in São Paulo — ["Resilient Jobs and Chaotic Tests"](https://www.youtube.com/watch?v=NGeyotdnJS4)
2. [**wroclove.rb**](https://wrocloverb.com) in Wrocław — ["On the tasteful journey to Yippee"](https://www.youtube.com/watch?v=VWDfeMHBaH0) (a project [Joel Drapper](https://joel.drapper.me) and I are slowly working on)
3. [**RubyKaigi**](https://rubykaigi.org/2025/) in Matsuyama — ["Parsing and generating SQLite's SQL dialect with Ruby"](https://www.youtube.com/watch?v=VaSpF9JmbZo)

I called it my #RubyTriathlon. Geniya called it "that thing where you're gone for most of April."

The highlight was RubyKaigi and getting to hang out with the Ruby community in Japan, watching Matz talk about the future of Ruby, eating incredible food, and wandering Matsuyama. The lowlight was the 12-hour-33-minute flight from Warsaw to Tokyo, my longest ever.

<button type="button" class="thumbnail" popovertarget="japan-jpeg" aria-label="">
  <img src="{{ '/images/japan.jpeg' | relative_url }}" alt="Narrow, dimly lit Japanese alley at night lined with small bars and shops, neon signs and lanterns, cluttered pipes and signage leading into distance" style="width: 33%; margin-inline: auto;" />
</button>
<dialog class="lightbox" id="japan-jpeg" popover>
  <img src="{{ '/images/japan.jpeg' | relative_url }}" alt="" />
</dialog>

Later: SQLite Office Hours at [RailsConf](https://railsconf.org) with [Mike Dalessio](https://mike.daless.io), a talk at [ChicagoRuby](https://chicagoruby.org). Five speaking engagements. Four continents. One very tired me.

- - -

## Staying Connected

Beyond conferences, the Ruby community showed up in smaller ways all year.

In January and February alone, I had 19+ "Chat with Stephen" calls—video chats with developers from around the world. Some wanted to talk SQLite. Some wanted career advice. Some just wanted to connect. One of those calls was with [Taylor Otwell](https://twitter.com/taylorotwell), creator of [Laravel](https://laravel.com). I basically begged him to consider expanding the Laravel services to the Rails ecosystem. Maybe one day; a man can dream.

I appeared on podcasts: [Remote Ruby](https://remoteruby.com), a few episodes of In Dialog, others I'm probably forgetting. I gave a virtual talk to [Ruby Turkey](https://rubyturkiye.org). I kept the [**Naming Things Discord**](https://discord.gg/zVKz9vrn) running—it's invite-only, but it remains one of my favorite corners of the internet. Like a virtual hallway track at a Ruby conference.

In December, after years of meaning to, I finally launched a [**newsletter**](https://join.fractaledmind.com/). Added a signup form to the blog, sent my first issue. It felt like a missing piece clicking into place.

- - -

## Writing

I published 6 blog posts this year, but the bigger development was launching a [**Tips section**](/tips/) in December. Short, focused techniques—one concept per post.

The theme across all my writing: **platform-native web development**. Every month, browsers ship features that used to require JavaScript. I became obsessed with documenting what's possible. Turns out: a lot.

I will be doing a lot more in this space in 2026 for sure.

- - -

## Life in Berlin

Some snapshots from the year:

**The movie pass.** Early in the year, we got a [UCI Luxe](https://www.uci-kinowelt.de) subscription—unlimited movies for a flat monthly fee. We saw everything: Nosferatu, Anora, A Real Pain, Emilia Perez, Mickey 17, Sinners, Final Destination 6, Ballerina. That last one, Demon Slayer, Geniya let me watch on my own while she was 37 weeks pregnant; she's a champion. Once Emma arrived, the movie pass got canceled. Priorities shift. 🤷🏻

**The studio.** In July, I decided I needed a proper space for recording and calls. So I built one. Framed up a corner of our apartment, wired fans, hung insulation and acoustic panels. By August it was done—not perfect, but mine. As Aaron Francis says, you can just build things.

<div style="display: grid; grid-template-columns: repeat(5, 1fr); grid-gap: 10px;">
  <button type="button" class="thumbnail" popovertarget="studio-build-0-jpeg" aria-label="">
    <img src="{{ '/images/studio-build-0.jpeg' | relative_url }}" alt="Empty corner of a room with gray walls, light wood floor, white baseboard, electrical outlets, and a gray curtain at left; painter's tape marks on floor." />
  </button>
  <button type="button" class="thumbnail" popovertarget="studio-build-1-jpeg" aria-label="">
    <img src="{{ '/images/studio-build-1.jpeg' | relative_url }}" alt="Wooden stud wall framing installed on hardwood floor inside a modern apartment, with lighting fixtures, tools, and stacked panels nearby." />
  </button>
  <button type="button" class="thumbnail" popovertarget="studio-build-2-jpeg" aria-label="">
    <img src="{{ '/images/studio-build-2.jpeg' | relative_url }}" alt="Interior room with new wooden stud framing for a partition wall, exposed wiring, a cordless drill on the floor, ladder and modern ring lights above." />
  </button>
  <button type="button" class="thumbnail" popovertarget="studio-build-3-jpeg" aria-label="">
    <img src="{{ '/images/studio-build-3.jpeg' | relative_url }}" alt="Partially built interior partition framed with insulation batts, a glass door, small window opening and ventilation fan next to hardwood flooring." />
  </button>
  <button type="button" class="thumbnail" popovertarget="studio-build-4-jpeg" aria-label="">
    <img src="{{ '/images/studio-build-4.jpeg' | relative_url }}" alt="Modern room with a vertical slat wooden partition enclosing a glass-door nook, circular pendant lights overhead and hardwood floors with trim pieces on the floor." />
  </button>
</div>

<dialog class="lightbox" id="studio-build-0-jpeg" popover>
  <img src="{{ '/images/studio-build-0.jpeg' | relative_url }}" alt="" />
</dialog>
<dialog class="lightbox" id="studio-build-1-jpeg" popover>
  <img src="{{ '/images/studio-build-1.jpeg' | relative_url }}" alt="" />
</dialog>
<dialog class="lightbox" id="studio-build-2-jpeg" popover>
  <img src="{{ '/images/studio-build-2.jpeg' | relative_url }}" alt="" />
</dialog>
<dialog class="lightbox" id="studio-build-3-jpeg" popover>
  <img src="{{ '/images/studio-build-3.jpeg' | relative_url }}" alt="" />
</dialog>
<dialog class="lightbox" id="studio-build-4-jpeg" popover>
  <img src="{{ '/images/studio-build-4.jpeg' | relative_url }}" alt="" />
</dialog>

**The opera.** Swan Lake at [Deutsche Oper Berlin](https://deutscheoperberlin.de) in March. Ein Sommernachtstraum earlier that month. A Sicilian cooking class in January. Ballet. These felt like the "before times" in retrospect—the last stretch of being able to do things spontaneously.

**The license.** After years in Germany, I finally got my driver's license in July. Test drove a BYD. Still thinking about it.

**Sports.** The Eagles won the Super Bowl in February (Fly Eagles Fly). LSU won the College World Series in June (Geaux Tigers). I watched both from Berlin, at inconvenient hours, and regret nothing.

- - -

## By the Numbers

### Travel

|--------|-------|
| **Flights** | 21 |
| **Miles** | 43,142 |
| **Time in the air** | 98 hours |
| **Countries visited** | 9 |

I flew 1.7x around the Earth. Berlin appeared in 10 of my 21 flights. I never flew on a Friday—not once, for reasons I can't explain.

### Writing

- 6 blog posts
- 14 tips
- 1 newsletter launched

### Speaking

- 5 events
- 4 continents
- 3 conference talks, 1 workshop, 1 meetup

### Open Source

- 15+ active repositories
- Major releases: Acidic Job, Chaotic Job, Solid Errors, Litestream Ruby, Plume

- - -

## What I Learned

A few things became clear:

**You can just build things.** Studios. Parsers. Courses. The barrier is usually deciding to start.

**The platform is getting really good.** We need less than we think we do to build excellent web apps in 2026.

**Community matters more than content.** The best moments weren't the talks. They were the conversations with old and new friends.

**Support systems matter.** Having a midwife visit daily, never worrying about medical bills, knowing childcare exists—these aren't luxuries. They're what let you focus on what matters.

- - -

## Looking Ahead

As I write this, Emma is just over three months old. She's has been smiling on purpose for a month or so now. She likes being held upright so she can look around. 

For 2026, I'm keeping it simple:

- **Keep writing.** The Tips format works.
- **Keep speaking.** I'm already scheduled to speak at [RubyConf Thailand](https://rubyconfth.com), and I'm on the program committee for [RubyConf Austria](https://www.rubyconf.at).
- **Keep shipping open source.** I have some awesome stuff brewing that I can't wait to share.
- **Be present.** Emma's first year only happens once.

To everyone who read a post, attended a talk, joined a call, or sent a kind message this year: thank you. The Ruby community remains one of the best places on the internet.

Here's to 2026. May it be slightly less chaotic and equally wonderful.

— Stephen
