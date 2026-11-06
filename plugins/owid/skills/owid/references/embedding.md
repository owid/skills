# Embedding a chart

How to show an OWID chart inside something you are producing: an HTML page, a
slide deck, a document, a notebook, or a chat artifact.

**First check that is what was asked for.** "Get me a chart on child mortality"
usually wants the chart, not a file — find it, say what it shows, and give the
link. Produce an image only when the user names where it is going (slides, a
document, a page, an artifact, an email) or asks for one in so many words (an
image, a PNG/SVG, a picture, a screenshot). Otherwise hand over the link and offer
the image.

## Which form to use

| Output | Use | Why |
|---|---|---|
| An HTML file or web page the user will open in a browser | Interactive iframe | Readers get the live chart: hover values, country picker, download button, source line. |
| A chat artifact or sandboxed preview | PNG, with a link to the chart | The surface may block third-party iframes, and a blank box is worse than an image. Use the iframe only where you know it renders. |
| Slides, Word/Google Docs, PDF, Markdown, email | PNG (or SVG for print), with a link | No iframes there. |

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

## Static image

Fetch these however suits your project.

```
# The view you analysed, at the default size
https://ourworldindata.org/grapher/life-expectancy.png?tab=line&country=USA~GBR&time=1950..latest

# Vector, for print or a design tool
https://ourworldindata.org/grapher/life-expectancy.svg?tab=map&time=2020
```

A PNG comes back at 850×600 unless you ask for something else. To fit a
particular space:

| Parameter | Effect |
|---|---|
| `imWidth` | Width in pixels. Give it alone and the height follows the default proportions; give both and you get that box, portrait included. |
| `imHeight` | Height in pixels, likewise. |
| `imSquareSize` | Side length for a square image, with `imType=square`. |

Sizes are capped: ask for more than 4250×3000 and you silently get 4250×3000 back.

```
# Sized for a 16:9 slide
https://ourworldindata.org/grapher/life-expectancy.png?tab=line&country=USA~GBR&imWidth=1600&imHeight=900

# Square, 1200 across
https://ourworldindata.org/grapher/life-expectancy.png?imType=square&imSquareSize=1200
```

The image endpoints take the same view parameters as the CSV, so the picture
matches the numbers you analysed. See [data-api.md](data-api.md).

## Attribution

An embedded or pasted OWID chart already carries its own title, source line and
logo, so the image is self-attributing. What it does not do is put the source
into your text, so still name the original data producer in the caption or the
surrounding prose, and link to the chart. How to build that line, and why the
producer rather than OWID is the part that matters, is in
[data-api.md](data-api.md).
