# Embedding a chart

How to show an OWID chart inside something you are producing: an HTML page, a
slide deck, a document, a notebook, or a chat artifact.

## Which form to use

| Output | Use | Why |
|---|---|---|
| An HTML file or web page the user will open in a browser | Interactive iframe | Readers get the live chart: hover values, country picker, download button, source line. |
| A chat artifact or sandboxed preview | PNG, with a link to the chart | Most chat surfaces block third-party iframes; a blank box is worse than an image. Try the iframe only if the surface is known to allow it. |
| Slides, Word/Google Docs, PDF, Markdown, email | PNG (or SVG for print), with a link | No iframes there. |
| A notebook or your own plot | The CSV, plotted yourself | You control the design; cite the source in the figure. |

In every case link to the chart URL (with its view parameters) so the reader can
reach the interactive version and the full source information.

## Interactive iframe

This is the snippet OWID's own "Embed" button produces:

```html
<iframe src="https://ourworldindata.org/grapher/life-expectancy?tab=line&country=USA~GBR&time=1950..latest"
        loading="lazy"
        style="width: 100%; height: 600px; border: 0px none;"
        allow="web-share; clipboard-write"></iframe>
```

- Set the view in the `src` query string: `tab=` (see the tab table in
  [search-api.md](search-api.md)), `country=`, `time=`, and on multi-dimensional
  charts or explorers their dimension parameters. Explorer views embed at
  `https://ourworldindata.org/explorers/<slug>?<params>`.
- 600 px tall suits most charts; maps and charts with many entities read better
  at 700–800 px. Width should be 100% of a container at least 600 px wide.
- The embedded chart shows its own title, subtitle, source line and OWID logo,
  so it is self-attributing.

## Static image

```bash
UA="owid-skills/1.0 (+https://github.com/owid/skills)"
URL="https://ourworldindata.org/grapher/life-expectancy"

# Default layout, exactly the view you analysed
curl -sA "$UA" -o chart.png "$URL.png?tab=line&country=USA~GBR&time=1950..latest"

# Sized for a 16:9 slide
curl -sA "$UA" -o slide.png "$URL.png?tab=line&country=USA~GBR&imWidth=1600&imHeight=900"

# Social-card and square variants
curl -sA "$UA" -o card.png   "$URL.png?imType=og"
curl -sA "$UA" -o square.png "$URL.png?imType=square&imSquareSize=1200"

# Vector, for print or a design tool
curl -sA "$UA" -o chart.svg "$URL.svg?tab=map&time=2020"
```

Image parameters are listed in [chart-data-api.md](chart-data-api.md#images-png-and-svg).
In Markdown or HTML you can also reference the PNG URL directly instead of
downloading it: `![Life expectancy](https://ourworldindata.org/grapher/life-expectancy.png?country=USA~GBR)`.
Downloading is better when the output must not change if the chart is updated.

## Attribution

An embedded or pasted OWID chart already displays "Data source: ..." and the
OWID logo. Still, in the surrounding text or caption:

- Name the original data producer from the metadata `citationShort`
  (e.g. "Source: UN World Population Prospects (2024), via Our World in Data").
- Link to the chart page.
- If you re-plotted the data yourself, add the same source line to your figure;
  the OWID licence is CC BY and the underlying producers each have their own
  terms, which the `.readme.md` for the chart spells out.

## Reproducing the chart yourself

Fetch the CSV (see [chart-data-api.md](chart-data-api.md)) and plot it. Mirror
OWID's practices where it helps the reader: title says what is measured,
subtitle says the unit and definition, source line names the producer, and the
axis starts at zero for counts and rates. Never read values off the PNG; use
the CSV.
