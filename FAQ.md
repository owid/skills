# FAQ

Common questions about using and contributing to the skill. For repo
conventions see [AGENTS.md](AGENTS.md); for how the skill is evaluated see
[evals/README.md](evals/README.md).

## Using the skill

### My agent isn't using the skill at all

Work through these in order — the first two are the most common.

**1. Are the files where your agent looks?** Every agent reads a different
directory, and installing to the wrong one fails silently. The
[`skills` CLI](https://github.com/vercel-labs/skills) knows the paths for 76
agents and picks the right one:

```bash
npx skills add owid/skills            # into the current project
npx skills add owid/skills --global   # user-level, all projects
npx skills list                       # what is installed where
```

Nineteen of those agents — including Codex, Cursor and Gemini CLI — share the
project-level `.agents/skills/` convention. Claude Code is the notable exception,
using `.claude/skills/` per project and `~/.claude/skills/` globally. If you
installed by hand, check with `ls .agents/skills/owid .claude/skills/owid 2>/dev/null`,
and make sure the `references/` directory came along with `SKILL.md`.

**2. Is your agent's reasoning effort turned down?** Skills are invoked through a
tool call, and lowering reasoning effort makes agents make fewer tool calls — so
a setting you turned down for cost can stop skills firing at all.

We measured this on Claude Code while building the trigger evals: at
`--effort low`, five queries that reliably invoke a skill at normal effort were
answered directly instead, with no skill consulted. Nothing about the skills
changed; only the effort did.

The same class of setting exists elsewhere — Codex has `model_reasoning_effort`
(`minimal`/`low`/`medium`/`high`/`xhigh`) in `~/.codex/config.toml`, and most
agents expose something similar. **We have only measured the effect on Claude
Code**, so treat the others as a plausible first thing to check rather than a
known cause. If your agent ignores skills, raise the effort and try again before
assuming the skill is at fault.

**3. Is the task substantial enough?** Agents skip skills for work they can do
unaided. "What's the URL for OWID's CO2 chart?" may not trigger anything, while
"find the best OWID chart on CO2 per capita and pull the data for the G7" will.
This is by design — it isn't a bug you need to report.

**4. Ask for it by name.** `use the owid skill to find…` bypasses routing
entirely, and is the quickest way to tell "the skill is missing" apart from
"the skill wasn't selected". In Claude Code the plugin-installed skill is
addressed as `owid:owid`.

### The skill fired but the agent still got the API wrong

`SKILL.md` holds the workflow and the rules; the details of each endpoint live
in `references/`, which the agent is told to read before making a kind of call
it has not made yet. If it skipped that step, say so: "read the search-api
reference first". If the reference itself is wrong, that is a bug — the
contract tests (`make test`) exist to catch exactly this, so please
[open an issue](https://github.com/owid/skills/issues) with the request the
agent made and the response it got.

### Does installing this put files in my repo?

Yes, if you install per-project: the skill directory is copied into your
agent's skills directory inside the project. It is `SKILL.md` plus four
Markdown files under `references/` — about 40 KB in total, no data files. Our
test fixtures and eval scripts live in a top-level `evals/` directory precisely
so they are never copied into your repository, where a fixture CSV could be
mistaken for your own data. See
[evals/README.md](evals/README.md#why-evals-live-here-and-not-inside-the-skill-directory).

To keep them out of version control, add your agent's skills directory to
`.gitignore`, or install with `--global` instead.

### Which tools do I need installed?

`curl` and `jq`. Nothing else: the skill only uses public OWID endpoints, so
there are no credentials to configure, and it deliberately does not depend on
Python, DuckDB or any OWID library. On macOS,
`./install-prerequisites-macos.sh` installs `jq` (curl is already there).

If you work in Python, the same URLs load with `pandas.read_csv`, and the skill
says so; the [`owid-catalog`](https://docs.owid.io/projects/etl/api/) library is
mentioned as an option, not a requirement.

### Why does every request carry a `User-Agent`?

The skill sends `owid-skills/1.0 (+https://github.com/owid/skills)` on every
call. It identifies traffic that comes through the skill, which is the only way
we can tell whether it is used and keep the endpoints supported. It does not
identify you. Please leave it in place.

### A skill gave me data I think is wrong

Check whether the skill or the data is at fault. The skill is documentation
over OWID's public API; it doesn't transform values. Fetch the same numbers
directly:

```bash
curl -s "https://ourworldindata.org/grapher/life-expectancy.csv?csvType=filtered&country=USA&time=2020"
```

If that matches what the agent told you, the skill worked and any concern belongs
with the underlying data — see the chart's own page on
[ourworldindata.org](https://ourworldindata.org). If it doesn't match, that's our
bug. Three known traps worth ruling out first, all documented in the skill:

- **`csvType=filtered` applies the chart's own default entity selection**, not
  "all countries". `population.csv?csvType=filtered&time=2020` returns seven rows
  — continents and World — with no individual country. Pass an explicit
  `country=` filter, or `csvType=full`.
- **On charts whose default view is a map, `country=` is ignored** unless the
  request also carries `tab=chart`. A filtered CSV that comes back with every
  country is this.
- **A no-match search still returns results.** OWID's search falls back to
  low-relevance hits (flagged `closestMatches: true`) rather than returning
  nothing, so `nbHits` is never a reliable signal that a topic is missing. Judge
  the titles.

### What happened to `search-charts`, `fetch-chart-data`, `joining-data` and `owid-catalog`?

They were the first version of this repository. The four covered adjacent
ground and competed for the same prompts, and two of them pulled in
dependencies (DuckDB, a Python library) that most users do not have. Their
content is now in the single `owid` skill: one reference on the search endpoint
and one on the data endpoints. Python users can still use the
[`owid-catalog`](https://docs.owid.io/projects/etl/api/) library directly.

If you installed the old skills by copying, delete those four directories:
plugin and `skills`-CLI installs replace them on update.

## Contributing

### `make test` fails and I didn't change anything

That is the contract tests doing their job. They check the OWID endpoints and
response shapes the skill documents against what the API actually returns, so
they can break when OWID ships a change and nobody has touched this repo. They
also run nightly for exactly that reason.

Read the failure before assuming it's a flake — it names the endpoint and the
mismatch, and the downloaded responses are kept under `evals/results/contract/`
so you can inspect one without re-running. Network outages also surface here,
which is intentional.

### `make triggers` costs a lot. How do I make it cheaper?

It runs `queries x RUNS` full agent sessions — 30 for the default invocation.
While iterating on the description, narrow it:

```bash
make triggers RUNS=1
```

Don't reach for a lower effort level to save money: as above, effort changes
whether skills fire at all, so a cheap run measures something other than what
your users experience. Same caution for `MODEL=` — routing is model-dependent, so
a cheaper model measures that model's routing. Both are fine for fast iteration
on wording, then confirm on the real model and effort before believing a number.

### Why does the skill never mention its own evals?

Because the `description`, `SKILL.md` and any reference it points to are loaded
into the user's context when the skill triggers, and eval prose would be pure
overhead there. It's enforced by `make validate`, not left to discipline.

### `make triggers` exits non-zero. Is that a failure?

Only if runs errored. Trigger accuracy is a measurement, not a pass/fail gate —
100% routing accuracy isn't a realistic bar. The runner exits non-zero when runs
actually failed (meaning the numbers can't be trusted) or when you set a floor
with `--min-accuracy`. `make test` is the gate.

### How do I add to the skill?

See [AGENTS.md](AGENTS.md). The short version: detail goes in a reference file
under `skills/owid/references/`, rules and workflow go in `SKILL.md`, every new
API claim gets a check in `evals/skills/owid/contract.sh`, and `make validate`
plus `make test` must pass. Prefer adding a reference over adding a sibling
skill.
