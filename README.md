# OWID Skills

**An agent skill for working with [Our World in Data](https://ourworldindata.org).** Teach your AI assistant — Claude Code, Codex, the ChatGPT and Claude apps, Gemini CLI, Cursor, GitHub Copilot, and others — to search published charts, explorers and articles, fetch the data and metadata behind them, embed charts, and cite the original sources.

Our World in Data publishes thousands of charts and hundreds of articles on global problems: poverty, health, energy, climate, education, and more. This skill gives agents the knowledge to use that content well — the right endpoints, the right query parameters, and the caveats that matter (which entity codes to join on, what `csvType=filtered` really returns, why "Our World in Data" alone is not a citation).

> **Status:** early and experimental. Interfaces may change. Feedback and issues are welcome!

## What you can do

Once installed, you can ask your agent things like:

- *"Find the OWID chart on child mortality and give me the URL with the map open."*
- *"Get life expectancy data for the US and UK since 1950 and plot the trend."*
- *"Someone claims 5 million children under five die every year. Is that consistent with Our World in Data?"*
- *"Convert my CSV of forest area per country into forest area per person using OWID population."*
- *"What has Hannah Ritchie written on OWID recently?"*
- *"Embed the CO₂ per capita chart in this HTML page, or give me a PNG for the slides."*
- *"Where does the data in this chart come from and how was it processed?"*

The skill triggers automatically when relevant — you don't need to invoke it by name.

## Installation

Nothing to install first, and no account or key to get.

Find your app below. They all install the same thing. **If you use the Claude app
or the ChatGPT app, use one of the first two** — the rest are for people who work
in a terminal.

| Your app | How you install it | Anything to turn on first? |
|---|---|---|
| [Claude app](#claude-app-web-desktop-mobile) | in the app, in a few clicks | no |
| [ChatGPT app](#chatgpt-app-chat-and-work) | in the app, in a few clicks | yes, a setting called Developer mode — you don't need to be a developer |
| [Claude Code](#claude-code-cli) | two commands | no |
| [Codex](#codex-cli) | two commands, in a terminal | no |
| [Anything else](#other-agents-gemini-cli-cursor-copilot-) | by copying the skill folder | no |

### Claude app (web, desktop, mobile)

1. Open Claude and go to **Customize → Plugins**.
2. Under *Personal plugins*, click **+**, then **Add marketplace**, then **Add
   from a repository**.
3. Type `owid/skills` in the box and confirm. That is the address of this
   project on GitHub — it is public and free.
4. Click **Browse plugins**, find **Our World in Data**, and install it.
5. New plugins arrive switched off. Find the switch and turn it on.
6. Start a **new** chat. The plugin only applies to conversations you begin after
   switching it on.

Then [check it worked](#check-it-worked).

On Team and Enterprise, an admin can add the marketplace once for the whole
organization instead, and it shows up in everyone's directory.

### ChatGPT app (Chat and Work)

The skill isn't in OpenAI's public Plugin Directory yet, so you add this project
as your own source. That step needs the **desktop** app. After that it works
everywhere you use ChatGPT — web, desktop and phone.

1. Go to **Settings → Security and login** and turn on **Developer mode**. If you
   can't see it, your workplace has probably switched it off — ask whoever
   manages your ChatGPT account.
2. Open **Plugins → Add marketplace** and type `owid/skills`. Leave any other
   fields as they are.
3. The project appears as **Our World in Data**; install it there.
4. Start a new conversation.

Then [check it worked](#check-it-worked).

If you're setting this up for colleagues rather than yourself, a workspace admin
can import and sync a GitHub marketplace for the whole workspace, so nobody else
has to touch developer mode.

### Claude Code (CLI)

Type these two lines into Claude Code's own prompt, one at a time. They start
with a slash, which is how it knows they are commands rather than questions.

```
/plugin marketplace add owid/skills
/plugin install owid@owid-skills
```

The first line tells Claude Code where to find the skill; the second installs it.
Then [check it worked](#check-it-worked).

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

The skill is a plain [Agent Skills](https://agentskills.io) folder, so you can also copy or symlink it into whatever directory your agent reads. Clone the repo:

```bash
git clone https://github.com/owid/skills owid-skills
```

Then put `owid-skills/skills/owid` where your agent looks for skills:

- **Per project** — `./.agents/skills/` (the shared convention read by Codex, Cursor, OpenCode, …)
- **Per user** — your agent's own skills directory, e.g. `~/.codex/skills/`, `~/.gemini/skills/`, or `~/.claude/skills/`

Copy the whole `owid/` directory, not just `SKILL.md`: the references live next to it.

### Check it worked

Start a new chat and ask:

> Find the Our World in Data chart on child mortality and give me the link.

You should get back a link to a chart on ourworldindata.org, and the name of the
organisation that produced the data. If you get a vague answer with no link, see
[Not working?](#not-working) below.

### Keeping the skill up to date

Every route above installs a snapshot of `main` as it was that day. Nothing refreshes on its own unless you turn it on, so use the step that matches how you installed:

- **Claude Code plugin.** Auto-update is off by default for marketplaces other than Anthropic's own. Turn it on once: run `/plugin`, open the **Marketplaces** tab, select `owid-skills` and choose **Enable auto-update**. Claude Code then checks shortly after each session starts and tells you to `/reload-plugins` when something changed. To update by hand instead:

  ```bash
  claude plugin marketplace update owid-skills   # refresh the catalog
  claude plugin update owid@owid-skills          # then restart, or /reload-plugins
  ```

  Refreshing the marketplace on its own does not update the installed plugin; the second command does.

- **Codex / ChatGPT plugin.** Refresh the source, then reinstall:

  ```bash
  codex plugin marketplace upgrade owid-skills
  codex plugin add owid@owid-skills
  ```

  Restart the ChatGPT desktop app afterwards so it picks up the new files.

- **Claude app.** A plugin installed from the marketplace follows this repo, like
  the other plugin routes. Anything you uploaded — a plugin archive or a single
  skill — is a frozen copy instead: rebuild it from a fresh `git pull` and upload
  it again, and delete an upload you are done with, so it does not sit beside the
  marketplace copy answering the same prompts.

- **`skills` CLI.** `npx skills add` installs one copy per scope, symlinks each agent's directory to it, and records what it installed — `skills-lock.json` in the project, `~/.agents/.skill-lock.json` for a global install. Update everything in that scope with:

  ```bash
  npx skills update            # -g for the user-level install, -p for the project one
  ```

- **Manual.** A copied directory is frozen; copy it again to update. A symlink into your clone follows the clone, so `git pull` in `owid-skills` is enough.

There are no version numbers to bump: every commit to `main` is a release, and each of these steps picks up the latest one.

> **Upgrading from the earlier four skills?** This repository used to ship `search-charts`, `fetch-chart-data`, `joining-data` and `owid-catalog`. They are folded into `owid` now. Plugin updates replace them automatically; if you installed by copying, delete the four old directories so they do not compete with the new skill.

### Not working?

If you installed in the Claude or ChatGPT app, check three things first: the
plugin is switched on, you started a new chat after switching it on, and your
question is specific enough — "find the OWID chart on child mortality and pull
the data" will use it, "what's OWID" may not. If it still doesn't fire, ask for it
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

Our World in Data's own work is free to reuse under the [Creative Commons BY license](https://ourworldindata.org/faqs#can-i-reuse-or-republish-your-data). Most of the data, though, comes from other producers and keeps whatever licence they set, so check before you republish — and a few charts cannot be downloaded at all. The skill instructs agents to name the original producer, so please keep the citations when you publish results.

Every request the skill makes identifies itself as coming from this skill, which is how we can see it being used and keep supporting it.

## Contributing

Want to change the skill itself? Start with [`AGENTS.md`](AGENTS.md). Issues and
pull requests are welcome.

## License

[Apache-2.0](LICENSE)
