---
title: "Code Is Cheap Now. That's Why It Matters."
date: 2026-10-04
tags:
  - code
  - ai
---

If you write software for a living, you've probably been told some version of this lately: the code doesn't matter anymore. The AI writes it now. Your job is to think like a product manager, or a QA engineer, or a "maker" who describes what they want and lets the machine figure out the rest.

I don't buy it. You're a programmer, and that's a great thing to be.

<!--/summary-->

- - -

Things are changing radically and rapidly, but the essence of programming remains. There is still such a thing as a better architecture, a solution that better fits the problem. There is still such a thing as well-modeled and well-factored code. There is still such a thing as a great abstraction, one that gives you leverage and doesn't leak.

What has changed is that code is now fungible. And that is why it matters more than ever.

## Code is fungible

For most of my career, code was expensive. Writing it took time, and rewriting it took even more time. So the first version that worked became the version we kept. We kept our early decisions long after we knew they were wrong, because changing them cost more than living with them. The code we already had was a weight we carried.

That weight is mostly gone. I can describe a change to a coding agent and watch it land across a codebase in the time it used to take me to plan it. I'm no longer burdened by the weight of what already exists, or limited by the pace of my own fingers.

That doesn't necessarily mean we want to make a habit of throwing code away and regenerating it from scratch. Some people argue for exactly that: treat a written spec as the real asset, and regenerate the code from it whenever you like. I think that's usually unwise. A working codebase holds countless decisions and fixes that no spec captures, and, as you'll see below, it's also what every AI session learns from. What becomes common instead is this: when I learn a better way to do something, I can make it true everywhere, right away.

Running Prettier over a codebase is the baby step of working this way. Change one line of config and every file in the codebase reformats in a single commit. AI lets us do the same with implementation: with interfaces and abstractions. When I decided that every external API we use should have a thin client that mirrors the API, with an SDK on top that speaks our domain, I didn't apply it only to new code. I applied it to every API integration we use, across the entire codebase.

## More important than ever

This is what the "code doesn't matter" argument misses. A coding agent session never begins work "from scratch." It reads the existing code and follows its conventions. The codebase weighs more heavily on the agent's decisions than your prompt does. As far as the agent is concerned, the code is the truth.

When the codebase is well-modeled and consistent, the AI pattern-matches its way to more good code with little hand-holding. When it's sloppy, you have to be on top of every step, and every flaw that you miss has a good chance of being copied mindlessly by the next coding agents that come across it.

So the quality of the code now compounds in a way it never did before. A great abstraction used to save time for the people who knew about it. Now it shapes every line a coding agent writes. At ZAR, our product access system gives us one way to define who can use what, and what they have to do first. Because it exists, nobody, human or AI, has to design authorization for a new product. That decision was made once, and every coding agent that finds it follows it.

The reverse compounds too. Unneeded complexity is worse than worthless. The nil check on a value that can't be nil, the fallback for a state that never happens: each one tells the next coding agent that the impossible is possible.

## The craft is finding the better abstraction

None of this means the AI knows what the better abstraction is. Finding it is still the programmer's job, and it's still hard, valuable work.

We never know what the right design looks like at the start. There are too many unknowns, and we have to build in order to find out what ought to be built. So I work in two phases. First I expand: I let the AI run, and we explore the problem space by actually building candidate solutions. Then I contract: I take what we learned and fold it back into the system. I reuse an existing primitive instead of adding a new one, promote a one-off into something the next feature can use, and delete unneeded new state and conditionals.

The second phase is entirely novel in the age of AI coding agents and unlimited intelligence on tap. In the old world we usually shipped the first solution we devised and lived with it, because further exploration cost too much time. Now there's no excuse. You explore until you find the *ideal* design, because implementing it is so fast.

## The best idea can win

Put those together and you get something programmers have always wanted. The best idea can win, and be put in place immediately and universally. Not after a quarter of migration planning, and not only in new code. Everywhere, now.

That makes the essence of programming more valuable. Knowing what a better architecture looks like, spotting a leaky abstraction, seeing the model hiding inside a messy feature: that is the scarce skill, and it has more leverage now than it has ever had.

The teams that do this best, and do it consistently, will win. They always have.
