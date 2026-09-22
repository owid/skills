# OWID Skills

**Agent skills for working with [Our World in Data](https://ourworldindata.org).** Teach your AI assistant — Claude Code, Codex, the ChatGPT and Claude apps, Gemini CLI, Cursor, GitHub Copilot, and others — to search our charts, download the data behind them, and analyze it correctly.

Our World in Data publishes thousands of charts and datasets on global problems: poverty, health, energy, climate, education, and more. These skills give agents the knowledge to use that data well — the right APIs, the right query parameters, and the caveats that matter (country harmonization, citations, metadata).

> **Status:** early and experimental. Interfaces may change. Feedback and issues are welcome!

## What you can do

Once installed, you can ask your agent things like:

- *"Get life expectancy data for the US and UK since 1950 and plot the trend."*
- *"Find OWID charts about renewable energy adoption."*
- *"Download CO₂ emissions per country and compute per-capita values using OWID population data."*
- *"Make a scatter plot of child mortality against GDP per capita."*

The skills trigger automatically when relevant — you don't need to invoke them by name.

## Skills

Skills follow the open [Agent Skills](https://agentskills.io) format (`SKILL.md`), so they work with any agent that supports the standard.

| Skill | What it does | Requires |
|---|---|---|
| [`search-charts`](skills/search-charts/SKILL.md) | Search OWID's published charts by keyword | `curl`, `jq` |
| [`fetch-chart-data`](skills/fetch-chart-data/SKILL.md) | Download the data and metadata behind any chart | `curl`, `jq` |
| [`joining-data`](skills/joining-data/SKILL.md) | Join OWID data with external sources (per-capita metrics, scatter plots vs GDP, …) | `duckdb` |
| [`owid-catalog`](skills/owid-catalog/SKILL.md) | Python-native access to the full OWID catalog (charts, tables, indicators) via the [`owid-catalog`](https://pypi.org/project/owid-catalog/) library | `uv` (or `pip`) |

The HTTP-based skills are lightweight and language-agnostic. `owid-catalog` is the richer option when Python is available — it returns metadata-aware DataFrames and covers the full data catalog beyond published charts.

## Installation

Pick the client you use. Every route installs the same four skills.

| Client | How it takes them | One-time setup? |
|---|---|---|
| [Claude Code](#claude-code-cli) | plugin, from this repo's marketplace | no |
| [Codex](#codex-cli) | plugin, from this repo | no |
| [ChatGPT app](#chatgpt-app-chat-and-work) | plugin, added via the desktop app | developer mode |
| [Claude app](#claude-app-web-desktop-mobile) | one skill at a time, as a `.zip` | enable code execution |
| [Anything else](#other-agents-gemini-cli-cursor-copilot-) | plain skill folders | no |

### Claude Code (CLI)

Install as a plugin from the marketplace:

```
/plugin marketplace add owid/skills
/plugin install owid@owid-skills
```

### Codex (CLI)

This repo is also an [Agent Plugins](https://agent-plugins.org) package, the
vendor-neutral plugin format ChatGPT and Codex share:

```bash
codex plugin marketplace add owid/skills   # register this repo as a source
codex plugin add owid@owid-skills          # install it
```

`codex plugin list` shows what resolved, and `/plugins` inside a session lists
what's active.

### ChatGPT app (Chat and Work)

The skills aren't in OpenAI's public Plugin Directory yet, so you add this repo
as your own plugin source. That step needs the **desktop** app; once installed,
the plugin works in both Chat and Work on web, desktop and mobile. The IDE
extension doesn't support plugins at all.

1. **Settings → Security and login → Developer mode**, turn it on. (Availability
   can depend on your account and workspace policy.)
2. Register this repo as a source, using the Codex CLI command above —
   `codex plugin marketplace add owid/skills`. The ChatGPT desktop app reads the
   same sources.
3. Restart the ChatGPT desktop app.
4. Switch to **Work** in the switcher (or open **Codex**), then open **Plugins**.
   This repo appears as **Our World in Data** under your personal marketplace;
   install it there.
5. Start a new conversation. Describe what you want, or invoke the plugin
   explicitly with `@`.

If you're setting this up for colleagues rather than yourself, a workspace admin
can import and sync a GitHub marketplace for the whole workspace, so nobody else
has to touch developer mode.

### Claude app (web, desktop, mobile)

Claude's apps don't read plugin marketplaces — they take **one skill at a time,
as a zip**. First enable **Settings → Capabilities → Code execution and file
creation** (on Team and Enterprise an owner enables it under **Organization
settings → Skills**). Then, from a clone of this repo:

```bash
cd skills && zip -r search-charts.zip search-charts    # one zip per skill
```

In Claude, go to **Customize → Skills**, click **+**, choose **+ Create skill →
Upload a skill**, pick the zip, and toggle the skill on. Skills only apply to
conversations started after you enable them.

Skills run in Claude's sandbox rather than on your machine, so the prerequisites
differ from the table above and we haven't verified all four there:
`search-charts` and `fetch-chart-data` need only network access, while
`joining-data` and `owid-catalog` need `duckdb` and Python packages.

### Other agents (Gemini CLI, Cursor, Copilot, …)

These are standard [Agent Skills](https://agentskills.io), read as-is by Codex, Gemini CLI, Cursor, GitHub Copilot, and many other tools — no Claude-specific setup required. The [`skills`](https://github.com/vercel-labs/skills) CLI detects which of your installed agents support skills (75+ supported) and installs them into each one's directory:

```bash
npx skills add owid/skills            # into the current project
npx skills add owid/skills --global   # user-level, across all your projects
```

Add `--agent '*'` to install to every supported agent, or `--list` to preview the skills first.

### Manual

The skills are plain [Agent Skills](https://agentskills.io) folders, so you can also copy or symlink them into whatever directory your agent reads. Clone the repo:

```bash
git clone https://github.com/owid/skills owid-skills
```

Then put `owid-skills/skills/*` where your agent looks for skills:

- **Per project** — `./.agents/skills/` (the shared convention read by Codex, Cursor, OpenCode, …)
- **Per user** — your agent's own skills directory, e.g. `~/.codex/skills/`, `~/.gemini/skills/`, or `~/.claude/skills/`

### Keeping the skills up to date

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

- **Claude app.** An uploaded skill is a frozen copy. To update it, re-zip the
  skill folder from a fresh `git pull` and upload it again.

- **`skills` CLI.** `npx skills add` installs one copy per scope, symlinks each agent's directory to it, and records what it installed in `skills-lock.json`. Update everything in that scope with:

  ```bash
  npx skills update            # -g for the user-level install, -p for the project one
  ```

- **Manual.** A copied directory is frozen; copy it again to update. A symlink into your clone follows the clone, so `git pull` in `owid-skills` is enough.

There are no version numbers to bump: every commit to `main` is a release, and each of these steps picks up the latest one.

### Not working?

If your agent doesn't seem to be using the skills, see the
[FAQ](FAQ.md#my-agent-isnt-using-the-skills-at-all). The two usual causes are the
files being in a directory your agent doesn't read, and your agent's reasoning
effort being turned down far enough that it stops making tool calls.

### Prerequisites

The skills use a few common command-line tools: `curl`, `jq`, `duckdb`, and `uv`. Install them with your package manager (e.g. `brew install jq duckdb uv`), or on macOS run:

```bash
curl -sSL https://raw.githubusercontent.com/owid/skills/main/install-prerequisites-macos.sh | bash
```

## Using the data

Data published by Our World in Data is open: it is available under the [Creative Commons BY license](https://ourworldindata.org/faqs#can-i-use-or-reproduce-your-data), and it builds on the work of the original data providers. The skills instruct agents to surface proper citations — please keep them when you publish results.

## Development

Want to add or improve a skill? See [AGENTS.md](AGENTS.md) for repo conventions, [evals/README.md](evals/README.md) for how the skills are evaluated, and the [FAQ](FAQ.md) for questions that come up often.

```bash
make            # list targets
make validate   # spec conformance, both plugin manifests and marketplace registration
make install    # install this repo as a plugin for Codex and the ChatGPT app
make test       # contract tests: do the OWID endpoints still match what the skills document?
make triggers   # trigger evals: does the right skill fire? (needs the claude CLI, costs tokens)
```

To try the skills in a live session, load the plugin directly with `claude --debug --plugin-dir .`

### Trying a branch

`make install` registers this repo as a plugin source for the Codex CLI, which
is also where the ChatGPT desktop app looks. Add `BRANCH=` to point it at a
branch instead of `main`:

```bash
make install BRANCH=my-feature
```

Re-running it repoints an existing install, so you can switch branches freely.
It prints the remaining ChatGPT-app steps (developer mode, restart) and the two
commands that undo it.

### Running the evals

Two layers, and they answer different questions. [evals/README.md](evals/README.md)
is the full playbook; this is enough to run them.

```bash
make test                            # all four skills
make test SKILL=search-charts        # one
SKIP_SLOW=1 make test                # skip the slow owid-catalog checks
```

**Contract tests** ask whether the endpoints and response shapes each `SKILL.md`
documents still match what the API returns. No model, no cost, seconds to run,
and they hit the live API — so a red run can also mean OWID is down, which is
deliberate. This is what CI runs on every PR and nightly, and it is the layer
that catches the failure these skills actually suffer: the prose stays put while
the API moves.

```bash
make triggers SKILL=search-charts RUNS=1     # cheapest useful loop
make triggers                                # all four, 3 runs each
```

**Trigger evals** ask whether the right skill fires — and, because all four cover
overlapping subject matter, whether one is stealing a sibling's queries. This
one costs real tokens: the default is 4 skills × 10 queries × 3 runs = 120
`claude -p` sessions. Pin `SKILL` and `RUNS=1` while you iterate on a
description, and use the defaults only for a number you intend to write down.
`EFFORT=low` is the default because routing is decided before any real work, and
`MODEL=<id>` measures that model's routing rather than the one your users get.

Run `make triggers` after changing any skill's `description` — that field is what
decides routing, and a wording change can quietly redirect a sibling's traffic.

Plugins here are versionless on purpose: every commit to `main` is a release.

This repository is limited to skills that rely on public OWID endpoints and common CLI tools; skills that require OWID-internal infrastructure or credentials are out of scope.

## License

[Apache-2.0](LICENSE)
