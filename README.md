# OWID Skills

**An agent skill for working with [Our World in Data](https://ourworldindata.org).** Teach your AI assistant — Claude Code, Codex, the ChatGPT and Claude apps, Gemini CLI, Cursor, GitHub Copilot, and others — to find our charts and articles, download the data behind them, and cite it correctly.

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

## The skill

Skills follow the open [Agent Skills](https://agentskills.io) format (`SKILL.md`), so they work with any agent that supports the standard. There is one skill, `owid`, built as a short `SKILL.md` that holds the workflow and the rules, plus reference files the agent reads only when it needs them:

| File | What it covers |
|---|---|
| [`SKILL.md`](skills/owid/SKILL.md) | When to use it, the five-step workflow (identify, metadata first, fetch, do the task, cite), the hard rules and the traps |
| [`references/search-api.md`](skills/owid/references/search-api.md) | Every parameter of `/api/search` for charts, explorers, articles and data insights; response shapes; the `?tab=` mapping |
| [`references/data-api.md`](skills/owid/references/data-api.md) | `.csv`, `.metadata.json`, `.readme.md`, `.zip`, `.png`, `.svg` for any chart; the filtering parameters; the metadata fields and how to cite; entity, code and year conventions |
| [`references/embedding.md`](skills/owid/references/embedding.md) | The iframe snippet, when to use a PNG instead, image sizes, attribution |

It uses only public endpoints. No API key, and no tools to install.

## Installation

Pick the client you use. Every route installs the same skill.

| Client | How it takes them | One-time setup? |
|---|---|---|
| [Claude Code](#claude-code-cli) | plugin, from this repo's marketplace | no |
| [Codex](#codex-cli) | plugin, from this repo | no |
| [ChatGPT app](#chatgpt-app-chat-and-work) | plugin, added via the desktop app | developer mode |
| [Claude app](#claude-app-web-desktop-mobile) | the skill folder, as a `.zip` | enable code execution |
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
cd skills && zip -r owid.zip owid
```

In Claude, go to **Customize → Skills**, click **+**, choose **+ Create skill →
Upload a skill**, pick the zip, and toggle the skill on. Skills only apply to
conversations started after you enable them.

The skill runs in Claude's sandbox rather than on your machine. Everything it
documents is a URL over HTTPS, so it needs only network access to
ourworldindata.org from that sandbox, which we have not verified yet.

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

- **Claude app.** An uploaded skill is a frozen copy. To update it, re-zip the
  skill folder from a fresh `git pull` and upload it again.

- **`skills` CLI.** `npx skills add` installs one copy per scope, symlinks each agent's directory to it, and records what it installed in `skills-lock.json`. Update everything in that scope with:

  ```bash
  npx skills update            # -g for the user-level install, -p for the project one
  ```

- **Manual.** A copied directory is frozen; copy it again to update. A symlink into your clone follows the clone, so `git pull` in `owid-skills` is enough.

There are no version numbers to bump: every commit to `main` is a release, and each of these steps picks up the latest one.

> **Upgrading from the earlier four skills?** This repository used to ship `search-charts`, `fetch-chart-data`, `joining-data` and `owid-catalog`. They are folded into `owid` now. Plugin updates replace them automatically; if you installed by copying, delete the four old directories so they do not compete with the new skill.

### Not working?

If your agent doesn't seem to be using the skill, see the
[FAQ](FAQ.md#my-agent-isnt-using-the-skill-at-all). The two usual causes are the
files being in a directory your agent doesn't read, and your agent's reasoning
effort being turned down far enough that it stops making tool calls.

### Prerequisites

None. Everything the skill documents is an ordinary URL over HTTPS, fetched with whatever the agent and the project already use. There is nothing to install and no API key.

## Using the data

Data published by Our World in Data is open: it is available under the [Creative Commons BY license](https://ourworldindata.org/faqs#can-i-use-or-reproduce-your-data), and it builds on the work of the original data providers. The skill instructs agents to name those providers in every output — please keep the citations when you publish results.

Requests made through the skill carry the User-Agent `owid-skills/1.0 (+https://github.com/owid/skills)`. That is how we can see the skill being used and keep the endpoints it relies on supported; please leave it in place.

## Development

Want to improve the skill? See [AGENTS.md](AGENTS.md) for repo conventions, [evals/README.md](evals/README.md) for how it is evaluated, and the [FAQ](FAQ.md) for questions that come up often.

```bash
make            # list targets
make validate   # spec conformance, both plugin manifests, registration, internal links
make install    # install this repo as a plugin for Codex and the ChatGPT app
make test       # contract tests: do the OWID endpoints still match what the skill documents?
make triggers   # trigger evals: does the skill fire when it should? (needs the claude CLI, costs tokens)
make behaviour  # behaviour evals: what does the plugin change about what Claude does?
```

To try the skill in a live session, load the plugin directly with `claude --debug --plugin-dir .`

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

Three layers, and they answer different questions. [evals/README.md](evals/README.md)
is the full playbook; this is enough to run them.

```bash
make test                            # the contract tests, about a minute
```

**Contract tests** ask whether the endpoints and response shapes the skill
documents still match what the API returns. No model, no cost, seconds to run,
and they hit the live API — so a red run can also mean OWID is down, which is
deliberate. This is what CI runs on every PR and nightly, and it is the layer
that catches the failure this skill actually suffers: the prose stays put while
the API moves.

```bash
make triggers RUNS=1                         # cheapest useful loop
make triggers                                # 3 runs per query
```

**Trigger evals** ask whether the skill fires on OWID work and stays quiet on
near-misses that merely share its vocabulary. This one costs real tokens: the
default is 9 queries × 3 runs = 27 `claude -p` sessions. Pin `RUNS=1` while you
iterate on the description, and use the defaults only for a number you intend
to write down.
`EFFORT=low` is the default because routing is decided before any real work, and
`MODEL=<id>` measures that model's routing rather than the one your users get.

Run `make triggers` after changing the skill's `description` — that field is what
decides routing.

```bash
make behaviour CASE=finds-a-map-link RUNS=1   # cheapest useful loop
make behaviour                                # every case, 3 runs per arm
```

**Behaviour evals** ask whether the skill changes the answer. Each case runs
with the plugin loaded and then again with **no plugin at all**, and reports the
difference — so a case that scores the same both ways is telling you the skill
contributed nothing there, which is the point of running them. This layer uses
[`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals) and needs
Claude Code ≥ 2.1.269. Cost scales as cases × runs × 2 arms; add `-j 4` to the
underlying command if you want the full matrix without the wait.

Run `make behaviour` after changing what a skill *teaches*, as opposed to when
it fires.

This repository is limited to skills that rely on public OWID endpoints and common CLI tools; skills that require OWID-internal infrastructure or credentials are out of scope.

## License

[Apache-2.0](LICENSE)
