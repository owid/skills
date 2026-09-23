# FAQ

Questions about using the skill. If you want to change the skill itself, see
[AGENTS.md](AGENTS.md).

## If you use the Claude or ChatGPT app

### My agent isn't using the skill at all

Check these three first.

1. **Is the plugin switched on?** A plugin somebody shared with you arrives
   switched off, and one you installed yourself may too. Find it in your plugins
   list; if it has a switch, make sure it is on.
2. **Did you start a new chat?** It only applies to conversations you begin after
   switching it on.
3. **Is the question specific enough?** Assistants skip skills for work they can
   do unaided. "Find the OWID chart on child mortality and pull the data" will use
   it; "what's OWID" may not. That is by design.

If it still doesn't use the skill, ask for it by name: *use the Our World in Data
skill to…*. That tells you whether the skill is missing or was simply not picked.

### I can't find Plugins in my settings

Plugins need a paid Claude plan — Pro, Max, Team or Enterprise. So do skills, so
there is no free route into the Claude app. If you do have a paid plan and still
can't see it, the menu may have been renamed: look for **Settings**, then anything
called **Plugins**, **Extensions** or **Add-ons**.

### Does this cost anything?

Not on our side. The skill is free, there is nothing to sign up for, and you don't
need an Our World in Data account or a key of any kind. You do need a paid plan
from Anthropic or OpenAI to use plugins in their apps at all.

### I typed `owid/skills` and it said it couldn't find it

Type it exactly: lowercase, one slash, no `https://` and no spaces. If it still
fails, try the full address `https://github.com/owid/skills` instead — some
versions of the box want the whole link rather than the short name.

### How do I remove it?

In the Claude app, open **Customize → Plugins**, find **Our World in Data** and
uninstall it — or remove the whole `owid/skills` marketplace, which takes the
plugin with it. In the ChatGPT app the same applies under **Settings → Plugins**.
If you uploaded the skill yourself, it is under **Customize → Skills** instead.

### Does Our World in Data see what I ask?

We see what any website sees: which pages and files were requested. Every request
the skill makes is labelled `owid-skills/1.0 (+https://github.com/owid/skills)`,
which is the only way we can tell the skill is being used and keep the endpoints
supported. It doesn't say who you are, and we never see your conversation. Please
leave the label in place.

### A number looks wrong

First, ask your assistant for the link to the chart itself and check the number on
that page. If it matches, the skill did its job, and any concern is about the data
rather than the skill — the chart's own page explains where it comes from. If it
doesn't match, that's our bug: please
[open an issue](https://github.com/owid/skills/issues).

Most surprises are about *which countries* came back rather than the values. Some
charts return continents and the world total instead of individual countries. Ask
your assistant to fetch the countries you want by name.

## If you work in a terminal

### My agent isn't using the skill after a terminal install

Work through these — the first two are the most common.

**1. Are the files where your agent looks?** Every agent reads a different
directory, and installing to the wrong one fails silently. The
[`skills` CLI](https://github.com/vercel-labs/skills) knows the right path for
every agent it supports and picks it for you:

```bash
npx skills add owid/skills            # into the current project
npx skills add owid/skills --global   # user-level, all projects
npx skills list                       # what is installed where
```

Many of those agents — including Codex, Cursor and Gemini CLI — share the
project-level `.agents/skills/` convention. Claude Code is the notable exception,
using `.claude/skills/` per project and `~/.claude/skills/` globally. If you
installed by hand, check with `ls .agents/skills/owid .claude/skills/owid 2>/dev/null`,
and make sure the `references/` directory came along with `SKILL.md`.

**2. Is your agent's reasoning effort turned down?** Skills are invoked through a
tool call, and lowering reasoning effort makes agents make fewer tool calls — so
a setting you turned down for cost can stop skills being used at all.

We measured this on Claude Code while testing how reliably the skill gets picked
up: at `--effort low`, five questions that reliably reach for a skill at normal
effort were answered directly instead, with no skill consulted. Nothing about the
skills changed; only the effort did.

The same class of setting exists elsewhere — Codex has `model_reasoning_effort`
(`low`/`medium`/`high`/`xhigh`/`max`/`ultra`, depending on the model) in
`~/.codex/config.toml`, and most
agents expose something similar. **We have only measured the effect on Claude
Code**, so treat the others as a plausible first thing to check rather than a
known cause. If your agent ignores skills, raise the effort and try again before
assuming the skill is at fault.

**3. Is the task substantial enough?** Agents skip skills for work they can do
unaided. "What's the URL for OWID's CO2 chart?" may not reach for anything, while
"find the best OWID chart on CO2 per capita and pull the data for the G7" will.
This is by design — it isn't a bug you need to report.

**4. Ask for it by name.** `use the owid skill to find…` bypasses routing
entirely, and is the quickest way to tell "the skill is missing" apart from
"the skill wasn't selected". In Claude Code the plugin-installed skill is
addressed as `owid:owid`.

### The skill ran, but the answer looks wrong

`SKILL.md` says which reference covers what; the details of each endpoint live
in `references/`, which the agent is told to read before making a kind of call
it has not made yet. If it skipped that step, say so: "read the search-api
reference first". If the reference itself is wrong, that is a bug — the
contract tests (`make test`) exist to catch exactly this, so please
[open an issue](https://github.com/owid/skills/issues) with the request the
agent made and the response it got.

### Does installing this put files in my repo?

Yes, if you install per-project: the skill directory is copied into your
agent's skills directory inside the project. It is `SKILL.md` plus three
Markdown files under `references/` — about 40 KB in total, no data files. Our
test fixtures and eval scripts live in a top-level `evals/` directory precisely
so they are never copied into your repository, where a fixture CSV could be
mistaken for your own data. See
[evals/README.md](evals/README.md#why-evals-live-here-and-not-inside-the-skill-directory).

To keep them out of version control, add your agent's skills directory to
`.gitignore`, or install with `--global` instead.

### Which tools do I need installed?

None. The skill only tells your assistant which web addresses to use, so it
fetches them with whatever the project already has. There are no credentials to
configure and no OWID library to install.

The skill deliberately names no tool. Prescribing one would assume something
about your setup that we have no business assuming.

### The data I got back isn't what I expected

The skill is documentation over OWID's public API; it doesn't transform values.
Fetch the same numbers directly and compare:

```
https://ourworldindata.org/grapher/life-expectancy.csv?csvType=filtered&country=USA&time=2020
```

If that matches what the agent told you, the skill worked. If it doesn't, that's
our bug — please [open an issue](https://github.com/owid/skills/issues). Three
known traps worth ruling out first, all documented in the skill:

- **`csvType=filtered` returns what the chart's current view shows**, not "all
  countries". `population.csv?csvType=filtered&time=2020` returns seven rows —
  continents and World — with no individual country. Pass an explicit `country=`
  filter, or `csvType=full`.
- **On charts whose default view is a map, `country=` is ignored.** Adding
  `tab=chart` recovers it on a chart that has a chart view; a map-only chart has
  none, so nothing recovers it and you need `csvType=full`. A filtered CSV that
  comes back with every country is this.
- **A partly-matching search still returns results.** When only some of your
  words match, OWID's search relaxes the query and returns loosely related hits
  flagged `closestMatches: true`. On a relaxed response `nbHits` counts only what
  came back, so judge the titles rather than the count. A query that matches
  nothing does come back empty.

### What happened to `search-charts`, `fetch-chart-data`, `joining-data`, `owid-catalog` and `fact-check-article`?

The first four were the first version of this repository. They covered adjacent
ground and competed for the same prompts, and two of them pulled in dependencies
(DuckDB, a Python library) that most users do not have. Their content is now in
the single `owid` skill: one reference on the search endpoint and one on the data
endpoints. `fact-check-article` was experimental and was withdrawn rather than
folded in.

If you installed the old skills by copying, delete those five directories:
plugin and `skills`-CLI installs replace them on update.

## Changing the skill

This FAQ is for people using the skill. If you want to change it, see
[`AGENTS.md`](AGENTS.md) for how the repository works and
[`evals/README.md`](evals/README.md) for how it is tested.
