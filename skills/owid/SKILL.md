---
name: "owid"
description: "Agent skills for working with Our World in Data: search published charts, explorers and articles, fetch the data and metadata behind them, embed charts, and cite the original sources. Use whenever a task mentions Our World in Data, OWID, ourworldindata.org or a grapher URL, or asks for cross-country data on global problems (population, health and causes of death, energy, CO2 and climate, poverty and GDP, education, democracy, war, food, and more): finding a chart or article, fetching or plotting the data behind a chart, fact-checking a claim or answering a factual question against OWID data, embedding a chart or its PNG in HTML, slides or an artifact, or explaining what a chart shows and where its data comes from. No API key."
---

Our World in Data (OWID) publishes thousands of interactive charts and hundreds
of articles on global problems. Everything is free to reuse under CC BY and
reachable through two public HTTP endpoints, with no API key:

| You need | Endpoint | Read first |
|---|---|---|
| To find charts, explorers or articles | `https://ourworldindata.org/api/search` | [references/search-api.md](references/search-api.md) |
| The data, metadata or image behind a chart, and how to read it | `https://ourworldindata.org/grapher/<slug>.{csv,metadata.json,png,...}` | [references/data-api.md](references/data-api.md) |
| To show a chart inside HTML, slides or an artifact | | [references/embedding.md](references/embedding.md) |

This file holds the workflow and the rules. Read the relevant reference before
making a kind of call you have not made yet in this session; each one lists
every parameter, the response shape, and what fails silently.

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
   want the filtered view or everything. Keep the response out of your context
   and process it however you normally process data.
4. **Do the task** (analyse, plot, fact-check, join, embed). Use the CSV for
   numbers, never values read off an image.
5. **Cite.** Tell the user where the numbers came from at least once in the
   session, even when they did not ask. Use `columns.*.citationShort`: it is one
   line of prose that names the original producer first, which is the part that
   matters. "Our World in Data" alone is not a citation, because OWID
   republishes data collected by others. Add a link to the chart.
   Where a caveat from `descriptionKey` bears on the user's question, say so.

## Rules

- **Identify yourself.** Send this header on every request; it is how OWID can
  see that the skill is being used and keep the endpoints supported:
  `-A "owid-skills/1.0 (+https://github.com/owid/skills)"`.
- **Never invent a slug.** Confirm a chart exists through search or a 200
  response before building on it.
- **Keep responses out of context.** Search hits are large (`availableEntities`
  lists every country) and CSVs can run to hundreds of thousands of rows. Narrow
  the request with `country=` and `time=`, and pull out only the fields you need.
- **Preserve user-facing details.** Responses are UTF-8. The citation lines in
  the metadata contain en dashes and curly quotes: pass them through unchanged.
  Entity names in the CSV have no accents (`Cote d'Ivoire`), so do not try to
  match against the accented spelling.
- **Only public endpoints.** Everything here works without credentials. If a
  request needs a login, you are on the wrong URL.

## Quick reference

Send `User-Agent: owid-skills/1.0 (+https://github.com/owid/skills)` on every
request. Fetch these however suits the project you are in.

```
# Charts (also explorer and multi-dim views), top 5 by relevance
https://ourworldindata.org/api/search?q=child+mortality&hitsPerPage=5

# Articles and data insights
https://ourworldindata.org/api/search?q=malaria&type=pages&pageTypes=article,data-insight&hitsPerPage=5

# Metadata first, then the data, for two countries since 2000
https://ourworldindata.org/grapher/child-mortality.metadata.json
https://ourworldindata.org/grapher/child-mortality.csv?csvType=filtered&useColumnShortNames=true&country=KEN~IND&time=2000..2023

# A PNG of the same view, and a written description of the data's sources
https://ourworldindata.org/grapher/child-mortality.png?country=KEN~IND&time=2000..2023
https://ourworldindata.org/grapher/child-mortality.readme.md
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
- `Entity` holds names, `Code` holds ISO alpha-3 codes for countries. Regions and
  historical states use `OWID_`, `UN_` or `WB_` codes, and about a quarter of the
  entities in a big chart have no code at all. Join on `Code`, never on names, and
  check what you lost.

## Answering factual questions and fact-checking

Find the chart, fetch its metadata, then fetch the filtered CSV for exactly the
entity and time the claim concerns. Report the value with its unit and year, the
original source, and the chart link. If the claim's year, entity or definition
differs from what OWID measures (deaths versus death rate, share versus count,
projections versus estimates), state the difference rather than forcing a match.
If the metadata `timespan` does not reach the year asked about, say the data
ends earlier instead of extrapolating.

