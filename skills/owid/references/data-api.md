# Data API

Every chart on Our World in Data has a URL. Add a suffix to that URL and you get
a file instead of a web page. Add parameters and you choose which part of the
data you get. No API key, no sign-up.

## How a request is built

One request, taken apart:

```
https://ourworldindata.org/grapher/life-expectancy.csv?csvType=filtered&country=USA~GBR&time=2000..2020
```

- **The slug** names the chart. `life-expectancy` and `life-expectancy-hmd-unwpp`
  are two different charts with two different sources. Never invent one: get it
  from a search result or from a URL the user gave you. Follow redirects — a
  renamed chart keeps its old slug working with a 301, and without following it
  you get an empty body rather than an error. `HEAD` is no way to test a slug
  either: it returns 404 for URLs that `GET` serves fine.
- **The suffix** says which file you want. Leave it off and you get the web page.
- **The view** says which part of the data you want: which countries, which
  years, and on some charts which indicator.

Explorer charts work the same way. They sit under `/explorers/` instead of
`/grapher/`, and they take the same suffixes.

If the user gave you a URL, keep its query string. On explorers and
multi-dimensional charts the query string chooses the indicator, so dropping it
gives you different numbers.

## Start with the metadata

Fetch `<chart-url>.metadata.json` before you do anything else, every time, even
when the user only asked for numbers. Read it into your context and keep it
there.

Treat it differently from the data. A CSV can be hundreds of thousands of rows,
so keep it out of your context and process it wherever you process data. The
metadata is a few kilobytes, and you cannot do the job well without it, so it
belongs in your context.

```
https://ourworldindata.org/grapher/life-expectancy.metadata.json
```

### The metadata fields

Three things at the top level: `chart`, describing the chart as a whole,
`columns`, one entry per indicator, and `dateDownloaded`. Multi-dimensional
charts add `activeFilters`, echoing the dimensions you asked for.

`columns` is keyed by the **indicator's own title**, which on most charts is not
the CSV header — the chart renames its columns for display. `life-expectancy`
has `Life expectancy` in the CSV and `Period life expectancy at birth` in the
metadata; `Age 10` in one chart is `Life expectancy - Sex: total - Age: 10 -
Type: period` in the other. **To line the two up, fetch the CSV with
`useColumnShortNames=true` and match on `columns.*.shortName`.** Where a chart
uses one indicator twice, the CSV adds a suffix the metadata does not have
(`__projected`, `__in_2016`, `__annotations`), so match on the prefix. Never
match on the long name, and never on column position.

| Field | Holds |
|---|---|
| `chart.title`, `chart.subtitle`, `chart.note` | The chart's own wording. Any of the three can be absent: `note` more often than not, and a few multi-dimensional charts have no `title`. Read them defensively. |
| `chart.citation` | The producers behind the whole chart. |
| `chart.selection` | The entities the chart highlights by default, by name. Often an empty list. It is **not** a prediction of what `csvType=filtered` returns: on map, scatter, Marimekko and bar views that gives you every entity the view draws, whatever the selection says. |
| `chart.originalChartUrl` | The chart this data came from. |
| `columns.*.titleShort`, `titleLong` | The column's name, short and long. |
| `columns.*.unit`, `shortUnit` | `"years"`, `"deaths per 100,000 people"`, `"%"`. Read this before you report any number. `shortUnit` is absent more often than present, and `unit` is occasionally an empty string. |
| `columns.*.descriptionShort` | A one-sentence definition of the indicator. |
| `columns.*.descriptionKey` | The caveats OWID editors wrote by hand, as **one string** of Markdown bullet lines — split it on newlines, it is not an array. **About half of all charts have none at all.** Missing means nobody has written them down, not that there are none; fall back to `.readme.md`. Repeat the ones that bear on the user's question. |
| `columns.*.descriptionProcessing` | Notes on OWID's processing step for this indicator. |
| `columns.*.timespan` | The years the **indicator** covers, as `start-end`, e.g. `1543-2023`. It is an upper bound, not a promise: a chart that sets its own start year returns a narrower CSV, and one chart claims `-10000-2023` while its CSV begins in 1950. The start can be negative, so parse it with a pattern rather than splitting on the dash. Empty on sub-annual charts. On a column that classifies rather than measures — region, income group — it gives that classification's vintage, not the rows it appears on. |
| `columns.*.type` | Almost always `Numeric` or `Integer`. Also `String`, `NumberOrString`, `Ordinal`, `Continent`, `SeriesAnnotation` and `Year`. Sometimes missing. |
| `columns.*.shortName` | The column name you get with `useColumnShortNames=true`, give or take a server-added suffix. |
| `columns.*.lastUpdated`, `nextUpdate` | Dates, `YYYY-MM-DD`. |
| `columns.*.citationShort`, `citationLong` | The source lines. See below. |
| `columns.*.fullMetadata` | A URL with the complete indicator metadata: every origin, licence and processing step. On a helper column it is built from a null id and 404s. |
| `columns.*.owidVariableId` | OWID's internal id for the indicator. |
| `activeFilters` | Present whenever you passed filters, on any chart: the `country`, `time` and dimensions actually applied. Compare it with what you asked for — it is the direct check that you got the view you wanted. |
| `dateDownloaded` | The day you fetched it. |

It is a few kilobytes for most charts. On one with many columns, read `chart`
and then, per column, `unit`, `timespan`, `descriptionShort`, `descriptionKey`
and `citationShort`.

### Citing the source

OWID almost never collects the data. It republishes work done by other people,
and those people need the credit to keep doing the work. So "Our World in Data"
on its own is not a citation. Name the producer.

**Say it out loud at least once per session.** Even in a chat where nobody asked
for a citation, tell the user where the numbers came from the first time you use
them. `citationShort` is written for exactly this: it is one line, it reads as
prose, and it names the producers before it names OWID.

Take it from a column that holds real values. A chart can carry helper columns —
`Year`, `…-annotations`, a region lookup — whose `citationShort` is just
`" – processed by Our World in Data"` with nothing before the dash. Citing that
credits nobody, which is the one outcome this section exists to prevent. The
wording of the middle varies too: "processed by", "with major processing by" and
"with minor processing by" are all normal.

```
Gapminder (2015); UN Inter-agency Group for Child Mortality Estimation (2025) – processed by Our World in Data
```

Use `citationLong` when you are writing something that will be read later, such
as a report, a document or a footnote: it names the producers, the dataset and
every original source behind it. Print it in full rather than trimming it.

Add a link to the chart as well, so the reader can get to the interactive
version and the full sources.

OWID's own work is open under [CC BY](https://creativecommons.org/licenses/by/4.0/):
you may use, change and republish it, as long as you credit the source and the
authors. The data itself stays under whatever terms its original producer set,
which is another reason the producer has to be named.

## Suffixes and parameters

The suffix decides which file comes back:

| Suffix | Returns |
|---|---|
| `.metadata.json` | Definitions, units, sources, caveats. Get this first, always. |
| `.csv` | The data. One row per entity and time point. |
| `.readme.md` | A written description of the data and where it came from. Long, but it answers "how was this made" in one request, and it names each source in prose: the producer, when it was published and retrieved, its URL and its licence. `fullMetadata` has the same facts as structured data. |
| `.zip` | The CSV, the metadata and the readme in one archive. Use it when the user wants a download. |
| `.png` | The chart as an image. See [embedding.md](embedding.md). |
| `.svg` | The same, as vector. |
| `.config.json` | The chart's own settings. Worth fetching whenever filtering matters: `tab`, `chartTypes`, `addCountryMode` and `hideTimeline` between them predict whether `country=` and `time=` will be honoured at all. It does not exist for multi-dimensional charts. |

The query string decides which part of the data comes back:

| Parameter | Values | Default | What it does |
|---|---|---|---|
| `csvType` | `full`, `filtered` | `full` | `full` gives every entity and every year in the chart. `filtered` gives what the chart itself shows. A misspelt value is ignored, so `csvType=fitlered` quietly gives you everything. |
| `country` | codes joined by `~`, e.g. `USA~GBR~OWID_WRL` | depends on the view | Which entities to include. **Only works with `csvType=filtered`**, and many charts ignore it even then — see below. Names work too, but codes are safer. Case matters: `usa` returns nothing. |
| `time` | `2015`, `2000..2020`, `earliest..2020`, `2000..latest`, `earliest..latest`, `latest`, `earliest` | the chart's own range | Which years. On `Month` and `Day` charts use full dates instead. **Only works with `csvType=filtered`**, and is ignored entirely when the chart's config says `hideTimeline`. |
| `useColumnShortNames` | `true`, `false` | `false` | `true` gives you `entity,code,year,life_expectancy_0`. `false` gives you `Entity,Code,Year,Life expectancy`. Use `true`: it is the only reliable way to match a CSV column to its metadata. Only lowercase `true` counts — `TRUE` is silently ignored. |
| `tab` | `chart`, `line`, `map`, `table`, `discrete-bar`, `scatter`, `slope`, `marimekko`, `dumbbell`, `stacked-area`, `stacked-bar`, `stacked-discrete-bar` | the chart's own tab | Which view `filtered` should copy. **Only works with `csvType=filtered`.** An unrecognised value does not error: you get the line view, which may not be the chart's own default. |
| dimension parameters | chart-specific | the chart's default view | On multi-dimensional charts, these choose the indicator. See below. |
| `nocache` | flag | | Skip the cache. Only useful right after a chart was updated. |

### How much data to ask for

Start from what the user gave you:

- **No parameters in the URL** — take the whole dataset with `csvType=full`.
- **Parameters already in the URL** — the user is looking at one view of the
  chart. Ask them whether they want that view or the whole dataset, rather than
  deciding for them.
- **You are answering one question** — filter on the server. Ask for exactly the
  countries and years you need, so you never handle more data than you need.

When you do filter, `?csvType=filtered&useColumnShortNames=true` plus explicit
`country=` and `time=` is the base to start from.

### Charts that will not give you their data

Where the producer forbids redistribution, `.csv` and `.zip` return **403** with
`{"status":403,"error":"This chart contains non-redistributable data..."}`,
whatever parameters you pass. It is a real minority of charts, concentrated in
health and causes of death; IHME's Global Burden of Disease charts are the common
case.

The metadata, readme, config and images still return 200, so you can still
describe and cite the chart. Check the status code before you parse the body —
that JSON starts with `{` and reads like a header row. Do not retry and do not
look for another route: tell the user the numbers have to come from the original
producer, and name it from the metadata.

## Explorers and multi-dimensional charts

Both let the reader switch between indicators inside one chart. The switch lives
in the query string, so here the query string is part of the request, not
decoration. Drop it and you get different numbers.

**Explorers** sit at `https://ourworldindata.org/explorers/<slug>` and take the
same suffixes and the same parameters, plus one parameter per dropdown:

```
https://ourworldindata.org/explorers/population-and-demography.csv?indicator=Population&Sex=Male&Age=Total&Projection+scenario=None&csvType=filtered&country=USA&time=2020
```

Change `Sex=Male` to `Sex=Female` and you get a different number, from the same
URL. Spaces in these values are written as `+`.

**Multi-dimensional charts** sit under `/grapher/` like any other chart, but they
also take one parameter per dimension. On `religious-composition` the dimensions
are `religion` and `indicator`:

```
https://ourworldindata.org/grapher/religious-composition.csv?csvType=filtered&tab=chart&country=USA&time=2020&religion=christians&indicator=share
```

Three things to know:

- **Get the parameters from a search hit, not from a browser.** A `multiDimView`
  or `explorerView` hit carries `queryParams` and a `url` that already selects
  that view; use either as it is (see [search-api.md](search-api.md)). There is
  no `.config.json` for a multi-dimensional chart to look them up in.
- **On a multi-dimensional chart, anything wrong is a 500.** A missing dimension,
  a misspelled dimension name — which leaves that dimension unset, so the set is
  partial — and a value that does not exist all fail loudly. A parameter that is
  not a dimension at all is ignored. This is the easy case: you see the failure.
- **On an explorer, everything wrong is silent.** A partial set, a wrong value
  and a misspelled parameter name all return 200 with the chart's default view —
  the wrong indicator, with no warning.

With `useColumnShortNames=true` the column name records the view you got
(`share__religion_christians`), which is the easiest way to confirm it.

## Reading the CSV

The CSV is long, or "tidy": **one row per entity and time point**, one column
per indicator. There are only two dimensions, entity and time. Anything else a
dataset measures by (sex, age group, scenario) is either a separate column, a
separate chart, or a dimension parameter as described above.

| Column | Holds |
|---|---|
| `Entity` / `entity` | The name. OWID spells each country the same way in every chart. |
| `Code` / `code` | The identifier. See below: it is not always an ISO code, and it is sometimes empty. |
| `Year` / `year` | A whole number. Negative means BCE, so `-10000` is 10,000 BCE. |
| `Month` / `Day` | Sub-annual charts carry one of these instead of `Year`. See below. |
| everything else | One indicator per column, already in the unit the metadata gives. |

An empty cell means there is no data for that entity and year. A country that is
missing altogether has no data in that chart at all. Neither is a zero.

### Entities

- **Countries keep today's borders** when the data goes back in time. "Italy" in
  the year 1 means the area that is Italy now.
- **Regions are aggregates**, and no brackets means OWID's own definition. When
  the brackets hold an organisation, they name whose scheme it is:
  `Sub-Saharan Africa (WB)` is the World Bank's, `Sub-Saharan Africa (FAO)` is the
  FAO's, and they are not the same set of countries. The same chart can carry
  several. Which countries each one contains is listed at
  [Definitions of world regions](https://ourworldindata.org/world-region-map-definitions),
  where every scheme's country-to-region mapping is also downloadable. Brackets do
  plenty of other work, so read what is inside before assuming it is a scheme:
  a publication year (`Maddison (1991)`), an exclusion (`Europe (excl. EU-27)`), a
  disambiguation (`Micronesia (country)`) or a historical state (`Sudan (former)`).
- **Historical states appear in long-run series**: `USSR`, `Yugoslavia`,
  `East Germany`, `Czechoslovakia`.
- **Some entities are not places**: income groups like `Low-income countries`,
  and splits like `China (urban)` or `Ethiopia (rural)`.

A whole chart can be like that, with AI models or industry sectors where you
expect countries. Nothing below about codes, regions and joining applies to those.

### The Code column

Do not assume a `Code` is an ISO code, do not assume it has a value, and do not
assume the column is there at all. Charts whose entities are not places — AI
models, age groups, industry sectors, sea regions, historical estimates — have no
`Code` column, and a chart that has one can drop it when a filter matches
nothing. Look columns up by name, never by position, and fall back to `Entity`.
When it is there it takes three shapes, and it is often empty:

- **ISO 3166-1 alpha-3** for countries: `USA`, `GBR`, `CIV`.
- **`OWID_` codes** for things OWID defines that have no ISO code: `OWID_WRL`
  (World), continents such as `OWID_AFR`, income groups such as `OWID_HIC`,
  `OWID_KOS` for Kosovo, historical states such as `OWID_USS`. They are not all
  the same length: `OWID_EU27` is longer.
- **`<BODY>_` codes** for regions as another organisation defines them. `WB_`,
  `WHO_`, `UN_`, `UNSDG_` and `PEW_` all appear, and they are not the whole list
  — [Definitions of world regions](https://ourworldindata.org/world-region-map-definitions)
  names more than a dozen schemes OWID carries.
- **Empty**, for a small but real share of entities, and not only obscure ones. Regions
  under somebody's scheme, groupings such as `Least developed countries`, parts
  of countries, and entities that are not places at all: individual wars,
  projects, even calendar months where a chart uses those as its entities.

A join on `Code` will look like it worked while quietly mishandling those rows, so
check the row count rather than assume.

Within OWID, names and codes are consistent: a name always maps to the same
code, and a code to the same name, in every chart. So you can line up two OWID
charts on `Code`, as long as you handle the entities that have none.

### Time

One column is named `Year`, `Month` or `Day`, and that name tells you how fine
the data is. It is usually third, but on a chart with no `Code` column it is
second — find it by name:

| Header | Format | A chart that has it |
|---|---|---|
| `Year` | a whole number, negative for BCE | `life-expectancy` |
| `Month` | `YYYY-MM` | `global-co2-concentration` |
| `Day` | `YYYY-MM-DD` | `daily-cases-covid-region` |

Annual is the norm. There is no `Week` column: weekly figures are dated by day,
as on `weekly-covid-deaths`. One chart can also mix time windows across its
columns — `global-co2-concentration` carries a monthly figure and a rolling
twelve-month average side by side on the same `Month` axis, both filled in every
month. Read `titleLong` before you assume what a second column is.

- **`earliest` and `latest` are one year for the entities you selected**, not one
  per country and not fixed for the chart. `latest` resolves to the most recent year
  *any* selected entity has, so ask for two countries whose data ends in different
  years and you get the later one — the entity that stopped earlier is silently
  dropped. For each country's own most recent value, fetch the range and take the
  last non-empty row per country yourself.
- **`timespan` is empty on sub-annual charts** — an empty string, not a missing
  field. Take the coverage from the first and last rows instead.
- **Filtering needs full dates on those charts.** `time=2021-01` is ignored and
  you get everything back. On a `Day` chart a range is exact. On a `Month` chart
  the end date rounds up, so `2021-01-01..2021-01-31` returns January *and*
  February — write first-of-month to first-of-month, or trim what comes back.
  `earliest` and `latest` work everywhere.
- Projections, where a chart has them, are a separate column — but the point where
  estimate stops and projection starts is decided **per country**, not per chart.
  On one chart the World's projection starts in 2025 while another entity's starts
  in 2002, and most entities have "projected" values for years already past. Do
  not read a value in a projection column as a forecast: per entity, find the last
  year the estimate column is filled. Say which column you used.

### Units

- Read `unit` and `shortUnit` before reporting anything. "per 100,000 people",
  "per 1,000 live births", "%" and "share" are easy to mistake for counts.
- Money is sometimes constant and sometimes current, and sometimes adjusted for
  what money buys in each country ("international-$"). Do not compare across
  those without saying that you did.

### Text and accents

Everything comes back as UTF-8. Two things follow:

- **The metadata and the readme contain real non-ASCII characters** — en dashes
  and curly quotes in the citation lines, `©` in the licence. Pass them through
  as they are, especially in a citation.
- **Entity names in the CSV do not.** Accents are stripped: the CSV says
  `Cote d'Ivoire`, `Curacao`, `Sao Tome and Principe`. Do not expect the accented
  spelling, and do not try to match against it.
- **Column headers do keep their special characters**, as in `Annual CO₂ emissions
  per capita` with a real subscript, so matching a header against a string you
  typed will fail — another reason for `useColumnShortNames=true`.

## Joining with other data

Join on `Code` and `Year`, never on names.

Two things will bite you:

- **Rows with an empty `Code` do not join the way you expect.** Count your rows
  before and after, and decide what to do about the difference rather than not
  noticing it.
- **A region name does not mean the same thing in two places.** `Sub-Saharan
  Africa` from OWID and `Sub-Saharan Africa` from another source can be different
  country lists. If you join regions by name, you may get numbers that look right
  and are not.

## Silent failures

Each of these returns a 200 and a plausible-looking file. Nothing tells you that
what came back is not what you asked for.

- **If you need named countries over time, use `csvType=full` and filter the rows
  yourself.** `filtered` is not a filter: it copies whatever view the chart opens
  in, and any view that is not a line or bar-over-time throws `country=` away and
  collapses you to a single time point. Maps do it, and so do scatter, Marimekko
  and discrete-bar views. `tab=chart` recovers the line view on some of them and does
  nothing on the rest, because a map-only chart has no chart tab to switch to.
  `.config.json` tells you in advance: `tab`, `chartTypes`, `addCountryMode` and
  `hideTimeline` between them predict it exactly.
- **On a filtered map view the `Year` column is the year you asked for, not the
  year of the number.** The map carries a value forward to fill a gap, stamps
  every row with the target year, and puts the real one in an extra
  `<Indicator> (Original Year)` column that has no metadata entry. If that column
  is there, it is the year. `csvType=full` never does this.
- **An entity you asked for that is not in the chart is dropped in silence.** So
  is a misspelling, an unrecognised code, and the wrong case — `country=usa`
  matches nothing. Count the entities that came back against the ones you asked
  for.
- **A `time=` range outside the data gives you the nearest year, not nothing.**
  Ask a chart that starts in 1980 for `1500..1600` and you get 1980, with no
  warning. Check the time values you got against the ones you asked for.
- **A bare number in `time=` is not a year on a `Month` or `Day` chart.** It is
  read as an offset in days from an internal origin, so `time=2020` on
  `daily-cases-covid-region` returns a single day in 2025. The origin is not in
  the chart's metadata, so do not try to work the date out: use full dates.
- **`tab=table` is not a way to get everything.** It usually undoes your
  filtering and hands back the whole dataset, but on some charts it keeps the
  filter and on others it returns an empty file. Use `csvType=full`.
- **A large `.csv` can fail with 503** and a Cloudflare body rather than a CSV.
  Retry once. Falling back to `csvType=filtered` gets you something, but not the
  same file — name the countries and years you want, and tell the user you did
  not get the whole dataset.
