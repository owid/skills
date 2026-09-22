# Search API

`GET https://ourworldindata.org/api/search` is the same Algolia-backed search
that powers the search box on ourworldindata.org. It covers **charts**
(including individual explorer views and multi-dimensional chart views) and
**pages** (articles, data insights, topic pages, and a few other page types).
No authentication. Responses are JSON.

## How a request is built

Everything is a query string on that one URL. `type` chooses which of the two
searches you get, and the two return different shapes, so decide that first.

Send this header on every request:

```
User-Agent: owid-skills/1.0 (+https://github.com/owid/skills)
```

OWID phrases things the way the field does, so search its vocabulary rather than
the user's: "death rate from malaria" rather than "people who died from malaria",
"literacy" rather than "people who can read", "GDP per capita" rather than
"average income". Results come back by relevance and the right chart is almost
always on the first page; if the top hits are wrong, change a term rather than
paging deeper.

The endpoint's own specification, which is what it is built against, is
[search-api.openapi.yaml](https://github.com/owid/owid-grapher/blob/master/docs/search-api.openapi.yaml).

## Parameters

| Parameter | Applies to | Values | Default | Notes |
|---|---|---|---|---|
| `q` | both | free text | `""` | Keyword search. An empty query returns a popularity-ordered browse list. |
| `type` | both | `charts`, `pages` | `charts` | Anything else is a 400. Note: `resultType` is **not** a parameter here and is silently ignored. |
| `page` | both | 0..1000 | `0` | 0-indexed. |
| `hitsPerPage` | both | 1..100 | `20` | Over 100 is a 400. |
| `countries` | charts | entity names joined with `~` | | Prefer charts that have data for these countries, e.g. `countries=Kenya~Chad`. Names, not ISO codes. |
| `requireAllCountries` | charts | `true`, `false` | `false` | With `countries`, keep only charts that have data for **all** of them. |
| `topics` | charts | one topic name | | Restrict to a topic, e.g. `topics=Malaria`. One topic only: a comma or `~` separated list is a 400. An unknown topic is also a 400, and the error message lists every valid topic, which is the quickest way to get that list. |
| `pageTypes` | pages | comma-separated list | `article,about-page` | Valid: `article`, `data-insight`, `topic-page`, `linear-topic-page`, `about-page`, `author`, `announcement`, `profile`, `fragment`, `homepage`, `featured-viz`. An unknown value is a 400 whose message lists the valid ones. |

Encode spaces as `+` or `%20`. The `~` in `countries` can be sent literally.

## What a chart search returns

The envelope holds `query`, `results`, `nbHits`, `page`, `nbPages` and
`hitsPerPage`, plus `closestMatches` when the query had to be relaxed.

Each hit:

| Field | Holds |
|---|---|
| `type` | `chart`, `explorerView` or `multiDimView`. The last two are single views inside a larger thing, and they are ordinary hits you can use directly. |
| `title` | The chart's title. |
| `slug` | The chart's slug. |
| `url` | Absolute. On an explorer or multi-dim view it already carries the query string that selects that view, so use it as it is. |
| `subtitle` | The chart's subtitle. |
| `variantName` | Which version of an indicator this chart uses, e.g. `World Bank, constant international-$`. Absent on charts with only one version. |
| `availableEntities` | Every country and region the chart has data for. This is long — hundreds of strings per hit — and it is the reason a search response is large. |
| `availableTabs` | Which views the chart supports, as `LineChart`, `WorldMap`, `Table`, `DiscreteBar`, `SlopeChart`, `Marimekko`, `ScatterPlot`, `StackedArea`, `StackedBar`, `StackedDiscreteBar`, `Dumbbell`. See [Choosing a chart view](#choosing-a-chart-view). |
| `publishedAt`, `updatedAt` | ISO 8601 timestamps. |
| `queryParams` | The query string that selects this view. Only on `explorerView` and `multiDimView`. |
| `containerTitle` | The explorer or multi-dimensional chart the view belongs to. Only on `explorerView` and `multiDimView`, and worth showing the user when several views of one explorer come back together. |

## What a page search returns

A different envelope: `query`, `results`, `nbHits`, and then `offset` and
`length` where the chart search has `page` and `nbPages`. `closestMatches`
appears here too.

Each hit:

| Field | Holds |
|---|---|
| `type` | One of the `pageTypes` values: `article`, `data-insight`, `topic-page`, `linear-topic-page`, `about-page`, `author`, `announcement`, `profile`, `fragment`, `homepage`, `featured-viz`. |
| `title` | The page title. |
| `slug` | The page slug. |
| `url` | Absolute. |
| `content` | An excerpt of the body, a few hundred words. Not the full text; fetch the page itself for that. |
| `authors` | Names, as written on the page. |
| `date` | Publication date, ISO 8601. Results are not sorted by it, so sort them yourself if you want newest first. |
| `modifiedDate` | ISO 8601. |
| `thumbnailUrl` | The page's image. |

## Recipes

Top 5 charts. Each result has `title`, `subtitle`, `url` and `availableTabs`:

```
https://ourworldindata.org/api/search?q=life+expectancy&hitsPerPage=5
```

Only charts with data for two given countries:

```
https://ourworldindata.org/api/search?q=electricity+access&countries=Nigeria~Ghana&requireAllCountries=true&hitsPerPage=5
```

Articles and data insights on a topic. Sort the results by `date` yourself for
newest first:

```
https://ourworldindata.org/api/search?q=malaria&type=pages&pageTypes=article,data-insight&hitsPerPage=20
```

Recent writing by one author. Author names are indexed as text, so search for
the name and then keep the results whose `authors` array contains it:

```
https://ourworldindata.org/api/search?q=Hannah+Ritchie&type=pages&hitsPerPage=50
```

The topic page for a subject:

```
https://ourworldindata.org/api/search?q=malaria&type=pages&pageTypes=topic-page,linear-topic-page&hitsPerPage=3
```

The list of topic names accepted by `topics=`. Ask for one that does not exist
and the 400 lists every valid topic:

```
https://ourworldindata.org/api/search?topics=list-them-please
```

## Finding a page you already have

There is no per-article JSON endpoint. To get an article's title, authors,
date and an excerpt, search for it: `q=<words from the slug or title>&type=pages`
and match on `.url` (drop the `pageTypes` default if it might be a data insight
or topic page). For the full text, fetch the HTML page itself. Articles embed
charts as `/grapher/<slug>` links, which you can then treat as charts.

## Choosing a chart view

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

## Silent failures

- **A search can return nothing, and it can also quietly return something else.**
  A query that matches nothing comes back empty. A query where some of the words
  match something comes back with a few loosely related hits and
  `closestMatches: true`. So a non-empty response is not the same as a match:
  read `closestMatches`, and judge the titles rather than `nbHits`.
- **`resultType` is not a parameter.** It is accepted and ignored, so you get a
  chart search back while believing you asked for something else. The parameter
  is `type`.
- **Page search does not return data insights or topic pages by default.** It
  defaults to `pageTypes=article,about-page`, so a search for a data insight
  finds nothing until you ask for that type.

When several charts fit, tell the user the top few titles and subtitles, and
either pick one and say why, or ask which they meant.
