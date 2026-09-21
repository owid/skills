#!/usr/bin/env bash
# Contract tests for the owid skill: do the two public endpoints still behave
# the way SKILL.md and its references say they do? Run via `make test`.
#
# The skill is documentation over live endpoints, so the checks are grouped by
# the reference file that makes each claim. Guard dependent checks on fetch
# succeeding so one dead endpoint does not cascade into a wall of failures.
source "$EVALS_LIB/assert.sh"

API="https://ourworldindata.org/api/search"
GRAPHER="https://ourworldindata.org/grapher"
EXPLORER="https://ourworldindata.org/explorers"

SEARCH_REF="references/search-api.md"
DATA_REF="references/chart-data-api.md"
FORMAT_REF="references/data-format.md"
EMBED_REF="references/embedding.md"

# ---------------------------------------------------------------------------
section "Search API: endpoint and chart-search envelope"
COMMON="$WORK/search-common.json"
if fetch "$API?q=life+expectancy&hitsPerPage=5" "$COMMON"; then
    has_keys "envelope has the documented ChartSearchResponse fields" "$COMMON" "." \
        query results nbHits page nbPages hitsPerPage
    jq_type "results is an array" "$COMMON" '.results' array
    jq_true "a common query returns hits" "$COMMON" '.nbHits > 0'
    jq_true "hitsPerPage caps the result count" "$COMMON" '(.results | length) <= 5'
    jq_eq "page is 0-indexed by default" "$COMMON" '.page' 0
    jq_eq "query is echoed back" "$COMMON" '.query' 'life expectancy'
    none_match "closestMatches is absent on an exact-match response" "$COMMON" '.' 'has("closestMatches")'
fi

section "Search API: pagination and limits"
if fetch "$API?q=energy&hitsPerPage=5&page=1" "$WORK/search-page1.json"; then
    jq_eq "requesting page=1 returns page 1" "$WORK/search-page1.json" '.page' 1
fi
http_status "hitsPerPage above 100 is rejected with 400" "$API?q=energy&hitsPerPage=101" 400
http_status "an unknown type is rejected with 400" "$API?q=energy&type=writing" 400
if fetch "$API?q=energy&resultType=writing&hitsPerPage=3" "$WORK/search-resulttype.json"; then
    # The skill warns that resultType is silently ignored. If the API ever
    # starts honouring it, that warning becomes wrong.
    jq_true "resultType is ignored: the response is still a chart search" \
        "$WORK/search-resulttype.json" '[.results[].type] | unique | inside(["chart", "explorerView", "multiDimView"])'
fi

section "Search API: chart hit shape"
BROAD="$WORK/search-broad.json"
if fetch "$API?q=energy&hitsPerPage=50" "$BROAD"; then
    all_match "every hit has url, title, slug and type" "$BROAD" '.results[]' \
        'has("url") and has("title") and has("slug") and has("type")'
    all_match "availableEntities is an array on every hit" "$BROAD" '.results[]' \
        '.availableEntities | type == "array"'
    all_match "availableTabs is an array on every hit" "$BROAD" '.results[]' \
        '.availableTabs | type == "array"'
    all_match "chart urls are absolute ourworldindata.org urls" "$BROAD" '.results[]' \
        '.url | startswith("https://ourworldindata.org/")'
    jq_true "every type is one of the documented values" "$BROAD" \
        '[.results[].type] | unique | inside(["chart", "explorerView", "multiDimView"])'
    all_match "every hit has publishedAt and updatedAt as ISO 8601" "$BROAD" '.results[]' \
        '(.publishedAt | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T")) and (.updatedAt | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T"))'
fi

section "Search API: explorer and multi-dim view hits"
# Which record types a query returns is not stable, so all_match's loud skip
# matters here: a type missing from the sample cannot masquerade as a pass.
NONCHART="$WORK/search-nonchart.json"
if fetch "$API?q=population&hitsPerPage=100" "$NONCHART"; then
    note "types present: $(jq -r '[.results[].type] | group_by(.) | map("\(.[0])=\(length)") | join(" ")' "$NONCHART")"
    jq_true "at least one non-chart record type is represented" "$NONCHART" \
        '[.results[] | select(.type != "chart")] | length > 0'
    all_match "view hits carry queryParams" "$NONCHART" \
        '.results[] | select(.type != "chart")' 'has("queryParams")'
    all_match "view hits carry containerTitle" "$NONCHART" \
        '.results[] | select(.type != "chart")' 'has("containerTitle")'
    all_match "view hit urls already include their query string" "$NONCHART" \
        '.results[] | select(.type != "chart")' '.url | contains("?")'
    none_match "containerTitle is absent on plain chart hits" "$NONCHART" \
        '.results[] | select(.type == "chart")' 'has("containerTitle")'
fi

section "Search API: chart filters"
if fetch "$API?q=life+expectancy&countries=Kenya~Chad&requireAllCountries=true&hitsPerPage=20" "$WORK/search-countries.json"; then
    jq_true "countries + requireAllCountries still returns hits" "$WORK/search-countries.json" '.nbHits > 0'
    all_match "every hit has data for both requested countries" "$WORK/search-countries.json" '.results[]' \
        '(.availableEntities | index("Kenya") != null) and (.availableEntities | index("Chad") != null)'
fi
if fetch "$API?q=deaths&topics=Malaria&hitsPerPage=10" "$WORK/search-topics.json"; then
    jq_true "topics filter returns hits" "$WORK/search-topics.json" '.nbHits > 0'
    note "topics=Malaria top hit: $(jq -r '.results[0].title' "$WORK/search-topics.json")"
fi

section "Search API: no such thing as an empty result"
EMPTY="$WORK/search-empty.json"
if fetch "$API?q=zzzzqqqx+not+a+real+topic&hitsPerPage=5" "$EMPTY"; then
    jq_true "the request succeeds rather than erroring" "$EMPTY" '.results | type == "array"'
    jq_true "a nonsense query still returns hits" "$EMPTY" '.nbHits > 0'
    jq_eq "the relaxed response is flagged with closestMatches" "$EMPTY" '.closestMatches' true
    jq_eq "a relaxed response is a single page" "$EMPTY" '.nbPages' 1
fi

section "Search API: page search"
PAGES="$WORK/search-pages.json"
if fetch "$API?q=malaria&type=pages&hitsPerPage=20" "$PAGES"; then
    has_keys "envelope has the documented PageSearchResponse fields" "$PAGES" "." \
        query results nbHits offset length
    all_match "every page hit has title, slug, type and url" "$PAGES" '.results[]' \
        'has("title") and has("slug") and has("type") and has("url")'
    jq_true "the default pageTypes yield only articles and about pages" "$PAGES" \
        '[.results[].type] | unique | inside(["article", "about-page"])'
    all_match "article hits carry authors, date and content" "$PAGES" \
        '.results[] | select(.type == "article")' 'has("authors") and has("date") and has("content")'
fi
if fetch "$API?q=malaria&type=pages&pageTypes=data-insight&hitsPerPage=5" "$WORK/search-insights.json"; then
    jq_true "pageTypes=data-insight returns only data insights" "$WORK/search-insights.json" \
        '(.results | length) > 0 and ([.results[].type] | unique == ["data-insight"])'
fi
# The 400 for an unknown pageTypes value lists the valid ones, which makes it
# the authoritative source for the list in the reference.
BADTYPES="$WORK/search-badtypes.json"
http_status "an unknown pageTypes value is rejected with 400" "$API?q=malaria&type=pages&pageTypes=blog" 400 "$BADTYPES"
if [[ -s "$BADTYPES" ]] && jq -e '.error' "$BADTYPES" >/dev/null 2>&1; then
    valid_types=$(jq -r '[.error, .details, .message] | map(strings) | join(" ") | capture("Valid types: (?<t>[^\"]*)").t // "" | split(", ")[]' "$BADTYPES" 2>/dev/null)
    if [[ -n "$valid_types" ]]; then
        note "valid pageTypes per the API: $(printf '%s' "$valid_types" | tr '\n' ' ')"
        missing=""
        while read -r t; do
            [[ -z "$t" ]] && continue
            grep -q "\`$t\`" "$SKILL_DIR/$SEARCH_REF" || missing="$missing $t"
        done <<<"$valid_types"
        if [[ -z "$missing" ]]; then
            _pass "every valid pageTypes value is documented in $SEARCH_REF"
        else
            _fail "every valid pageTypes value is documented in $SEARCH_REF" "missing:$missing"
        fi
    else
        skip "pageTypes list documentation check" "could not parse the valid types out of the error body"
    fi
fi

section "Search API: documentation drift"
observed_tabs=$(jq -r '.results[].availableTabs[]' "$BROAD" "$NONCHART" "$COMMON" 2>/dev/null | sort -u)
doc_table_covers "every observed availableTabs value is in the tab mapping table" "$SEARCH_REF" "$observed_tabs"
note "observed tabs: $(printf '%s' "$observed_tabs" | tr '\n' ' ')"
doc_contains "the reference lists every documented parameter" "$SEARCH_REF" '`pageTypes`'
doc_contains "the reference warns that resultType is not a parameter" "$SEARCH_REF" 'resultType'
skill_md_contains "SKILL.md points at /api/search" 'ourworldindata\.org/api/search'
skill_md_contains "SKILL.md mentions the closestMatches fallback" 'closestMatches'

# ---------------------------------------------------------------------------
section "Chart data API: metadata"
CHART="$GRAPHER/life-expectancy"
PARAMS="useColumnShortNames=true&csvType=filtered&country=USA~GBR&time=2000..2020"
META="$WORK/metadata.json"
if fetch "$CHART.metadata.json?$PARAMS" "$META"; then
    has_keys "top level has chart, columns, dateDownloaded" "$META" "." chart columns dateDownloaded
    jq_type "columns is an object keyed by column name" "$META" '.columns' object
    jq_true "columns is non-empty" "$META" '(.columns | length) > 0'
    jq_true "chart.title is a non-empty string" "$META" '(.chart.title | type == "string") and (.chart.title | length > 0)'
    jq_true "chart.citation is present" "$META" '.chart | has("citation")'
    jq_type "chart.selection is an array" "$META" '.chart.selection' array
    jq_true "dateDownloaded is YYYY-MM-DD" "$META" '.dateDownloaded | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")'
    jq_true "activeFilters echoes the query params" "$META" \
        '.activeFilters.country == "USA~GBR" and .activeFilters.time == "2000..2020"'
    all_match "every column has titleShort and titleLong" "$META" '.columns[]' 'has("titleShort") and has("titleLong")'
    all_match "every column has citationShort and citationLong" "$META" '.columns[]' 'has("citationShort") and has("citationLong")'
    all_match "every column has fullMetadata" "$META" '.columns[]' 'has("fullMetadata")'
    all_match "shortName is present when useColumnShortNames=true" "$META" '.columns[]' 'has("shortName")'
    all_match "timespan looks like a year range" "$META" '.columns[] | select(has("timespan"))' \
        '.timespan | test("^-?[0-9]+-[0-9]+$")'
    all_match "descriptionKey is a markdown bulleted string, as documented" "$META" \
        '.columns[] | select(has("descriptionKey"))' '(.descriptionKey | type == "string") and (.descriptionKey | test("^- "))'
    note "columns: $(jq -r '.columns | keys | join(", ")' "$META")"
fi

section "Chart data API: CSV with the recommended parameters"
CSV_SHORT="$WORK/data-shortnames.csv"
if fetch "$CHART.csv?$PARAMS" "$CSV_SHORT"; then
    csv_min_rows "the csv has data rows" "$CSV_SHORT" 1
    csv_has_columns "the documented entity, code and year columns exist" "$CSV_SHORT" entity code year
    csv_header "useColumnShortNames=true lowercases the first three headers" "$CSV_SHORT" "entity,code,year"
    csv_column_set "the country filter is respected" "$CSV_SHORT" code "GBR USA"
    csv_column_range "the time filter is respected" "$CSV_SHORT" year 2000 2020
    data_columns=$(head -1 "$CSV_SHORT" | cut -d, -f4-)
    ok "short column names contain no spaces" test "$data_columns" = "${data_columns// /}"
fi

CSV_PLAIN="$WORK/data-plain.csv"
if fetch "$CHART.csv?csvType=filtered&country=USA&time=2020" "$CSV_PLAIN"; then
    csv_header "without useColumnShortNames the header is Entity,Code,Year" "$CSV_PLAIN" "Entity,Code,Year"
    csv_column_set "a single-country filter works without a tilde" "$CSV_PLAIN" Code "USA"
fi

section "Chart data API: filters, time keywords and csvType"
if fetch "$CHART.csv?csvType=filtered&useColumnShortNames=true&country=USA&time=earliest..latest" "$WORK/data-earliest-latest.csv"; then
    csv_min_rows "time=earliest..latest returns many years" "$WORK/data-earliest-latest.csv" 50
fi
if fetch "$CHART.csv?csvType=filtered&useColumnShortNames=true&country=USA&time=latest" "$WORK/data-latest.csv"; then
    csv_min_rows "time=latest returns a row" "$WORK/data-latest.csv" 1
    ok "time=latest returns a single year" test "$(csv_column "$WORK/data-latest.csv" year | sort -u | wc -l | tr -d ' ')" = "1"
fi
FULL="$WORK/data-full.csv"
if fetch "$CHART.csv?country=USA&time=2020" "$FULL"; then
    # The reference says country/time only apply with csvType=filtered.
    ok "without csvType=filtered the filters are ignored and the full data comes back" \
        test "$(csv_column "$FULL" Code | sort -u | wc -l | tr -d ' ')" -gt 100
fi
if fetch "$GRAPHER/population.csv?csvType=filtered&time=2020" "$WORK/population-default.csv"; then
    # SKILL.md's first trap: filtered + no country = the chart's default selection.
    ok "csvType=filtered without country= returns the default selection, not all countries" \
        test "$(csv_column "$WORK/population-default.csv" Code | grep -cv '^OWID_')" = "0"
    ok "World is coded OWID_WRL as documented" test -n "$(csv_column "$WORK/population-default.csv" Code | grep -x 'OWID_WRL')"
    note "default selection: $(csv_column "$WORK/population-default.csv" Entity | sort | tr '\n' ' ')"
fi

section "Chart data API: map-default charts need tab= for country filters"
# This is a multi-dimensional chart whose default view is a map. The slug may
# be renamed one day, in which case skip rather than fail: the claim is about
# map-default charts in general, not about this slug.
MDIM="$GRAPHER/religious-composition"
MDIM_PARAMS="indicator=share&religion=any_religion&csvType=filtered&country=USA~GBR&time=2020"
code=$(curl -sS -L --max-time 90 -H 'User-Agent: owid-skills contract tests (tech@ourworldindata.org)' \
    -o "$WORK/mdim-notab.csv" -w '%{http_code}' "$MDIM.csv?$MDIM_PARAMS" 2>/dev/null) || code="000"
if [[ "$code" == "200" ]]; then
    ok "on a map-default chart, country= alone is ignored (many rows come back)" \
        test "$(csv_column "$WORK/mdim-notab.csv" Code | sort -u | wc -l | tr -d ' ')" -gt 10
    if fetch "$MDIM.csv?$MDIM_PARAMS&tab=chart" "$WORK/mdim-tab.csv"; then
        csv_column_set "adding tab=chart makes the country filter apply" "$WORK/mdim-tab.csv" Code "GBR USA"
    fi
    if fetch "$MDIM.metadata.json?indicator=share&religion=any_religion" "$WORK/mdim-metadata.json"; then
        jq_true "multi-dim metadata still has column titles even when chart.title is null" \
            "$WORK/mdim-metadata.json" '[.columns[] | .titleShort] | all(type == "string")'
    fi
else
    skip "map-default chart checks" "$MDIM returned HTTP $code; pick another map-default chart"
fi

section "Chart data API: daily charts, projections, explorers"
if fetch "$GRAPHER/daily-cases-covid-region.csv?csvType=filtered&time=2021-01-01..2021-01-31" "$WORK/daily.csv"; then
    csv_has_columns "the third column is Day rather than Year" "$WORK/daily.csv" day
    csv_column_matches "Day values are YYYY-MM-DD" "$WORK/daily.csv" day '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
fi
# The references say estimates and projections arrive as separate columns, each
# populated only for its own years.
if fetch "$GRAPHER/population-with-un-projections.csv?csvType=filtered&useColumnShortNames=true&country=USA&time=2020..2030" "$WORK/projections.csv"; then
    projected_col=$(head -1 "$WORK/projections.csv" | tr ',' '\n' | grep -i 'projected' | head -1)
    estimates_col=$(head -1 "$WORK/projections.csv" | tr ',' '\n' | grep -i 'estimates' | head -1)
    if [[ -n "$projected_col" && -n "$estimates_col" ]]; then
        _pass "projections and estimates are separate columns"
        ok "no year has both an estimate and a projection" \
            test "$(awk -F, 'NR>1 && $4 != "" && $5 != ""' "$WORK/projections.csv" | wc -l | tr -d ' ')" = "0"
    else
        skip "projection column check" "header no longer has separate estimates/projected columns: $(head -1 "$WORK/projections.csv")"
    fi
fi
EXPLORER_VIEW="$EXPLORER/population-and-demography"
EXPLORER_PARAMS="indicator=Population&Sex=Both+sexes&Age=Total&Projection+scenario=None"
if fetch "$EXPLORER_VIEW.csv?$EXPLORER_PARAMS&csvType=filtered&country=USA&time=2020" "$WORK/explorer.csv"; then
    csv_has_columns "explorer views download as CSV with the same columns" "$WORK/explorer.csv" Entity Code Year
    csv_column_set "explorer country filter is respected" "$WORK/explorer.csv" Code "USA"
fi
http_status "explorer views have metadata too" "$EXPLORER_VIEW.metadata.json?$EXPLORER_PARAMS" 200

section "Chart data API: the other suffixes"
content_type ".png returns an image" "$CHART.png?country=USA~GBR&time=2000..2020" '^image/png'
content_type ".png honours imType=square" "$CHART.png?imType=square&country=USA" '^image/png'
content_type ".svg returns an svg" "$CHART.svg?tab=map&time=2020" '^image/svg'
content_type ".readme.md returns markdown" "$CHART.readme.md" '^text/markdown'
content_type ".zip returns an archive" "$CHART.zip?csvType=filtered&country=USA" '^application/zip'
if fetch "$CHART.config.json" "$WORK/config.json"; then
    has_keys ".config.json is a grapher config with slug and title" "$WORK/config.json" "." slug title
fi

section "Chart data API: documentation drift"
doc_contains "the reference documents the .metadata.json suffix" "$DATA_REF" '\.metadata\.json'
doc_contains "the reference documents the recommended base parameters" "$DATA_REF" 'csvType=filtered&useColumnShortNames=true'
doc_contains "the reference documents the image parameters" "$DATA_REF" '`imType=og`'
doc_contains "the reference documents the map-default trap" "$DATA_REF" 'tab=chart'
skill_md_contains "SKILL.md documents the recommended base parameters" 'csvType=filtered&useColumnShortNames=true'
skill_md_contains "SKILL.md requires the User-Agent header" 'owid-skills/1\.0 \(\+https://github\.com/owid/skills\)'
for ref in "$SEARCH_REF" "$DATA_REF" "$FORMAT_REF" "$EMBED_REF"; do
    doc_contains "$ref uses the same User-Agent string" "$ref" 'owid-skills/1\.0 \(\+https://github\.com/owid/skills\)'
done
doc_contains "the embedding reference carries the iframe snippet" "$EMBED_REF" '<iframe src="https://ourworldindata\.org/grapher/'

# ---------------------------------------------------------------------------
section "Data format: reference series for joins"
# data-format.md hardcodes four chart slugs and claims about their coverage.
# slug|claim|earliest-year-must-be-at-most|latest-year-must-be-at-least
CHARTS=(
    "population|long-run population, 10,000 BCE to present|-10000|2020"
    "population-with-un-projections|UN population, 1950 with projections to 2100|1950|2100"
    "gdp-per-capita-maddison-project-database|long-run GDP per capita from 1820|1820|2018"
    "gdp-per-capita-worldbank|World Bank GDP per capita from 1990|1990|2022"
)
TIMESPANS='
  [ .columns[]
    | select(has("timespan"))
    | .timespan
    | capture("^(?<s>-?[0-9]+)-(?<e>[0-9]+)$")
    | { start: (.s | tonumber), end: (.e | tonumber) } ]
'
for entry in "${CHARTS[@]}"; do
    IFS='|' read -r slug claim min_start min_end <<<"$entry"
    meta="$WORK/$slug.metadata.json"
    if ! fetch "$GRAPHER/$slug.metadata.json" "$meta"; then
        continue
    fi
    starts=$(jq -r "$TIMESPANS | map(.start) | min" "$meta" 2>/dev/null)
    ends=$(jq -r "$TIMESPANS | map(.end) | max" "$meta" 2>/dev/null)
    if [[ -n "$starts" && -n "$ends" && "$starts" != "null" && "$ends" != "null" ]]; then
        note "$slug covers $starts to $ends"
        ok "$slug: coverage starts at or before $min_start ($claim)" test "$starts" -le "$min_start"
        ok "$slug: coverage extends to at least $min_end" test "$ends" -ge "$min_end"
    else
        _fail "$slug: timespans are parseable" "could not parse timespans"
    fi
    doc_contains "data-format.md still references $slug" "$FORMAT_REF" "grapher/$slug"
done

section "Data format: entity codes are joinable"
CO2="$WORK/co2.csv"
POP="$WORK/pop.csv"
JOIN_PARAMS="csvType=filtered&useColumnShortNames=true&country=USA~GBR~CHN&time=2020"
if fetch "$GRAPHER/annual-co2-emissions-per-country.csv?$JOIN_PARAMS" "$CO2" &&
    fetch "$GRAPHER/population.csv?$JOIN_PARAMS" "$POP"; then
    csv_column_set "the emissions file holds the three ISO codes" "$CO2" code "CHN GBR USA"
    csv_column_set "the population file holds the same three ISO codes" "$POP" code "CHN GBR USA"
    csv_column_matches "every code is ISO alpha-3 or an OWID_ code" "$POP" code '^([A-Z]{3}|OWID_[A-Z_0-9]+)$'
fi
doc_contains "data-format.md tells agents to join on Code and Year" "$FORMAT_REF" 'Join on \*\*`Code` and `Year`\*\*'

finish
