# Repository guide for agents

This repository publishes **agent skills for working with Our World in Data** (see [README.md](README.md)). The repo root is itself a plugin named `owid` that bundles every skill under `skills/`, packaged two ways so one commit serves both ecosystems:

- `.claude-plugin/marketplace.json` — Claude Code's marketplace format.
- `plugin.json` — the vendor-neutral [Agent Plugins](https://agent-plugins.org/) format, which ChatGPT and Codex read.

Today there is one skill, `owid`, structured as a short `SKILL.md` plus a
`references/` directory the agent reads on demand. That is deliberate: the
tasks people bring to OWID (find a chart, get its data, check a number, embed
it) share one workflow and two endpoints, and one skill with a broad trigger
routes better than several narrow ones competing for the same prompt.

## Structure

```
FAQ.md                            # common user and contributor questions
Makefile                          # entry points: make validate / lint / install / test / triggers / behaviour
skills/owid/SKILL.md              # the workflow and the rules (~150 lines, always loaded)
skills/owid/references/*.md       # one file per endpoint or topic, read when needed
.claude-plugin/marketplace.json   # Claude Code marketplace + plugin definition
.claude-plugin/plugin.json        # the plugin's own Claude manifest; `claude plugin eval` needs it
plugin.json                       # Agent Plugins manifest (ChatGPT, Codex)
.agents/plugins/                  # repo-scoped catalog: lets ChatGPT/Codex install the repo as-is
evals/skills/<skill-name>/        # that skill's test cases and fixtures
evals/                            # shared eval harness + playbook (evals/README.md)
```

**Everything under `skills/<skill-name>/` ships to every user.** A skill
directory is copied recursively into users' projects by the cross-agent
installer, which has no ignore mechanism. Put only `SKILL.md` and the
`references/`, `scripts/` or `assets/` the skill genuinely needs there. Evals
live in a sibling `evals/skills/<skill-name>/` for exactly this reason; see
[evals/README.md](evals/README.md).

## Changing the skill

- **`SKILL.md` is the context budget.** It is loaded whole whenever the skill
  triggers, so it holds the workflow, the hard rules, the quick reference and
  the traps, and nothing an agent only needs sometimes. Aim to keep it near its
  current length; move detail into a reference.
- **References are the documentation.** Each file under `references/` covers
  one endpoint or topic exhaustively: every parameter, the response shape,
  recipes, traps. `SKILL.md` names the reference to read for each kind of task.
  Link between references with relative links; `make validate` checks they
  resolve.
- **The `description` field decides when the skill fires.** It is the only
  thing an agent sees before choosing to load the skill. Keep it about *what
  the skill does and when to use it*, under 1024 characters. After changing it,
  re-run the trigger eval (`make triggers`).
- **Every claim about the API should have a contract test.** The skill is
  documentation over live endpoints, and it rots when the API changes, not when
  the prose gets worse. Add a check to `evals/skills/owid/contract.sh` when you
  document a new parameter, endpoint or behaviour, and use the `doc_contains`
  helper to pin the documentation to it.
- **Public endpoints, and no prescribed tools.** Skills must rely on public OWID
  endpoints, and must document them as URLs rather than as commands. Naming a
  tool assumes something about the reader's environment that we have no business
  assuming: people reach this API from a shell, from Python, from R, from a
  notebook, on machines where `jq` was never installed. The repository's own
  tests may use whatever they like; the shipped skill may not. Do **not** add
  anything that requires OWID-internal infrastructure or credentials; this
  repository is public.
- **Keep responses out of context.** Instruct agents to narrow a request with
  `country=` and `time=` and read only the fields they need, rather than pulling
  a large payload into context. Do not tell them which tool to do that with.

## Adding a skill

Prefer extending `owid` with a reference over adding a sibling skill: two
skills with overlapping triggers steal each other's traffic. If a genuinely
separate skill is warranted:

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter. The `name` field **must** match the directory name.
2. **Register it** in the `skills` array of the `owid` plugin in `.claude-plugin/marketplace.json`. Without this it is not installable via the marketplace. `plugin.json` needs no edit — the Agent Plugins format discovers everything under `skills/`, and a `skills` declaration there is ignored for packages that have a root manifest.
3. Add `evals/skills/<skill-name>/` with at least a `contract.sh` and a `triggers.json`, and add `expected_skill` negatives to the sibling's `triggers.json` so misrouting is measured.

## Versioning

Plugins here are intentionally **versionless**: `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`, `plugin.json` and the plugin entries carry no `version` field, so every commit to `main` is a new release and update mechanisms pick it up automatically. Do not add version fields back — `version` is optional in the Agent Plugins schema, hosts that need one fall back to `1.0.0`, and `make validate` warning about the missing version is the convention working, not a defect to fix.

Listing in OpenAI's public Plugin Directory would change this — each submitted
version goes through review — so that is a separate decision from the packaging
here, which only enables repo and local installs.

## Testing

Run `make` for the full list. The two you need most:

- `make validate` — four checks with distinct jobs: spec conformance via
  `skills-ref`, the reference validator the [Agent Skills
  spec](https://agentskills.io/specification) recommends (agent-agnostic, so it
  covers Codex/Gemini/Cursor users too); the Claude marketplace manifest via
  `claude plugin validate`; `plugin.json` against the published Agent Plugins
  schema, which no CLI here looks at; that every skill is registered in
  `.claude-plugin/marketplace.json` and that no skill file references eval
  files, which none of the validators knows about; and that every relative link
  inside `skills/` resolves. Run the make target rather than any single CLI —
  none of them subsumes another.
- `make test` — the contract tests. These check that the OWID endpoints and
  response shapes the skill documents still match what the API returns, which
  is the way this skill is most likely to break. This is what CI runs.

For end-to-end testing, load the plugin directly in a live session:
`claude --debug --plugin-dir .`

For ChatGPT and Codex, `make install` registers this repo as a plugin source via
the Codex CLI, which the ChatGPT desktop app reads too. It resolves from GitHub
rather than from the working tree, and installs the branch you are on, so it
fails if that branch was never pushed; `BRANCH=<ref>` installs a different one.
It clears its own marketplace entry first, because `codex plugin marketplace
add` refuses to re-point an existing marketplace at a different source. `codex
plugin list` shows what resolved.

For live edits rather than a pushed branch, point a personal marketplace
(`~/.agents/plugins/marketplace.json`, whose paths are relative to `$HOME`) at a
worktree.

## Evals

Each skill has an `evals/skills/<skill-name>/` directory holding its test inputs; the
shared harness and the playbook live in [evals/README.md](evals/README.md). Two
rules, both enforced by `make validate`:

- **Commit inputs, not outputs.** Test cases and fixtures are source. Everything
  a run produces goes to `evals/results/`, which is gitignored.
- **Never reference eval files from a skill.** Skills that route to their own
  evals spend the user's context budget on test prose. This is the only path by
  which eval content could reach an agent's context, so it is a hard check
  rather than a convention, and it covers `references/` as well as `SKILL.md`.

When you change the skill's `description`, re-run its trigger eval
(`make triggers`).

When you change what the skill *teaches*, run its behaviour cases
(`make behaviour CASE=<name>`). These run the plugin against a real prompt and
again with no plugin at all, and report the difference. A case that scores the
same both ways is measuring nothing — see
[evals/README.md](evals/README.md#the-baseline-arm-is-the-whole-point) before
writing one, because that trap catches almost every first attempt.
