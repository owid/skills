---
name: "owid"
description: "Agent skills for working with Our World in Data: search published charts, explorers and articles, fetch the data and metadata behind them, embed charts, and cite the original sources. Use whenever a task mentions Our World in Data, OWID, ourworldindata.org or a grapher URL, or asks for cross-country data on global problems (population, health and causes of death, energy, CO2 and climate, poverty and GDP, education, democracy, war, food, and more): finding a chart or article, fetching or plotting the data behind a chart, fact-checking a claim or answering a factual question against OWID data, embedding a chart or its PNG in HTML, slides or an artifact, or explaining what a chart shows and where its data comes from. No API key."
---

Our World in Data (OWID) publishes thousands of interactive charts and hundreds
of articles on global problems. Everything is free to reuse under CC BY, and
everything this skill does is an ordinary URL over HTTPS with no API key.

This file only says which reference to read. Each one documents its endpoint in
full: every parameter, what comes back, and what fails silently. Read the one
you need before making a kind of request you have not made yet in this session,
rather than guessing from the table below.

| What you are doing | Read |
|---|---|
| Finding a chart, explorer, article or data insight | [references/search-api.md](references/search-api.md) |
| Getting the numbers behind a chart, understanding what they mean, or checking a claim against them | [references/data-api.md](references/data-api.md) |
| Putting a chart into a page, a document, slides or an artifact | [references/embedding.md](references/embedding.md) |

Everything here is public. If a request needs a login, you are on the wrong URL.
