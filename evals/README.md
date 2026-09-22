# Evaluating the skills in this repo

Three layers, cheapest and most deterministic first. They answer different
questions, and only the third one needs a model in the loop grading output.

| Layer | Question | Model in the loop? | Cost | Where |
|---|---|---|---|---|
| 1. Contract tests | Do the endpoints and response shapes documented in the skill still match reality? | no | seconds | `evals/skills/<skill>/contract.sh` |
| 2. Trigger evals | Does the skill fire when it should and stay quiet when it shouldn't? | yes (routing only) | minutes | `evals/skills/<skill>/triggers.json` |
| 3. Behaviour evals | Is the output any good, and better than no skill at all? | yes (graders, and a baseline arm) | minutes, and real money | `evals/skills/<skill>/<case>/` |

Layer 1 catches the failure mode that will actually bite this repo: the skill
is thin documentation over live public OWID endpoints, so it rots when the API
changes, not when the prose gets worse. Layer 2 matters because the skill's
`description` is broad on purpose (one skill covers search, data and
embedding), so the question is whether it fires on OWID work and stays quiet on
near-misses that merely share vocabulary. Layer 3 is the expensive one; it
earns its keep for the tasks where the agent does real reasoning, such as
fact-checks.

## Layout

```
Makefile                                # entry points — what you actually run
evals/
├── README.md                           # you are here
├── lib/assert.sh                       # assertion helpers for contract tests
├── run-contract-tests.sh               # layer 1 runner
├── run-trigger-eval.py                 # layer 2 runner
├── results/                            # gitignored — every run writes here
└── skills/<skill>/                     # mirrors skills/, one directory per skill
    ├── contract.sh                     # layer 1
    ├── triggers.json                   # layer 2
    ├── evals.json                      # layer 3, hand-run legacy format
    ├── <case>/                         # layer 3, one directory per case
    │   ├── prompt.md                   # frontmatter: limits and tools; body: the prompt
    │   └── graders/<name>.md           # one grader per file
    └── fixtures/                       # input files a case needs

skills/<skill>/SKILL.md                 # the skill
skills/<skill>/references/*.md          # the reference files it tells the agent to read
```

Everything directly under `evals/` is harness; everything under `evals/skills/` is
per-skill input, named exactly as the skill it tests. The runners glob
`evals/skills/*/`, so they cannot mistake `lib/` or `results/` for a skill.

## Why evals live here and not inside the skill directory

`skills/<skill>/` contains only what ships to users, on purpose. A skill
directory is the unit of distribution, and it is copied **recursively** into
users' projects. The [`skills` CLI](https://github.com/vercel-labs/skills) that
the README recommends for Codex, Gemini CLI and Cursor excludes only
`metadata.json`, `.git`, `__pycache__` and `__pypackages__` — there is no ignore
file and no opt-out. So anything under `skills/<skill>/` lands in someone else's
repo.

That matters less for tokens than for confusion. Fixture CSVs are realistic by
design; once they sit in a user's `.agents/skills/`, a `find . -name '*.csv'` or a
project-wide grep returns them alongside the user's real data. Keeping evals in a
sibling top-level directory removes the possibility entirely rather than
mitigating it: the installer never sees them.

The same reasoning is why no skill file may reference an eval file — that is the
one remaining path by which this content could reach an agent's context, and
`make validate` enforces it for `SKILL.md` and everything under `references/`.

**The rule that keeps this from becoming clutter: commit inputs, never outputs.**
Test cases, assertions and fixtures are source. Run outputs, gradings,
benchmarks and transcripts go to `evals/results/`, which is gitignored. The
noisy 90% of an eval workflow is never checked in.

## Layer 1 — contract tests

```bash
make test                                      # all skills
make test SKILL=owid                           # one skill
```

Exits non-zero if any check fails, so it works as a CI gate; it runs on every PR
and nightly via `.github/workflows/contract-tests.yml`. Downloaded responses stay
in `evals/results/contract/<skill>/` so you can inspect a failure without
re-running.

Checks come in two flavours. Most assert that the API behaves as documented. A
few assert the reverse — that the skill still documents everything the API
returns. Two examples in `owid/contract.sh`: if OWID adds a new chart type, the
tab-mapping check fails because an agent reading `references/search-api.md`
would have no way to build a `?tab=` URL for it; and the valid `pageTypes` are
parsed out of the API's own 400 error and compared against the reference.

**A check that did not run must never look like a check that passed.** This bit
us three ways: jq's `all` is `true` for an empty array, so a per-type assertion
passes vacuously when the sample holds none of that type; a `[[ -s "$FILE" ]]`
guard falls through silently when an earlier request failed; and a gate that
returns early drops its dependent checks from the summary entirely. Each is now
reported with `skip` and a reason. When you add a check that depends on the
sample containing something, assert that it does, or `skip` loudly.

Writing a new check: `source "$EVALS_LIB/assert.sh"` and reach for a helper
rather than raw shell. The vocabulary exists so that a check reads as a claim
about the API instead of as plumbing — if you find yourself writing `bash -c`
with nested quoting, the helper is missing and worth adding.

| Helper | Use |
|---|---|
| `fetch <url> <out>` | GET, assert 200, save the body. Returns non-zero so you can guard |
| `http_status <name> <url> <code> [out]` | the url returns exactly this status; for endpoints that must reject bad input |
| `content_type <name> <url> <ere>` | the response's Content-Type matches; for images and archives whose body you don't need |
| `all_match <name> <file> <selector> <predicate>` | every selected element satisfies the predicate |
| `none_match <name> <file> <selector> <predicate>` | no selected element satisfies it |
| `jq_true` / `jq_eq` / `jq_type` / `has_keys` | single-value assertions on JSON |
| `csv_column <file> <col>` | print a column's values, by name, quote-aware |
| `csv_has_columns` / `csv_min_rows` | CSV preconditions |
| `csv_column_set` / `csv_column_range` / `csv_column_matches` | assertions on a column's values |
| `csv_header` | the header line starts with a literal prefix (case-sensitive on purpose) |
| `doc_contains <name> <file> <ere>` / `doc_table_covers <name> <file> <values>` | documentation-drift checks against `SKILL.md` or a file under `references/` (paths relative to the skill directory) |
| `skill_md_contains` / `skill_md_table_covers` | the same, on `SKILL.md` |
| `ok <name> <cmd...>` | last resort: the command exits 0 |
| `note` / `skip` / `section` / `finish` | output and control |

`all_match` and `none_match` take the selector and the predicate separately. That
keeps quoting sane, and it lets them insist the selector matched something before
judging the predicate — `[] | all` is `true` in jq, so a fused filter silently
passes when the sample contains none of the thing being described.

CSV columns are addressed **by name**, resolved case-insensitively, because
`useColumnShortNames=true` lowercases the first three headers: an index-based or
case-sensitive check only works against one of the two documented forms. The
splitter is quote-aware, which matters for entities like
`"Bonaire, Sint Eustatius and Saba"` — `cut -d,` returns the wrong field there.

Guard dependent checks on `fetch` succeeding, so one dead endpoint doesn't
cascade into a wall of failures:

```bash
if fetch "$API?q=energy" "$WORK/search.json"; then
    jq_true "a common query returns hits" "$WORK/search.json" '.nbHits > 0'
fi
```

Pin every documented claim to the API with a drift check next to the behaviour
check, so the two cannot diverge unnoticed:

```bash
jq_eq "the relaxed response is flagged with closestMatches" "$EMPTY" '.closestMatches' true
skill_md_contains "SKILL.md mentions the closestMatches fallback" 'closestMatches'
```

Run `make lint` before committing: shellcheck for the shell, ruff for the Python.

## Layer 2 — trigger evals

```bash
make triggers                                                # every skill
make triggers RUNS=1                                         # cheapest useful loop
make triggers MODEL=claude-sonnet-5 EFFORT=medium            # override the defaults
./evals/run-trigger-eval.py --skill owid --dry-run           # print the plan only
./evals/run-trigger-eval.py --all --max-budget-usd 0.05      # hard per-run spend cap
```

**This layer is the expensive one, so size it deliberately.** Cost is
`queries x RUNS x skills` full `claude -p` sessions — the default `make triggers`
is 10 x 3 = 30 of them, each carrying a full system prompt, and a query that
fires nothing lets the model answer it in full before exiting.

| Knob | Default | Effect |
|---|---|---|
| `SKILL=<name>` | all | only that skill's queries |
| `RUNS=<n>` | 3 | 3 runs stabilises a fire rate; 1 is enough while iterating on wording |
| `EFFORT=<level>` | your session's effort | see the caveat in the FAQ: low effort suppresses tool calls, and so skill triggering |
| `MODEL=<id>` | your session model | see the caveat below |
| `--max-budget-usd` | unset | hard per-run cap; a cut-off run is reported as an error, not as a negative |

Routing is model-dependent, so a cheaper `MODEL` measures that model's routing,
not the one your users get. Use it to iterate on description wording quickly, then
re-measure on the model you actually ship before recording a result.

**Exit status is not a verdict on accuracy.** This is a measurement, not a gate:
the runner exits non-zero only when runs failed (the numbers are untrustworthy),
or when you opt into a floor with `--min-accuracy`.

Each query runs through `claude -p` with this repo loaded via `--plugin-dir`, the
same situation a real user is in. The runner records *which* skill fired, which
makes these outcomes possible:

| Outcome | Meaning |
|---|---|
| `correct` | the expected skill fired (or, for a negative, nothing did) |
| `miss` | no skill fired but one should have |
| `misroute` | a different skill fired than the one expected |
| `false_positive` | the skill under test fired when it should not have |
| `error` | the run never produced a routing decision, so it says nothing either way |

`error` exists because "no skill fired" and "the run never happened" look
identical from the outside. Conflating them is dangerous: an unauthenticated CLI
would score every negative case as `correct` and report respectable accuracy on
nothing at all. Only runs that observed a decision or exited cleanly are allowed
to vote, failed runs are reported with their cause, and any failed run makes the
whole invocation exit non-zero.

`triggers.json` is a list of `{query, should_trigger}` objects, compatible with
the eval-set format that `anthropics/skills`' `skill-creator` uses. Two
extensions: an optional `note` for human context, and an optional
`expected_skill` naming a sibling that *should* win instead. With one skill in
the repo `misroute` and `expected_skill` are dormant, but the runner keeps them
so that a second skill, if one is ever added, is measured against the first
from day one.

The set currently holds 9 queries: 5 positives spanning the skill's use cases
(discovery, fetch by URL, fact-check, article search, explaining a chart) and
4 near-misses. The negatives that earn their keep are
the near-misses — a query that shares vocabulary with the skill but needs
something else: an OWID codebase bug, a chart of non-OWID data, a translation
about an OWID topic, Python tooling. `"write a fibonacci function"` tests
nothing.

Only the `Skill` tool is permitted during a run, and the run is killed the
moment a skill fires: we are measuring the routing decision, not letting the
skill make requests for real.

## Layer 3 — behaviour evals

```bash
make behaviour                                 # every case
make behaviour CASE=finds-a-map-link           # one case
make behaviour CASE=finds-a-map-link RUNS=1    # cheapest useful loop
make behaviour CASE=extract-claims JUDGE=sonnet  # stronger judge for an llm grader
make behaviour MODEL=claude-sonnet-5           # the model under test
```

This layer runs on [`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals),
which sends a realistic prompt to a fresh headless session with this plugin
loaded, runs each case three times, then repeats the whole thing **with no
plugin at all** and reports the difference. That second arm is the reason to use
it: it answers "did the skill do this, or would Claude have managed anyway",
which is the question a skill repo has to keep asking itself.

It needs Claude Code ≥ 2.1.269. Every run is a real model call on your account.

### What a case looks like

A case is a directory anywhere under `evals/`; we put them in
`evals/skills/<skill>/<case>/` so they sit with that skill's other eval inputs.
`prompt.md` holds the prompt in its body and the run's limits in frontmatter,
and every file under `graders/` is one pass/fail check. The example case is
[`skills/owid/finds-a-map-link/`](skills/owid/finds-a-map-link/):

```markdown
---
description: >-
  A chart the model cannot name from memory, asked for as a map.
tags: [behaviour]
allowed_tools: [WebFetch, Skill]
---

For a slide on ocean plastic I want Our World in Data's chart of mismanaged
plastic waste per person, shown as a world map rather than as a line chart.
What's the link?
```

Write the prompt the way a user would type it. Naming the skill in the prompt
turns a routing measurement into an instruction-following one.

### Graders

One grader per file under `graders/`; the filename is the grader's name. The
type goes in frontmatter, and for `llm` the body is the rubric.

| Type | Passes when | Costs |
|---|---|---|
| `regex` | `pattern` matches the target (default: the final reply) | free |
| `tool_used` | `tool` was called between `min` and `max` times, optionally matching `input_match` | free |
| `tool_order` | the first `before` call precedes the first `after` call | free |
| `file_exists` | a file Claude **created** matches the `path` glob | free |
| `llm` | a judge model votes PASS on the body's rubric, 2 of 3 votes | a judge call |
| `baseline` | a judge finds the run at least as good as a reference transcript | a judge call |

Prefer the free four. These skills produce URLs, CSV columns and command lines —
things a regex pins down exactly and a small judge model can talk itself out of.
Keep `llm` for short prose where correctness is genuinely a judgement call, and
reach for `--judge-model sonnet` before trusting a rubric that keeps flipping.

Give each case **one grader on the answer and one on how Claude got there**.
The answer grader catches a regression in what the skill teaches; the path
grader is usually where the plugin's contribution actually shows up.

### The baseline arm is the whole point

A `tool_used: Skill` grader can never pass without the plugin, so it is excluded
from scoring in both arms and reported as an indicator only. Everything else is
scored in both, and the gap between them, `Δ`, is what the plugin contributed.

**A case that scores 1.00 with the plugin and 1.00 without it measures nothing.**
The example case is exactly that, on purpose — it is here to show the shape of a
case, and its own result is the more useful lesson:

| | with | without | Δ |
|---|---|---|---|
| `finds-a-map-link` | 1.00 | 1.00 | **0.00** |

Its transcript says why. Asked for the chart of *mismanaged plastic waste per
person*, baseline Claude with no plugin at all went straight to
`ourworldindata.org/grapher/mismanaged-plastic-waste-per-capita` and used its one
granted tool only to check the page was not a 404. It never searched. The prompt
had handed it the slug: OWID's slugs track its chart titles, so any phrasing
natural enough to be realistic is close to a transliteration of the answer.

An earlier version did report Δ +0.33, bought by a fourth grader that checked
whether Claude called the documented `/api/search` endpoint. That grader was
dropped, because grading the *route* rather than the result answers the wrong
question: if the reply is right, how Claude got there is not the user's problem.
Remove it and the case honestly reports that this skill changed nothing here.

So when a case shows Δ ≈ 0, the question is never "how do I get the number up".
It is whether the skill earns its place on that task. For chart discovery the
answer may be that a frontier model has memorised much of OWID's slug namespace,
and the skill's real value — currency, and not inventing a slug that looks right
— is not what a pass/fail grader on one prompt can see. Fact-checks and data
questions, where the agent does real reasoning and the traps the skill documents
bite, are the better places to spend runs.

### Cost and grants

Six runs of the example case cost about \$0.80 and take two minutes (about a
minute with `-j 4`). Cost scales
as cases × runs × 2 arms, so pin `CASE` and `RUNS=1` while iterating on graders
and use the defaults only for a number you intend to record.

`make behaviour` grants exactly `WebFetch(domain:ourworldindata.org)`. That grant
is deliberate in both directions: the cases need it, and the no-plugin arm gets
it too, so a positive Δ is the skill's doing rather than the tool grant's.

Granting `Bash` instead would let the agent fetch the URLs the way a shell user
would, with `curl`, but it puts every command under Claude Code's OS sandbox,
whose preconditions are machine-dependent. On a Mac with Docker Desktop
installed it refuses outright, because `~/.docker` contains symlinks it cannot
reliably exclude, and the case fails with a run error rather than a score. If
you want a Bash-granting case, expect to debug the sandbox first.

### Gotchas

- **The plugin must resolve.** `claude plugin eval` reports which plugin it
  loaded; if it says `none resolved`, the cases run against plain Claude Code and
  every Δ is meaningless. `.claude-plugin/plugin.json` is what makes it resolve
  as `owid`, which is also why that file has to exist even though
  `marketplace.json` already describes the same plugin.
- **`claude plugin validate` warns that the plugin has no version.** That is the
  repo's versionless convention, not an oversight. Don't silence it by adding
  one.
- **Runs cannot see the eval directory**, so a case cannot accidentally leak its
  graders to the agent under test.
- **`file_exists` only sees files created during the run**, not ones edited.
- Results land in `evals/results/<timestamp>/`, gitignored like everything else a
  run produces. `report.html` there shows each grader's verdict per run.

### The older `evals.json`

`evals.json` predates this layer and holds hand-run cases in the format at
<https://agentskills.io/skill-creation/evaluating-skills>. It is still the record
of what each skill was meant to be good at; port a case into the directory
format when you next touch it.

## Iterating

1. Run the layers. Layer 1 tells you whether the docs are still true; layer 2
   whether the description routes correctly; layer 3 whether the skill changes
   what Claude does.
2. Read the failures alongside the current `SKILL.md` and references.
3. Change one thing. Prefer explaining *why* over adding a rule — models follow
   reasoning more reliably than directives.
4. Re-run. Keep the change only if a target measure improves and nothing else
   regresses.

Adopt a skill change when: contract tests pass; trigger accuracy does not drop;
no behaviour-eval grader that previously passed now fails, and no case's Δ
shrinks; and no eval file ended up referenced from the skill.

## Caveats

- The exact way `claude -p` reports skill invocations is not a stable contract.
  `run-trigger-eval.py` parses `tool_use` blocks with a raw substring fallback;
  if results look implausible, run `--dry-run`, execute the printed command by
  hand, and check the `stream-json` against `skills_in_line()`.
- Layer 1 hits the live public API, so a network outage looks like a failure.
  That is deliberate — a red nightly run because OWID is down is information.
- Layer 2 costs real tokens: 9 queries × 3 runs is 27 `claude -p` invocations.
  Run it when the description changes, not on every PR.
- Layers 2 and 3 overlap. A `tool_used: Skill` grader asks the same question as
  a trigger eval, on one prompt instead of ten, and `claude plugin eval` is
  first-party where `run-trigger-eval.py` is ours to maintain. Whether layer 2
  should fold into layer 3 is worth deciding once there are enough behaviour
  cases to judge it on; until then the two measure at different widths.
