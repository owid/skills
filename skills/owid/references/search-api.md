# Search API

`GET https://ourworldindata.org/api/search` is the same Algolia-backed search
that powers the search box on ourworldindata.org. It covers **charts**
(including individual explorer views and multi-dimensional chart views) and
**pages** (articles, data insights, topic pages, and a few other page types).
No authentication. Responses are JSON. Full reference:
<https://docs.owid.io/projects/etl/api/search-api/>.

Always send `-A "owid-skills/1.0 (+https://github.com/owid/skills)"`.

## Parameters

| Parameter | Applies to | Values | Default | Notes |
|---|---|---|---|---|
| `q` | both | free text | `""` | Keyword search. An empty query returns a popularity-ordered browse list. |
| `type` | both | `charts`, `pages` | `charts` | Anything else is a 400. Note: `resultType` is **not** a parameter here and is silently ignored. |
| `page` | both | 0..1000 | `0` | 0-indexed. |
| `hitsPerPage` | both | 1..100 | `20` | Over 100 is a 400. |
| `countries` | charts | entity names joined with `~` | | Prefer charts that have data for these countries, e.g. `countries=Kenya~Chad`. Names, not ISO codes. |
| `requireAllCountries` | charts | `true`, `false` | `false` | With `countries`, keep only charts that have data for **all** of them. |
| `topics` | charts | one topic name | | Restrict to a topic tag, e.g. `topics=Malaria`. Tag names are listed at <https://datasette-public.owid.io/owid/tags?slug__notnull=1>. |
| `pageTypes` | pages | comma-separated list | `article,about-page` | Valid: `article`, `data-insight`, `topic-page`, `linear-topic-page`, `about-page`, `author`, `announcement`, `profile`, `fragment`, `homepage`, `featured-viz`. An unknown value is a 400 whose message lists the valid ones. |

Encode spaces as `+` or `%20`. The `~` in `countries` can be sent literally.

## Chart search response (`type=charts`)

```typescript
type GrapherTabName =
  | "LineChart" | "ScatterPlot" | "StackedArea" | "DiscreteBar" | "StackedDiscreteBar"
  | "SlopeChart" | "StackedBar" | "Marimekko" | "Dumbbell" | "Table" | "WorldMap"

interface BaseChartHit {
  type: "chart" | "explorerView" | "multiDimView"
  title: string
  slug: string
  url: string                        // absolute; for explorer and multi-dim views it already includes the query string that selects this view
  subtitle?: string
  variantName?: string               // e.g. "World Bank, constant international-$"
  availableEntities: string[]        // every country/region the chart has data for; long
  originalAvailableEntities?: string[]
  availableTabs: GrapherTabName[]    // which views the chart supports
  publishedAt: string                // ISO 8601
  updatedAt: string                  // ISO 8601
}

// explorerView and multiDimView hits additionally carry:
interface ViewHitExtras {
  queryParams: string                // the query string that selects this view
  containerTitle: string             // the explorer / multi-dim chart it belongs to
}

interface ChartSearchResponse {
  query: string
  results: BaseChartHit[]
  nbHits: number
  page: number
  nbPages: number
  hitsPerPage: number
  closestMatches?: boolean           // true when nothing matched exactly and these are relaxed matches
}
```

## Page search response (`type=pages`)

```typescript
interface PageHit {
  type: "article" | "data-insight" | "topic-page" | "linear-topic-page" | "about-page"
      | "author" | "announcement" | "profile" | "fragment" | "homepage" | "featured-viz"
  title: string
  slug: string
  url: string                        // absolute
  content?: string                   // excerpt of the body text; a few hundred words
  authors?: string[]
  date?: string                      // publication date, ISO 8601
  modifiedDate?: string              // ISO 8601
  thumbnailUrl?: string
}

interface PageSearchResponse {
  query: string
  results: PageHit[]
  nbHits: number
  offset: number                     // note: pages use offset/length, not page/nbPages
  length: number
  closestMatches?: boolean
}
```

## Recipes

```bash
UA="owid-skills/1.0 (+https://github.com/owid/skills)"
S="https://ourworldindata.org/api/search"

# Top 5 charts: title, subtitle, url and the views each supports
curl -sA "$UA" "$S?q=life+expectancy&hitsPerPage=5" \
  | jq '.results[] | {title, subtitle, url, availableTabs}'

# Only charts with data for two given countries
curl -sA "$UA" "$S?q=electricity+access&countries=Nigeria~Ghana&requireAllCountries=true&hitsPerPage=5" \
  | jq -r '.results[] | "\(.title) — \(.url)"'

# Articles and data insights on a topic, newest first
curl -sA "$UA" "$S?q=malaria&type=pages&pageTypes=article,data-insight&hitsPerPage=20" \
  | jq -r '.results | sort_by(.date) | reverse | .[] | "\(.date[:10])  \(.type)  \(.title)  \(.url)"'

# Recent writing by one author (author names are indexed as text)
curl -sA "$UA" "$S?q=Hannah+Ritchie&type=pages&hitsPerPage=50" \
  | jq -r '.results[] | select(.authors // [] | index("Hannah Ritchie")) | "\(.date[:10])  \(.title)  \(.url)"'

# The topic page for a subject
curl -sA "$UA" "$S?q=malaria&type=pages&pageTypes=topic-page,linear-topic-page&hitsPerPage=3" \
  | jq -r '.results[] | "\(.title) — \(.url)"'

# The list of topic names accepted by `topics=`
curl -sA "$UA" 'https://datasette-public.owid.io/owid/tags.json?slug__notnull=1&_size=max&_shape=array' \
  | jq -r '.[].name' | sort
```

## Given the URL of an article

There is no per-article JSON endpoint. To get an article's title, authors,
date and an excerpt, search for it: `q=<words from the slug or title>&type=pages`
and match on `.url` (drop the `pageTypes` default if it might be a data insight
or topic page). For the full text, fetch the HTML page itself. Articles embed
charts as `/grapher/<slug>` links, which you can then treat as charts.

## Search tips

- **Vocabulary.** OWID follows the terminology of the field: "death rate from
  malaria" not "people who died from malaria", "literacy" not "people who can
  read", "GDP per capita" not "average income".
- **Relevance, not recall.** Results come ordered by relevance and the first
  page usually contains the right chart. If the top hits are off, add a term or
  swap a synonym; do not page deep.
- **There is no empty result.** With no real match the API relaxes the query
  and returns loosely related hits with `closestMatches: true`, as a single
  page whose `nbHits` is just the number returned. Treat a nonsense query as
  "nothing found" by looking at the titles, never at `nbHits`.
- **Tell the user what you found.** When several charts fit, name the top few
  titles and subtitles and either pick one with a stated reason or ask.
- **Explorer and multi-dim views are first-class hits.** Their `url` already
  encodes the view; use it verbatim for the data endpoints. `containerTitle`
  tells you which explorer they belong to, which helps when several views of
  one explorer show up.

## Building a chart URL for a specific view

`availableTabs` says which views a chart supports. Append `?tab=<value>` using
this mapping (a value not in the table is not embeddable that way):

| Tab name in `availableTabs` | `tab=` value | View |
|---|---|---|
| `LineChart` | `line` | Time-series line chart |
| `WorldMap` | `map` | Choropleth world map |
| `Table` | `table` | Data table |
| `DiscreteBar` | `discrete-bar` | Bar chart for one point in time |
| `SlopeChart` | `slope` | Slope chart between two points in time |
| `Marimekko` | `marimekko` | Marimekko / mosaic chart |
| `ScatterPlot` | `scatter` | Scatter plot |
| `StackedArea` | `stacked-area` | Stacked area chart |
| `StackedBar` | `stacked-bar` | Stacked bar chart |
| `StackedDiscreteBar` | `stacked-discrete-bar` | Stacked bar chart for one point in time |
| `Dumbbell` | `dumbbell` | Dumbbell chart comparing two values per entity |

Other view parameters (`country=USA~GBR`, `time=2000..2020`, `time=2015`) can be
appended too and are honoured by the data, image and embed endpoints alike; see
[data-api.md](data-api.md).
