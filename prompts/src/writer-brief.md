# Brief: write what a real person would type

You are writing test prompts for a reusable library of realistic requests about
global statistics — the kind of questions Our World in Data (OWID) could help
with. The library will be used to test many different tools (AI assistants with
and without data tools, a site search box, future integrations), so the prompts
must read like **real people typing to an AI assistant**, not like test cases.

Each line of your batch file is a *tuple*: a persona, a situation, and sampled
attributes. For each tuple, invent one concrete person in that situation and
write the message they would actually send, in English.

**Work blind.** Do not browse, search, curl, or look anything up — no web, no
OWID site or API. The point is to write from the person's need, not from what
OWID happens to publish. It is fine (and useful) if some prompts ask for
something that doesn't exist.

## How to read the tuple

Persona cards are in `src/personas.yaml`, situations in `src/situations.yaml`.
Read both first.

- `topic` and `geography` — the subject and place. Make the request specific to
  them (a concrete metric within the topic, the named countries or region), but
  in the person's words. If the topic is an awkward fit for the situation,
  pick the most natural angle on it that such a person would plausibly have.
- `intent` — what they want back (a chart, a number, a comparison, data,
  code/analysis, a join with their own data, a citation or caveat). Nothing
  about *how* a tool should do it.
- `freshness` — `fixed-year` names a year; `latest` wants the most recent
  figure; `over-time` wants a trend; `false-premise` rests on a plausible but
  wrong belief (e.g. assumes something rose when it fell). Write the premise
  as the person believes it — don't signal that it's wrong.
- `leak` — how closely the wording names the exact metric:
  - `L0`: names the metric precisely, as a statistician or the official source
    would ("under-five mortality rate per 1,000 live births").
  - `L1`: a synonym or lay paraphrase ("how many little kids die").
  - `L2`: describes the need; the metric is left implicit ("is it safer to be
    born in X now?").
  - `L3`: the metric has to be inferred from context — their data, their
    task, their audience ("our clinic numbers look bad next to the region,
    is that just because the country's poorer?").
  Never use a chart-title-like phrase above L0.
- `surface` — `chat` is a chat app (claude.ai, ChatGPT); `agent` is a coding
  or file-working assistant, so the person may mention files, scripts, a
  notebook, a repo, pandas/R.
- `register` — apply every attribute:
  - `tone`: casual (lowercase, fragments, no greeting is fine) or formal.
  - `typo`: include one or two natural typos — prefer misspelling a country,
    place or metric word, since that's what trips real searches.
  - `pasted_material`: include something pasted — a sentence from a draft, an
    assignment text, a URL (a real-looking ourworldindata.org URL only if
    `mentions_owid` is true; otherwise another site's or none), a few lines of
    their table.
  - `length`: one line / a few sentences / long, with context.
  - `mentions_owid`: if true, the person names Our World in Data (or "owid",
    or pastes an OWID link) naturally; if false, no mention at all.

Out-of-scope controls (`persona: X`) have no topic or leak. Write a realistic
request for that situation that *sounds* statistical but should not be
answered with country-level public data. Make the two prompts per situation
differ.

## Three mistakes that reviewers catch

- **Using a sampled combination that no real person would pick.** The grid is
  random: it can pair a topic with a place where it doesn't happen (malaria in
  North America) or a table with an unrelated indicator. If a combination
  wouldn't occur to a real person, adjust it minimally — a neighbouring
  country, a closer angle on the topic — and keep the rest.
- **Announcing an attribute instead of showing it.** Don't narrate
  ("pasted my draft below:"), don't claim a paste that isn't there, don't
  explain away the metric to reach a leak level, and don't add a sentence just
  to mention OWID. Each attribute should be a natural trait of the text.
- **Losing the situation's core need.** The prompt has to carry what makes the
  situation distinct (two sources that disagree, a breakdown the headline
  figures lack, a dashboard that must stay updated, which figure needs the
  caveat). Spec-like phrasing ("I require…", "Not looking for X, just Y") is
  a tell.

## What real prompts look like (register, not content)

Real people state the problem and stop. They rarely say what output format
they want or why, they skip context the assistant would need, they paste
things. Most messages are short. Examples of real
register (from public chat logs):

- `which country has the highest proportion of obese people?`
- `please draw a chart comparing the confirmed positive COVID-19 cases, from January 2021 to 2023, for Europe Union, Hong Kong and China`
- `hey can u help me with my notebook that i uploaded on kaggle?`

Avoid the tells of generated text: tidy complete sentences, "I am a
journalist working on...", listing requirements as bullets, thanking in
advance, every prompt starting the same way. Vary openings across your batch.

## Output

Write one JSON object per tuple, in the same order, to the output path given
in your task, as JSONL:

```json
{"id": "<tuple id>",
 "prompt": "<exactly what the person types>",
 "need": "<one plain English sentence: what information would satisfy them, including metric, place, period>",
 "attachment": "<only for join-own-data or when the prompt refers to their file: a small CSV sample (header + 4-6 rows) of the table they have, with realistic messiness — otherwise null>"}
```

`need` is the answer key tools are graded against, so make it unambiguous even when
the prompt is vague. For false-premise prompts, state the premise in `need`
and that it should be checked. For controls, say what they need and why
country-level public statistics don't answer it.
