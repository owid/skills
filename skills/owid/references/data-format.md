# Data format and conventions

How OWID data is shaped, what the identifiers mean, and how to combine it with
data from elsewhere without silently losing or double-counting rows.

## Shape

OWID chart data is long ("tidy"): **one row per entity and time point**, with
one column per indicator. Two dimensions only, entity and time. Extra
dimensions a dataset may have (sex, age group, scenario) are either separate
columns, separate charts, or the dimension parameters of a multi-dimensional
chart or explorer.

| Column | Content |
|---|---|
| `Entity` / `entity` | Harmonised name. OWID uses one spelling per country everywhere (`Czechia`, `Democratic Republic of Congo`, `Côte d'Ivoire`, `United States`). |
| `Code` / `code` | ISO 3166-1 alpha-3 for countries (`USA`, `GBR`, `CHN`). `OWID_` codes for entities without an ISO code: `OWID_WRL` (World), continents (`OWID_AFR`, `OWID_EUR`, ...), World Bank income groups (`OWID_HIC`, `OWID_LIC`, ...), `OWID_KOS` (Kosovo), historical states (`OWID_USS`, `OWID_YGS`). Aggregates defined by other bodies, e.g. `Americas (UN)`, may have an empty code. |
| `Year` / `year` | Integer. Negative values are BCE (`-10000`). |
| `Day` / `day` | `YYYY-MM-DD`, on daily charts instead of `Year`. |
| everything else | One indicator per column. Values are already in the unit given by the metadata `unit` field; any `conversionFactor` has been applied. Empty cells mean no data for that entity-year. |

Missing values are gaps, not zeros. A country absent from the CSV has no data
in that chart at all.

## Entities

- **Countries** use modern borders for historical values: "Italy" in 1 CE is
  the area of present-day Italy.
- **Regions** (`Europe`, `Sub-Saharan Africa (WB)`, `High-income countries`,
  `World`) are aggregates. Their definitions differ between OWID and other
  providers and between OWID datasets (the suffix in parentheses names the
  definition: `(WB)` World Bank, `(WHO)`, `(UN)`). Never join a region by name
  to another source's region of the same name.
- **Historical entities** (`USSR`, `Yugoslavia`, `East Germany`) appear with
  `OWID_` codes in long-run series.
- `chart.selection` in the metadata is the chart's default entity selection,
  which is also what `csvType=filtered` returns when no `country=` is passed.

## Time

- Annual data is the norm. `timespan` in the metadata (e.g. `1950-2023`) gives
  each column's coverage; check it before promising a year.
- `tolerance` (years) is how far an OWID chart looks to a neighbouring year to
  fill a gap when plotting. When you compute a value for a specific year,
  either use the exact year or say which neighbouring year you used.
- Projections, when present, are separate columns with their own `timespan`,
  populated only for the projected years. Drop the column if you want
  estimates only, and say which you used.

## Joining OWID data with other data

Join on **`Code` and `Year`**, never on entity names.

1. If the other dataset has ISO alpha-3 codes, join directly.
2. If it has ISO alpha-2 codes, country names, or another identifier, map to
   ISO alpha-3 first. For names, do the mapping explicitly and report which
   rows did not match rather than dropping them silently.
3. Drop or handle separately any regional aggregate rows in the other dataset
   (`EU`, `SSA`, `OECD`, `World`): they will not match OWID codes and must not
   be treated as countries.
4. If the other dataset has no year, decide the year from its documentation or
   with the user, and join OWID data for that same year.
5. After the join, count the rows that matched and list the ones that did not.

### Reference series for per-capita and GDP comparisons

| Need | Chart | Coverage | Notes |
|---|---|---|---|
| Population, long run | `https://ourworldindata.org/grapher/population` | 10,000 BCE to a year or two ago | Several sources stitched; the standard denominator for per-capita figures. |
| Population, recent and projected | `https://ourworldindata.org/grapher/population-with-un-projections` | 1950 to 2100 | UN World Population Prospects, medium variant. Use when you need the current year or the future. Estimates and projections are separate columns. |
| GDP per capita, long run | `https://ourworldindata.org/grapher/gdp-per-capita-maddison-project-database` | 1820 to a few years ago | Maddison Project, constant international-$; best for history, lags the present. |
| GDP per capita, recent | `https://ourworldindata.org/grapher/gdp-per-capita-worldbank` | 1990 to a year or two ago | World Bank, constant international-$; best for current comparisons. |

Confirm coverage from `.metadata.json` (`columns.*.timespan`) before relying on
a year. Coverage is the union across columns: `population-with-un-projections`
splits estimates and projections into two columns.

### Per-capita recipe

```bash
UA="owid-skills/1.0 (+https://github.com/owid/skills)"
G="https://ourworldindata.org/grapher"
P="csvType=filtered&useColumnShortNames=true&country=USA~GBR~CHN&time=2020"

curl -sA "$UA" -o co2.csv "$G/annual-co2-emissions-per-country.csv?$P"
curl -sA "$UA" -o pop.csv "$G/population.csv?$P"
# Then join the two files on code+year in whatever tool you are using (pandas,
# duckdb, R). Both carry `code` and `year`, so the join is an equi-join on two
# columns; check that the row count equals the number of countries requested.
```

Per-capita figures combine two sources, so cite both: the emissions producer
and the population producer, each from its own `citationShort`.

## Units and interpretation

- Read `unit` and `shortUnit`; "per 100,000", "per 1,000 live births", "%" and
  "share" are common and easy to confuse with counts.
- `descriptionShort` is the one-sentence definition. `descriptionKey` lists the
  caveats an editor thought a reader must know; if the question touches one,
  repeat it.
- `descriptionProcessing` explains OWID-side transformations (unit conversions,
  region aggregation, gap filling). Mention it when the user asks how a number
  was produced.
- Monetary series say whether they are in constant or current dollars and
  whether they are PPP-adjusted ("international-$"). Do not compare across
  those without saying so.
