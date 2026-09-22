# Data API

Every chart on Our World in Data has a URL. Add a suffix to that URL and you get
a file instead of a web page. Add parameters and you choose which part of the
data you get. No API key, no sign-up.

## How a request is built

Here is one request, taken apart:

```
https://ourworldindata.org/grapher/life-expectancy.csv?csvType=filtered&country=USA~GBR&time=2000..2020
└───────────┬────────────┘└──┬───┘└──────┬───────┘└┬─┘└───────────────────────┬───────────────────────┘
         the site          section      slug     suffix                    the view
```

- **The slug** names the chart. `life-expectancy` and `life-expectancy-at-birth-hmd`
  are two different charts with two different sources. Never invent one: get it
  from a search result or from a URL the user gave you.
- **The suffix** says which file you want. Leave it off and you get the web page.
- **The view** says which part of the data you want: which countries, which
  years, and on some charts which indicator.

Explorer charts work the same way. They sit under `/explorers/` instead of
`/grapher/`, and they take the same suffixes.

If the user gave you a URL, keep its query string. On explorers and
multi-dimensional charts the query string chooses the indicator, so dropping it
gives you different numbers.

Send this header on every request. OWID uses it to see that the skill is being
used:

```bash
UA="owid-skills/1.0 (+https://github.com/owid/skills)"
```

## Start with the metadata

Fetch `<chart-url>.metadata.json` before you do anything else, every time, even
when the user only asked for numbers. Read it into your context and keep it
there.

Treat it differently from the data. A CSV can be hundreds of thousands of rows,
so you save it to a file and work on it there. The metadata is a few kilobytes,
and you cannot do the job well without it, so it belongs in your context.

It tells you:

- **What the numbers are.** The unit, and what the indicator actually measures.
- **Where they come from.** The original producer, which you must name when you
  report a figure. "Our World in Data" on its own is not a source.
- **What the limits are.** `descriptionKey` holds the caveats our editors wrote
  by hand: what is estimated, what is not comparable across countries, what a
  break in the series means, etc.
- **How far the data goes.** `timespan` per column. If it stops before the year
  the user asked about, say so instead of guessing.

Without this you can answer a question but you cannot tell the user what the
answer means, and you cannot warn them when the number does not say what they
think it says. That is most of the value you add during a chat or a coding
session.

```bash
curl -sA "$UA" -o meta.json \
  "https://ourworldindata.org/grapher/life-expectancy.metadata.json"
```

### The metadata fields

Two things at the top level: `chart`, describing the chart as a whole, and
`columns`, with one entry per data column, keyed by the column name.

| Field | Holds |
|---|---|
| `chart.title`, `chart.subtitle`, `chart.note` | The chart's own wording. Multi-dimensional charts have no title. |
| `chart.citation` | The producers behind the whole chart. |
| `chart.selection` | The entities the chart shows by default, by name. This is also what `csvType=filtered` returns when you pass no `country=`. |
| `chart.originalChartUrl` | The chart this data came from. |
| `columns.*.titleShort`, `titleLong` | The column's name, short and long. |
| `columns.*.unit`, `shortUnit` | `"years"`, `"deaths per 100,000 people"`, `"%"`. Read this before you report any number. |
| `columns.*.descriptionShort` | A one-sentence definition of the indicator. |
| `columns.*.descriptionKey` | The caveats, written by OWID editors, as a bulleted list. Repeat the ones that bear on the user's question. |
| `columns.*.descriptionProcessing` | Notes on OWID's processing step for this indicator. |
| `columns.*.timespan` | The years the column covers, e.g. `1543-2023`. |
| `columns.*.type` | Almost always `Numeric` or `Integer`. Also `String`, `NumberOrString`, `Ordinal`, `Continent` and `SeriesAnnotation`. Sometimes missing. |
| `columns.*.shortName` | The column name you get with `useColumnShortNames=true`. |
| `columns.*.lastUpdated`, `nextUpdate` | Dates, `YYYY-MM-DD`. |
| `columns.*.citationShort`, `citationLong` | The source lines. See below. |
| `columns.*.fullMetadata` | A URL with the complete indicator metadata: every origin, licence and processing step. |
| `columns.*.owidVariableId` | OWID's internal id for the indicator. |
| `dateDownloaded` | The day you fetched it. |

Pull out what you need rather than reading the whole file:

```bash
jq '{chart: (.chart | {title, subtitle, note}),
     columns: (.columns | map_values({unit, timespan, descriptionShort, descriptionKey, citationShort}))}' meta.json
```

### Citing the source

OWID almost never collects the data. It republishes work done by other people,
and those people need the credit to keep doing the work. So "Our World in Data"
on its own is not a citation. Name the producer.

**Say it out loud at least once per session.** Even in a chat where nobody asked
for a citation, tell the user where the numbers came from the first time you use
them. `citationShort` is written for exactly this: it is one line, it reads as
prose, and it names the producers before it names OWID.

```
Gapminder (2015); UN Inter-agency Group for Child Mortality Estimation (2025) – processed by Our World in Data
```

Use `citationLong` when you are writing something that will be read later, such
as a report, a document or a footnote. It names the producers, the dataset, and
the original data behind it:

```
Gapminder (2015); UN Inter-agency Group for Child Mortality Estimation (2025) – processed by
Our World in Data. “Child mortality rate – Gapminder; UN IGME – Long-run data” [dataset].
United Nations Inter-agency Group for Child Mortality Estimation, “United Nations Inter-agency
Group for Child Mortality Estimation 2025”; Gapminder, “Child mortality rate under age five v7”
[original data].
```

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
| `.readme.md` | A written description of the data and where it came from. Long, but it answers "how was this made" in one request. |
| `.zip` | The CSV, the metadata and the readme in one archive. Use it when the user wants a download. |
| `.png` | The chart as an image. See [embedding.md](embedding.md). |
| `.svg` | The same, as vector. |
| `.config.json` | The chart's own settings, including which entities it shows by default. Rarely needed, and it does not exist for multi-dimensional charts. |

The query string decides which part of the data comes back:

| Parameter | Values | Default | What it does |
|---|---|---|---|
| `csvType` | `full`, `filtered` | `full` | `full` gives every entity and every year in the chart. `filtered` gives what the chart itself shows. |
| `country` | codes joined by `~`, e.g. `USA~GBR~OWID_WRL` | the chart's own selection | Which entities to include. **Only works with `csvType=filtered`.** Names work too, but codes are safer. |
| `time` | `2015`, `2000..2020`, `earliest..2020`, `2000..latest`, `earliest..latest`, `latest`, `earliest` | the chart's own range | Which years. On daily charts, use dates: `2021-01-01..2021-01-31`. **Only works with `csvType=filtered`.** |
| `useColumnShortNames` | `true`, `false` | `false` | `true` gives you `entity,code,year,life_expectancy_0`. `false` gives you `Entity,Code,Year,Life expectancy`. Use `true`: the long names contain commas and spaces. |
| `tab` | `chart`, `line`, `map`, `table` | the chart's own tab | Which view `filtered` should copy. You need it on charts that open as a map. |
| dimension parameters | chart-specific | the chart's default view | On multi-dimensional charts, these choose the indicator. See below. |
| `nocache` | flag | | Skip the cache. Only useful right after a chart was updated. |

### How much data to ask for

Start from what the user gave you:

- **No parameters in the URL** — take the whole dataset with `csvType=full`.
- **Parameters already in the URL** — the user is looking at one view of the
  chart. Ask them whether they want that view or the whole dataset, rather than
  deciding for them.
- **You are answering one question** — filter on the server. Ask for exactly the
  countries and years you need, so you never handle a large file.

```bash
G="https://ourworldindata.org/grapher/life-expectancy"

# Everything the chart has
curl -sA "$UA" -o full.csv "$G.csv?csvType=full&useColumnShortNames=true"

# Two countries, two decades
curl -sA "$UA" -o part.csv \
  "$G.csv?csvType=filtered&useColumnShortNames=true&country=USA~GBR&time=2000..2020"
```

## Explorers and multi-dimensional charts

Both let the reader switch between indicators inside one chart. The switch lives
in the query string, so here the query string is part of the request, not
decoration. Drop it and you get different numbers.

**Explorers** sit at `https://ourworldindata.org/explorers/<slug>` and take the
same suffixes and the same parameters, plus one parameter per dropdown:

```bash
E="https://ourworldindata.org/explorers/population-and-demography"
P="indicator=Population&Sex=Male&Age=Total&Projection+scenario=None"

curl -sA "$UA" -o pop.csv "$E.csv?$P&csvType=filtered&country=USA&time=2020"
```

Change `Sex=Male` to `Sex=Female` and you get a different number, from the same
URL. Spaces in these values are written as `+`.

**Multi-dimensional charts** sit under `/grapher/` like any other chart, but they
also take one parameter per dimension. On `religious-composition` the dimensions
are `religion` and `indicator`:

```bash
M="https://ourworldindata.org/grapher/religious-composition"

curl -sA "$UA" -o rel.csv \
  "$M.csv?csvType=filtered&tab=chart&country=USA&time=2020&religion=christians&indicator=share"
```

Four things to know:

- **Copy the parameters from the chart URL.** Open the chart, choose the view you
  want, and take the query string as it is. Do not guess the names: there is no
  `.config.json` for a multi-dimensional chart to look them up in.
- **Give every dimension, or none.** A complete set works. No dimensions at all
  gives the chart's default view. A partial set returns a 500.
- **A wrong value returns a 500 on a multi-dimensional chart.** This is the easy
  case: the request fails and you can see it.
- **A wrong parameter name is ignored, and so is a wrong value on an explorer.**
  You get a 200 and the default view, which means the wrong indicator with no
  warning. Check that the column name in the CSV matches the view you asked for.

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
| `Day` / `day` | `YYYY-MM-DD`, on daily charts, instead of `Year`. |
| everything else | One indicator per column, already in the unit the metadata gives. |

An empty cell means there is no data for that entity and year. A country that is
missing altogether has no data in that chart at all. Neither is a zero.

### Entities

- **Countries keep today's borders** when the data goes back in time. "Italy" in
  the year 1 means the area that is Italy now.
- **Regions are aggregates**, and the name says whose definition it is:
  `Sub-Saharan Africa (WB)` is the World Bank's, `Sub-Saharan Africa (FAO)` is
  the FAO's, and they are not the same set of countries. The same chart can
  carry several.
- **Historical states appear in long-run series**: `USSR`, `Yugoslavia`,
  `East Germany`, `Czechoslovakia`.
- **Some entities are not places**: income groups like `Low-income countries`,
  and splits like `China (urban)` or `Ethiopia (rural)`.

### The Code column

The `Code` column comes in three shapes, and it is often empty:

- **ISO 3166-1 alpha-3** for countries: `USA`, `GBR`, `CIV`.
- **`OWID_` codes** for things with no ISO code: `OWID_WRL` (World), continents
  (`OWID_AFR`), income groups (`OWID_HIC`), Kosovo (`OWID_KOS`), historical
  states (`OWID_USS`), and `OWID_EU27`, which is longer than the rest.
- **`UN_` and `WB_` codes** for regions defined by those bodies: `UN_AFR`,
  `WB_SSA`, `WB_MENAP`.
- **Empty.** Roughly a quarter of the entities in OWID's largest charts have no
  code at all. That includes `Scotland`, `Northern Ireland`, `England and Wales`,
  every `(FAO)` region, and every urban and rural split.

Within OWID, names and codes are consistent: a name always maps to the same
code, and a code to the same name, in every chart. So you can line up two OWID
charts on `Code` safely, as long as you handle the entities that have none.

### Years and days

- Annual data is the norm. Check `timespan` on the column before you promise a
  year; if the data stops earlier, say so.
- Projections, where a chart has them, are a separate column with their own
  `timespan`, filled in only for the projected years. Say which one you used.

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

## Joining with other data

Join on `Code` and `Year`, never on names.

Two things will bite you:

- **Rows with an empty `Code` drop out silently.** That is a quarter of the
  entities in a big chart. Count your rows before and after, and decide what to
  do with the ones you lost rather than not noticing them.
- **A region name does not mean the same thing in two places.** `Sub-Saharan
  Africa` from OWID and `Sub-Saharan Africa` from another source can be different
  country lists. Join regions by name and you get numbers that look right and are
  not. Match countries, and build the region yourself if you need one.

## Silent failures

Each of these returns a 200 and a plausible-looking file. Nothing tells you that
what came back is not what you asked for.

- **`country=` and `time=` do nothing without `csvType=filtered`.** They are not
  rejected, they are ignored, and you get every country back. If a "filtered"
  download looks far too big, this is why.
- **`csvType=filtered` with no `country=` gives the chart's own selection.** On
  `life-expectancy` that is the world and the continents, not the countries. Name
  the countries you want, or use `csvType=full`.
- **Charts that open as a map ignore `country=`.** A map shows every country, so
  there is nothing to filter. Add `tab=chart` to get the country selection back.
  `political-regime` behaves this way.
- **`tab=table` gives you everything.** The table view holds all entities, so it
  undoes your filtering.
- **`earliest` and `latest` are one year for the whole chart, not per country.**
  `time=earliest` on `life-expectancy` gives the first year any country has data,
  and countries with nothing that year are simply missing from the result.
- **Estimates and projections can share a chart**, as separate columns covering
  different years. There is no parameter to drop the projection. Check `timespan`
  per column and drop it yourself.
