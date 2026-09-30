# Prompt library

Realistic, synthetic requests about global statistics: the questions people
bring to an AI assistant, a search box or a chart page where Our World in
Data could help. The library is tool-agnostic. It describes what people ask
and what would satisfy them, never what a particular tool should do, so the
same prompts can test this repo's skill, a WebMCP integration, site search, or
a model with no tools at all.

[`prompts.json`](prompts.json) is the library: one array, 106 prompts in
English.

## One entry

```json
{
  "id": "E4-040",
  "prompt": "which countries are losing the most trees right now? for a quiz round",
  "attachment": null,
  "need": "The countries with the largest recent annual net forest loss or deforestation (in hectares or as a rate), ranked, with the year.",
  "persona": {
    "id": "E",
    "name": "Educator / student"
  },
  "situation": {
    "id": "E4",
    "text": "A teacher designing a classroom activity or quiz from real data."
  },
  "tags": {
    "intent": "compare-ranking",
    "freshness": "latest",
    "leak": "L3",
    "surface": "chat",
    "topic": "Forests & Deforestation",
    "geography": {
      "scope": "world"
    },
    "register": {
      "tone": "casual",
      "typo": false,
      "pasted_material": false,
      "length": "one line",
      "mentions_owid": false
    }
  },
  "provenance": {
    "kind": "synthetic",
    "generator": "claude-sonnet-5-5"
  }
}
```

- **`prompt`** is exactly what the person types. **`attachment`** is the
  table they refer to, when they bring their own data.
- **`need`** says in plain words what would satisfy them. It is the answer key
  a grader checks a response against.
- **`tags`** are the dimensions the prompt was generated from. Filter on them
  to pick the slice a tool should handle, for example:
  `jq '[.[] | select(.tags.surface == "chat" and .tags.intent != "join-own-data")]' prompts.json`.
- **`leak`** is how closely the wording names the metric. At `L0` the prompt
  uses the metric's official name. At `L1` it uses a lay synonym. At `L2` it
  describes the need. At `L3` the metric has to be inferred from context. Low
  levels are easy for any tool, because the words point straight at the
  chart. Higher levels test whether a tool understands the need.
- **Persona `X`** marks out-of-scope controls: requests that sound
  statistical, such as stock prices, city-level data or a personal budget,
  but that no country-level dataset answers. A tool should not answer them
  with OWID data.

What a given tool is expected to do with each prompt (which skill or tool
should fire, what counts as a pass) belongs with that tool's own evals, keyed
by `id`.

## How it is made

| Step | File | Kind |
|---|---|---|
| Persona cards and situations | `src/personas.yaml`, `src/situations.yaml` | hand-written |
| Tuples: each situation × leak level; intent, freshness and geography cycled per situation; topic, country and register sampled with a fixed seed | `src/grid.py` → `tuples.jsonl` | deterministic |
| Prompts written blind, with no access to OWID | `src/writer-brief.md` → `work/prompts-*.jsonl` | a model |
| Join into the library | `src/build.py` → `prompts.json` | deterministic |
| Reading page | `src/view.py` → `prompts.html` | deterministic |

Topics come from OWID's list of topic tags (`src/topics.json`). Countries
come from OWID's continent classification, limited to present-day countries
with more than a million people (`src/countries.csv`).

The prompts are written blind so they come from the person's need, not from
OWID's chart titles. A writer that can see the titles copies their wording,
and then any tool finds the chart. To regenerate, run `uv run -q src/grid.py`.
Split `tuples.jsonl` into batches, give each batch and `src/writer-brief.md`
to a model with no web access, save its output as `work/prompts-NN.jsonl`,
then run `uv run -q src/build.py`. `tuples.jsonl`, `work/` and `prompts.html`
are regenerated, not committed.
