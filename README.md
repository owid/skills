# AI skill for Our World in Data

**An agent skill for working with [Our World in Data](https://ourworldindata.org).** It teaches your AI assistant to find our charts and articles, pull the numbers behind them, put a chart into a page or a slide, and credit whoever produced the data.

It works with the Claude and ChatGPT apps, Claude Code, Codex, Gemini CLI, Cursor, GitHub Copilot and others.

Our World in Data publishes thousands of charts and hundreds of articles on global problems: poverty, health, energy, climate, education, and more. This skill teaches assistants how to use that content properly: how to find the right chart, how to get the numbers behind it, what the data does and does not mean, and how to credit the people who collected it.

## What you can do

Once installed, you can ask your agent things like:

- *"Find the OWID chart on child mortality and give me the URL with the map open."*
- *"Get life expectancy data for the US and UK since 1950 and plot the trend."*
- *"Someone claims 5 million children under five die every year. Is that consistent with Our World in Data?"*
- *"Convert my CSV of forest area per country into forest area per person using OWID population."*
- *"What has Hannah Ritchie written on OWID recently?"*
- *"Embed the CO₂ per capita chart in this HTML page, or give me a PNG for the slides."*
- *"Where does the data in this chart come from and how was it processed?"*

You don't have to ask for it by name. Your assistant uses it on its own whenever your question is about our charts or data.

## Installation

The quickest way is to ask your AI assistant to do it. Send it this:

> Install the OWID skill hosted at https://github.com/owid/skills/

Claude Code and Codex can carry that out themselves. The Claude and ChatGPT apps
will read this page and walk you through it.

To do it by hand, find your app below. They all install the same thing, and none
of them needs an OWID account or an API key. **If you use the Claude app or the
ChatGPT app, use one of the first two** — the rest are for people who work in a
terminal.

Use one of those routes if you can: they install the skill from this project, so
it keeps up with our changes. The last two — uploading the skill by hand, or
copying the folder — give you a fixed copy that never updates itself. They are
there for when the others don't work for you.

In the apps this arrives as a **plugin**. A plugin is the wrapper a skill comes
in: install the plugin and you have the skill. You will also see the same thing
called `owid/skills` (the address it comes from), **Our World in Data** (what you
click) and `owid@owid-skills` (what the terminal commands call it).

| Your app | How you install it |
|---|---|
| [Claude app](#claude-app-web-and-desktop) | in the app, in a few clicks |
| [ChatGPT app](#chatgpt-app-chat-and-work) | in the app, in a few clicks |
| [Claude Code](#claude-code-cli) | two commands, at Claude Code's own prompt |
| [Codex](#codex-cli) | two commands, in a terminal |
| [Anything else](#other-agents-gemini-cli-cursor-copilot-) | one command in a terminal |

### Claude app (web and desktop)

You are going to point Claude at this project on GitHub, where the skill lives.
Claude calls a collection of add-ons a *marketplace*, and the place ours is kept a
*repository*. You don't need to know more than that — you paste one short address
and Claude does the rest. No GitHub account needed.

1. Open Claude. Click your name at the bottom left, then **Customize**, then the
   **Plugins** tab.
2. Under *Personal plugins*, click **+**, then **Add marketplace**, then
   **Add from a repository**.
3. A box appears. Type `owid/skills` and confirm.
4. Click **Browse plugins**, find **Our World in Data**, and click **Install**.
5. If it shows a switch next to its name, make sure it is on.
6. Start a **new** chat. The plugin only applies to conversations you begin after
   installing it.

Then [check it worked](#check-it-worked).

*Setting this up for a team?* On Team and Enterprise plans an admin can add
`owid/skills` once for everyone, and it appears in every colleague's plugin list,
so nobody else has to do the steps above.

### ChatGPT app (Chat and Work)

The skill isn't in OpenAI's own plugin list yet, so you point ChatGPT at where it
lives on GitHub. This works on chatgpt.com as well as in the desktop app.

1. Open **Settings → Plugins**, choose **Add marketplace**, and type
   `owid/skills`. That is the address of this project on GitHub. Leave every
   other field alone.
2. Find **Our World in Data** in the list and install it.
3. Start a **new** conversation. The plugin only applies to chats you start after
   installing it.

Then [check it worked](#check-it-worked).

If you're setting this up for colleagues rather than yourself, a workspace admin
can import and sync a GitHub marketplace for the whole workspace.

### Claude Code (CLI)

Type these two lines into Claude Code's own prompt, one at a time. They start
with a slash, which is how it knows they are commands rather than questions.

```
/plugin marketplace add owid/skills
/plugin install owid@owid-skills
```

The first line tells Claude Code where to find the skill; the second installs it.
Then run `/reload-plugins`, or restart Claude Code, so it picks the skill up —
Claude Code will prompt you for this. Then [check it worked](#check-it-worked).

### Codex (CLI)

Codex is a tool you run by typing in a terminal. If that isn't you, use one of the
app routes above.

This repo is also an [Agent Plugins](https://agent-plugins.org) package, the
format ChatGPT and Codex share. In a terminal:

```bash
codex plugin marketplace add owid/skills
codex plugin add owid@owid-skills
```

The first line registers this project as a source; the second installs the skill.
`codex plugin list` shows what it installed. Then
[check it worked](#check-it-worked).

### Other agents (Gemini CLI, Cursor, Copilot, …)

This is a standard [Agent Skill](https://agentskills.io), read as-is by Codex, Gemini CLI, Cursor, GitHub Copilot, and many other tools — no Claude-specific setup required. The [`skills`](https://github.com/vercel-labs/skills) CLI detects which of your installed agents support skills (75+ supported) and installs it into each one's directory:

```bash
npx skills add owid/skills            # into the current project
npx skills add owid/skills --global   # user-level, across all your projects
```

Add `--agent '*'` to install to every supported agent, or `--list` to preview first.

### Manual

This one is for developers. If you are not comfortable in a terminal, use one of
the app routes above.

The skill is a plain [Agent Skills](https://agentskills.io) folder, so you can also copy or symlink it into whatever directory your agent reads. Clone the repo:

```bash
git clone https://github.com/owid/skills owid-skills
```

Then put `owid-skills/skills/owid` where your agent looks for skills:

- **Per project** — `./.agents/skills/` (the shared convention read by Codex, Cursor, OpenCode, …)
- **Per user** — your agent's own skills directory, e.g. `~/.codex/skills/`, `~/.gemini/skills/`, or `~/.claude/skills/`

Copy the whole `owid/` directory, not just `SKILL.md`: the references live next to it.

### Claude app, without a paid plan

Plugins need a paid Claude plan, but skills do not. If you are on the free plan,
upload the skill on its own instead:

1. Turn on **Settings → Capabilities → Code execution and file creation**. Skills
   are greyed out without it.
2. Download this repository and zip the skill folder, so that `owid` is the top
   level of the zip: `cd skills && zip -r owid.zip owid`.
3. In Claude, go to **Customize → Skills → + → Create skill → Upload a skill**
   and choose that zip.

An uploaded skill is a fixed copy — it will not update itself, so repeat this
when you want a newer version.

### Check it worked

Start a new chat and ask:

> Tell me what source this OWID chart relies on:
> https://ourworldindata.org/grapher/child-mortality — and fetch the complete
> time series for Uganda.

A working install names **Gapminder and the UN Inter-agency Group for Child
Mortality Estimation**, not "Our World in Data", and comes back with the whole
series for Uganda — about seventy yearly figures, starting in the 1950s.

Both halves matter. An assistant without the skill will usually name us as the
source rather than the people who collected the data, and will summarise or
invent the numbers instead of fetching them. If that is what you get, see
[Not working?](#not-working) below.

### Keeping the skill up to date

However you installed it, you got the skill as it was that day. It does not update itself unless you turn that on. Find the way you installed it:

- **Claude app.** Nothing to do: a plugin installed from the plugin list keeps
  itself up to date.

- **Claude Code plugin.** Auto-update is off by default for marketplaces other than Anthropic's own. Turn it on once: run `/plugin`, open the **Marketplaces** tab, select `owid-skills` and choose **Enable auto-update**. Claude Code then checks within about ten minutes of a session starting, and tells you to `/reload-plugins` when something changed. To update by hand instead:

  ```bash
  claude plugin marketplace update owid-skills   # refresh the catalog
  claude plugin update owid@owid-skills          # then restart, or /reload-plugins
  ```

  Refreshing the marketplace on its own does not update the installed plugin; the second command does.

- **Codex / ChatGPT plugin.** Refresh the source, then reinstall:

  ```bash
  codex plugin marketplace upgrade owid-skills   # refresh the source
  codex plugin remove owid@owid-skills           # then reinstall
  codex plugin add owid@owid-skills
  ```

  Restart the ChatGPT desktop app afterwards so it picks up the new files.

- **`skills` CLI.** `npx skills add` installs one copy per scope, symlinks each agent's directory to it, and records what it installed — `skills-lock.json` in the project, `~/.agents/.skill-lock.json` for a global install. Update everything in that scope with:

  ```bash
  npx skills update            # -g for the user-level install, -p for the project one
  ```

- **Manual.** A copied directory is frozen; copy it again to update. A symlink into your clone follows the clone, so `git pull` in `owid-skills` is enough.

There are no version numbers to bump: every commit to `main` is a release, and each of these steps picks up the latest one.

> **Upgrading from an earlier version?** This repository used to ship `search-charts`, `fetch-chart-data`, `joining-data`, `owid-catalog` and `fact-check-article`. They are folded into `owid` now. Plugin updates replace them automatically; if you installed by copying, delete the old directories so they do not compete with the new skill.

### Not working?

If you installed in the Claude or ChatGPT app, check three things first: the
plugin is switched on, you started a new chat after switching it on, and your
question is specific enough — "find the OWID chart on child mortality and pull
the data" will use it, "what's OWID" may not. If it still doesn't use the skill, ask for it
by name: *use the Our World in Data skill to…*

For anything else, see the [FAQ](FAQ.md#my-agent-isnt-using-the-skill-at-all).

## What's in it

The skill is a short set of notes your assistant reads when it needs them: how to
search our site, how to fetch the data and sources behind a chart, and how to put
a chart into a page or a slide. You can read them in
[`skills/owid/`](skills/owid/) if you're curious.

It follows the open [Agent Skills](https://agentskills.io) format, so it works
with any assistant that supports the standard.

## Using the data

Our World in Data's own work is free to reuse under the [Creative Commons BY licence](https://ourworldindata.org/faqs#can-i-reuse-or-republish-your-data). Most of the data, though, comes from other producers and keeps whatever licence they set, so check before you republish — and a few charts cannot be downloaded at all. The skill instructs agents to name the original producer, so please keep the citations when you publish results.

Every request the skill makes identifies itself as coming from this skill, which is how we can see it being used and keep supporting it.

## License

[Apache-2.0](LICENSE)
