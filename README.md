# AI skill for Our World in Data

**An agent skill for working with [Our World in Data](https://ourworldindata.org).** It teaches your AI assistant to find our charts and articles, pull the numbers behind them, put a chart into a page or a slide, and credit whoever produced the data.

It works with the Claude and ChatGPT apps, Claude Code, Codex, Gemini CLI, Cursor, GitHub Copilot and others.

Our World in Data publishes thousands of charts and hundreds of articles on global problems: poverty, health, energy, climate, education, and more. This skill teaches assistants how to use that content properly: how to find the right chart, how to get the numbers behind it, what the data does and does not mean, and how to credit the people who collected it.

## What you can do

Once installed, you can ask your agent things like:

- *"Find the OWID chart on child mortality and give me the URL with the map open."*
- *"Get life expectancy data for the US and UK since 1950 and plot the trend."*
- *"Someone claims 5 million children under five die every year. Is that consistent with Our World in Data?"*
- *"Convert my CSV of forest area per country into forest area per person using OWID population."*
- *"What has Hannah Ritchie written on OWID recently?"*
- *"Embed the CO₂ per capita chart in this HTML page, or give me a PNG for the slides."*
- *"Where does the data in this chart come from and how was it processed?"*

Most of the time you don't have to ask for it by name — your assistant reaches for
it on its own when your question is about our charts or data.

## What's in it

The skill is a short set of notes your assistant reads when it needs them: how to
search our site, how to fetch the data and sources behind a chart, and how to put
a chart into a page or a slide. You can read them in
[`skills/owid/`](skills/owid/) if you're curious.

It runs no code of its own and needs no API key or account. Your assistant reads
public pages and data files on ourworldindata.org, and nothing else.

## Using the data

Our World in Data's own work is free to reuse under the [Creative Commons BY licence](https://ourworldindata.org/faqs#can-i-reuse-or-republish-your-data). Most of the data, though, comes from other producers and keeps whatever licence they set, so check before you republish — and a few charts cannot be downloaded at all. The skill instructs agents to name the original producer, so please keep the citations when you publish results.

Every request the skill makes identifies itself as coming from this skill, which is how we can see it being used and keep supporting it. That is why links it gives you end in `utm_source=owid-skills`; the [FAQ](FAQ.md#does-our-world-in-data-see-what-i-ask) explains.

## Installation

The quickest way is to ask your AI assistant to do it. Send it this:

> Install the OWID skill hosted at https://github.com/owid/skills/

Claude Code and Codex can carry that out themselves. The Claude and ChatGPT apps
will read [INSTALL.md](INSTALL.md) and walk you through it.

To do it by hand:

| Your app | How you install it |
|---|---|
| [Claude app](INSTALL.md#claude-app-web-and-desktop) | in the app, in a few clicks |
| [ChatGPT app](INSTALL.md#chatgpt-app) | in the app, in a few clicks |
| [Claude Code](INSTALL.md#claude-code) | two commands, at Claude Code's own prompt |
| [Codex](INSTALL.md#codex) | two commands, in a terminal |
| [Anything else](INSTALL.md#other-agents-gemini-cli-cursor-copilot-) | one command in a terminal |

None of them needs an Our World in Data account, and nothing on our side costs
anything. [INSTALL.md](INSTALL.md) also covers how to
[check it worked](INSTALL.md#check-it-worked) and how to
[keep it up to date](INSTALL.md#keeping-the-skill-up-to-date); the [FAQ](FAQ.md)
covers what to do when it doesn't behave.

## License

[Apache-2.0](LICENSE)
