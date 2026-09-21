# Chart data API

Every OWID chart lives at `https://ourworldindata.org/grapher/<slug>`, optionally
with a query string that selects a view (`?country=USA~GBR&time=2000..2020`, or
on multi-dimensional charts the dimensions, e.g. `?indicator=share&religion=any_religion`).
Appending a suffix to the path turns the same URL into a download. Full
reference: <https://docs.owid.io/projects/etl/api/chart-api/>.

Always send `-A "owid-skills/1.0 (+https://github.com/owid/skills)"`.

## Endpoints

| Suffix | Returns | Use it for |
|---|---|---|
| `.metadata.json` | JSON: chart title/subtitle/note/citation, one entry per data column with unit, descriptions, timespan, citations | **Always fetch first.** Understanding what the numbers mean and their caveats. |
| `.csv` | CSV, one row per entity and time point | The data. |
| `.readme.md` | Markdown "data package" description: CSV structure, per-indicator sources, processing notes, licence | Answering "where does this come from, how was it produced". Human-readable; long. |
| `.zip` | The three files above in one archive | Handing the user a complete download. |
| `.png` | Rendered chart image | Slides, documents, chat surfaces that cannot iframe. See [embedding.md](embedding.md). |
| `.svg` | Same as `.png`, as vector | Print, editing in a design tool. |
| `.config.json` | The chart's grapher configuration (title, selected entities, chart types, map settings, indicator ids) | Rarely needed; useful to see the default entity selection or default tab. |

Explorer views (`https://ourworldindata.org/explorers/<slug>?...`) accept the
same suffixes with their query string kept, e.g. `/explorers/<slug>.csv?...`.

## Query parameters for `.csv` and `.metadata.json`

| Parameter | Values | Default | Effect |
|---|---|---|---|
| `csvType` | `full`, `filtered` | `full` | `full` returns every entity and year the chart has. `filtered` returns what the chart's current view shows, i.e. only the entities and years selected by `country=`, `time=` and the chart's defaults. |
| `useColumnShortNames` | `true`, `false` | `false` | `true` gives machine-friendly column names (`life_expectancy_0`) instead of the long titles, and lowercases the first three headers to `entity,code,year`. Recommended. |
| `country` | codes joined with `~`, e.g. `USA~GBR~OWID_WRL` | chart default | Entities to include. ISO alpha-3 codes for countries; `OWID_` codes for regions (`OWID_WRL` is World). Entity names (`country=World`) are accepted too, but codes are safer. Only applied when `csvType=filtered`. |
| `time` | `2015`, `2000..2020`, `earliest..2020`, `2000..latest`, `earliest..latest`, `latest` | chart default | Year (or `YYYY-MM-DD` for daily data) or range. Only applied when `csvType=filtered`. |
| `tab` | `line`, `map`, `table`, ... | chart default | Which view `filtered` refers to. **Needed on map-default charts**: a map shows every country, so on those `country=` is ignored until you add `tab=chart` or `tab=line`. |
| dimension parameters | chart-specific, e.g. `indicator=share&religion=any_religion` | | Multi-dimensional charts and explorers. Copy them from the chart URL exactly; they choose which indicator you get. |

**Recommended base:** `?csvType=filtered&useColumnShortNames=true` plus explicit
`country=` and `time=`. Use `csvType=full` when you genuinely need everything.

```bash
UA="owid-skills/1.0 (+https://github.com/owid/skills)"
URL="https://ourworldindata.org/grapher/life-expectancy"

curl -sA "$UA" -o meta.json "$URL.metadata.json?country=USA~GBR&time=2000..2020"
curl -sA "$UA" -o data.csv "$URL.csv?csvType=filtered&useColumnShortNames=true&country=USA~GBR&time=2000..2020"
```

## Metadata shape

```typescript
type MetadataColumn = {
  titleShort: string
  titleLong: string
  descriptionShort?: string
  descriptionKey?: string        // markdown bulleted list ("- " per line) of caveats and key facts curated by OWID editors; surface it when relevant
  descriptionProcessing?: string // how OWID processed the data, if it is not a straight republish
  unit?: string                  // "years", "deaths per 100,000 people", "% of GDP"
  shortUnit?: string             // "%", "$", "t"
  timespan?: string              // "1543-2023"; negative start for BCE
  tolerance?: number             // years OWID charts look back/forward to fill a gap when plotting sparse data
  type?: string                  // Numeric | Categorical | Ordinal | Integer
  conversionFactor?: number      // already applied to the CSV values; never apply it again
  shortName?: string             // the CSV column name when useColumnShortNames=true
  lastUpdated?: string           // YYYY-MM-DD
  nextUpdate?: string            // YYYY-MM-DD
  citationShort: string          // the line to put in your output, e.g. "UN WPP (2024); HMD (2025) – with major processing by Our World in Data"
  citationLong: string
  fullMetadata: string           // URL of the full indicator metadata JSON (origins, licences, processing)
}

type GrapherMetadataResponse = {
  chart: {
    title?: string
    subtitle?: string
    note?: string
    xAxisLabel?: string
    yAxisLabel?: string
    citation: string             // producer-level citation for the whole chart
    originalChartUrl?: string
    selection: string[]          // the chart's default entity selection, by name
  }
  columns: Record<string, MetadataColumn>   // keyed by column name; an object, not an array
  dateDownloaded: string         // YYYY-MM-DD
  activeFilters?: Record<string, string>    // echoes country/time etc. if you passed them
}
```

Pull out what you need rather than reading the whole file:

```bash
jq '{chart: (.chart | {title, subtitle, note, citation}),
     columns: (.columns | map_values({unit, shortUnit, timespan, descriptionShort, descriptionKey, citationShort}))}' meta.json
```

## CSV shape

One row per entity and time point. The first three columns are:

- `Entity` — the entity name (`United States`, `Sub-Saharan Africa (WB)`, `World`).
- `Code` — ISO alpha-3 for countries (`USA`); `OWID_` codes for regions and
  historical or non-standard entities (`OWID_WRL`, `OWID_KOS`); may be empty
  for some aggregates.
- `Year` — an integer, negative for BCE. Daily charts have `Day` instead,
  holding `YYYY-MM-DD`.

Then one column per data series. With `useColumnShortNames=true` the header is
`entity,code,year,<short_name>,...` (lowercase); without it, `Entity,Code,Year,<Long title>,...`.
Match header names case-insensitively. Long titles can contain commas and are
quoted, so use a real CSV parser rather than `cut -d,` on those.

To save tokens, drop `Entity` (the `Code` is enough to identify rows and to join)
and keep only the columns you need. Column details are in
[data-format.md](data-format.md).

## Images: `.png` and `.svg`

The image endpoints honour the same view parameters (`country`, `time`, `tab`,
dimension parameters), so a PNG of exactly the view you analysed is one request:

```bash
curl -sA "$UA" -o chart.png "$URL.png?country=USA~GBR&time=2000..2020&tab=line"
curl -sA "$UA" -o map.png   "$URL.png?tab=map&time=2020"
```

Image-specific parameters:

| Parameter | Effect |
|---|---|
| `imType=og` | 1200×628 social-card layout (Open Graph). `imType=twitter` gives 800×418. |
| `imType=square` | Square layout; `imSquareSize=<px>` sets the side. |
| `imType=thumbnail` | Small thumbnail layout; supports `imWidth`, `imHeight`, `imMinimal=1`. |
| `imType=uncaptioned` | Chart without the title/subtitle/footer block. |
| `imWidth=<px>`, `imHeight=<px>` | Custom size for the default layout. Give one and the other follows the default aspect ratio; extreme ratios and very large sizes are clamped. |
| `imDetails=1` | Append the details-on-demand definitions below the chart. |
| `imFontSize=<pt>` | Base font size. |
| `nocache` | Bypass the one-hour cache after a chart was just updated. |

The rendered image already carries the OWID logo and the source line, so it is
self-attributing; still cite the producer in the surrounding text.

## Traps

- **`csvType=filtered` without `country=` means the chart's default selection**,
  which for `population` is seven regions and no individual country. When you
  want everything, say `csvType=full`.
- **Map-default charts ignore `country=`** until you add `tab=chart`. If a
  filtered CSV comes back with every country, this is why.
- **Projections and estimates can share a chart** as separate columns (UN
  population 1950–2023 estimates plus a 2024–2100 medium-variant projection),
  each populated only for its own years. Check `timespan` per column, and
  drop the projection column yourself if you want estimates only; there is no
  query parameter for it.
- **Multi-dimensional charts may return `chart.title: null`** in the metadata.
  Use the column `titleShort`/`titleLong` or `.readme.md` for a name.
- **The slug is not the topic.** `life-expectancy` and
  `life-expectancy-at-birth-hmd` are different charts with different sources.
  Search rather than guessing, and quote the chart you actually used.
