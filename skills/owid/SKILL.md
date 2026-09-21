---
name: "owid"
description: "Work with Our World in Data (OWID) content: search its published charts, explorers and articles, download the data and metadata behind any chart, and cite it correctly. Use whenever a task mentions Our World in Data, OWID, ourworldindata.org or a grapher URL, or asks for cross-country data on global problems (population, health and causes of death, energy, CO2 and climate, poverty and GDP, education, democracy, war, food, and more): finding a chart or article, fetching or plotting the data behind a chart, fact-checking a claim or answering a factual question against OWID data, computing per-capita figures or joining OWID data with your own, embedding a chart or its PNG in HTML, slides or an artifact, or explaining what a chart shows and where its data comes from. Needs only curl and jq; no API key."
allowed-tools:
- "Bash(curl:*)"
- "Bash(jq:*)"
- "Bash(cat:*)"
- "Read"
---

Our World in Data (OWID) publishes thousands of interactive charts and hundreds
of articles on global problems. Everything is free to reuse under CC BY and
reachable through two public HTTP endpoints, with no API key:

| You need | Endpoint | Read first |
|---|---|---|
| To find charts, explorers or articles | `https://ourworldindata.org/api/search` | [references/search-api.md](references/search-api.md) |
| The data, metadata or image behind a chart | `https://ourworldindata.org/grapher/<slug>.{csv,metadata.json,png,...}` | [references/chart-data-api.md](references/chart-data-api.md) |
| To interpret columns, entities and years, or join with other data | | [references/data-format.md](references/data-format.md) |
| To show a chart inside HTML, slides or an artifact | | [references/embedding.md](references/embedding.md) |

This file holds the workflow and the rules. Read the relevant reference before
making a kind of call you have not made yet in this session; each one lists
every parameter, the response shape, and the traps.

## Workflow

1. **Identify the content.**
   - If the user gave a URL, use it verbatim, including its query string. On
     explorers and multi-dimensional charts the query parameters *are* the
     chart: dropping them selects a different indicator.
   - Otherwise search. Charts: `/api/search?q=...`. Articles, data insights and
     topic pages: add `type=pages`. OWID uses specialist vocabulary, so search
     for "child mortality" rather than "kids dying". Tell the user the top few
     titles and either pick the best match or ask which one they mean.
2. **Fetch the metadata first, always**, even when the user only asked for
   data: `<chart-url>.metadata.json`. It tells you what each column measures,
   in which unit, from which source, and which caveats OWID's editors flagged
   (`descriptionKey`). Skim `chart.title`, `chart.subtitle`, `chart.note` and,
   per column, `unit`, `descriptionShort`, `descriptionKey`,
   `descriptionProcessing`, `timespan`, `citationShort`.
3. **Fetch the data**: `<chart-url>.csv?csvType=filtered&useColumnShortNames=true`
   plus `country=` and `time=` filters. If the URL carried no filters, download
   the full data (`csvType=full`); if it did, decide with the user whether they
   want the filtered view or everything. Save the response to a file and
   process it with `jq`, `awk` or a script rather than reading it into context.
4. **Do the task** (analyse, plot, fact-check, join, embed). Use the CSV for
   numbers, never values read off an image.
5. **Cite.** Every output that uses OWID numbers names the *original* data
   producer, taken from `columns.*.citationShort`, plus a link to the chart.
   "Our World in Data" alone is not a sufficient citation: OWID processes and
   republishes data collected by others, and the producer must be credited.
   Where a caveat from `descriptionKey` bears on the user's question, say so.

## Rules

- **Identify yourself.** Send this header on every request; it is how OWID can
  see that the skill is being used and keep the endpoints supported:
  `-A "owid-skills/1.0 (+https://github.com/owid/skills)"`.
- **Never invent a slug.** Confirm a chart exists through search or a 200
  response before building on it.
- **Keep responses out of context.** Search hits are large (`availableEntities`
  lists every country) and CSVs can run to hundreds of thousands of rows. Save
  to a file, then extract with `jq` or filter with `country=` and `time=`.
- **Preserve user-facing details.** Data is UTF-8 (`Côte d'Ivoire`, `Curaçao`);
  keep it that way. `conversionFactor` in the metadata is already applied to the
  CSV values; do not apply it again.
- **Only public endpoints.** Everything here works without credentials. If a
  request needs a login, you are on the wrong URL.

## Quick reference

```bash
UA="owid-skills/1.0 (+https://github.com/owid/skills)"
S="https://ourworldindata.org/api/search"
G="https://ourworldindata.org/grapher"

# Charts (also explorer and multi-dim views), top 5 by relevance
curl -sA "$UA" "$S?q=child+mortality&hitsPerPage=5" \
  | jq -r '.results[] | "\(.title) — \(.url)"'

# Articles and data insights
curl -sA "$UA" "$S?q=malaria&type=pages&pageTypes=article,data-insight&hitsPerPage=5" \
  | jq -r '.results[] | "\(.date[:10]) \(.type): \(.title) — \(.url)"'

# Metadata, then data, for two countries since 2000
curl -sA "$UA" -o meta.json "$G/child-mortality.metadata.json?country=KEN~IND&time=2000..2023"
jq '{title: .chart.title, columns: (.columns | map_values({unit, descriptionShort, citationShort}))}' meta.json
curl -sA "$UA" -o data.csv "$G/child-mortality.csv?csvType=filtered&useColumnShortNames=true&country=KEN~IND&time=2000..2023"

# A PNG of the same view, and a human-readable description of the data's sources
curl -sA "$UA" -o chart.png "$G/child-mortality.png?country=KEN~IND&time=2000..2023"
curl -sA "$UA" "$G/child-mortality.readme.md"
```

## Traps

- `csvType=filtered` applies the **chart's own default selection** when you
  pass no `country=`, which for many charts is a handful of regions rather than
  all countries. For every entity use `csvType=full`, or name the countries.
- On charts whose default view is a **map**, `country=` is ignored unless you
  also pass `tab=chart` (a map shows every country, so the filter has nothing
  to act on).
- The search **never returns zero hits**: with no real match it falls back to
  loosely related charts and sets `closestMatches: true`. Judge the titles, not
  `nbHits`.
- `hitsPerPage` is capped at 100. Page search defaults to
  `pageTypes=article,about-page`, so data insights and topic pages need an
  explicit `pageTypes=`.
- The `Entity` column holds names and `Code` holds ISO alpha-3 codes; regions
  and historical countries have `OWID_` codes. Join on `Code`, never on names.

## Answering factual questions and fact-checking

Find the chart, fetch its metadata, then fetch the filtered CSV for exactly the
entity and time the claim concerns. Report the value with its unit and year, the
original source, and the chart link. If the claim's year, entity or definition
differs from what OWID measures (deaths versus death rate, share versus count,
projections versus estimates), state the difference rather than forcing a match.
If the metadata `timespan` does not reach the year asked about, say the data
ends earlier instead of extrapolating.

## Working in Python

The same URLs load directly: `pd.read_csv(f"{url}.csv?csvType=filtered&...")`
and `requests.get(f"{url}.metadata.json").json()`, with the User-Agent header
set. For richer needs (indicator-level metadata, dimensions that published
charts flatten away, semantic search across OWID's whole catalog) the
[owid-catalog](https://docs.owid.io/projects/etl/api/) Python library exists,
but nothing in this skill requires it.
