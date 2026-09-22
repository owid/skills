# OWID Skills

**An agent skill for working with [Our World in Data](https://ourworldindata.org).** Teach your AI agent — Claude Code, OpenAI Codex, Gemini CLI, Cursor, GitHub Copilot, and others — to find our charts and articles, download the data behind them, and cite it correctly.

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

### Claude Code

Install as a plugin from the marketplace:

```
/plugin marketplace add owid/skills
/plugin install owid@owid-skills
```

### Other agents (Codex, Gemini CLI, Cursor, Copilot, …)

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
make validate   # spec conformance, plugin manifest, registration, internal links
make test       # contract tests: do the OWID endpoints still match what the skill documents?
make triggers   # trigger evals: does the skill fire when it should? (needs the claude CLI, costs tokens)
```

To try the skill in a live session, load the plugin directly with `claude --debug --plugin-dir .`

Plugins here are versionless on purpose: every commit to `main` is a release.

This repository is limited to skills that rely on public OWID endpoints and common CLI tools; skills that require OWID-internal infrastructure or credentials are out of scope.

## License

[Apache-2.0](LICENSE)
