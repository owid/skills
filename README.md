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

The quickest way is to ask your AI assistant: *"Install the OWID skill hosted at
https://github.com/owid/skills/"*. Claude Code and Codex can do it themselves; in
the Claude and ChatGPT apps, your assistant can walk you through the current menus.

What each app needs:

| Your app | How |
|---|---|
| Claude app (paid plan) | In the plugin settings, add a marketplace from `owid/skills`, then install **Our World in Data** |
| ChatGPT app | In the plugin settings, add a marketplace from `owid/skills`, then install **Our World in Data** |
| Claude Code | `/plugin marketplace add owid/skills`, then `/plugin install owid@owid-skills` |
| Codex | `codex plugin marketplace add owid/skills`, then `codex plugin add owid@owid-skills` |
| Anything else | `npx skills add owid/skills`, or copy the [`skills/owid/`](skills/owid/) folder into your agent's skills directory |

None of them needs an Our World in Data account or a GitHub account. Start a new
chat afterwards: plugins only apply to conversations that begin after installing.

**Check it worked.** In a new chat, ask:

> Use the Our World in Data skill to fetch the data behind this chart:
> https://ourworldindata.org/grapher/child-mortality — the complete time series
> for Uganda, and the source the chart relies on.

A working install returns the whole series for Uganda (about seventy yearly
figures, starting in the 1950s) and names **Gapminder and the UN Inter-agency
Group for Child Mortality Estimation** as the source, not "Our World in Data". An
assistant without the skill will say so; one that has it but didn't fetch anything
will summarise or invent the numbers. If that happens, see the [FAQ](FAQ.md).

**Updating.** There are no version numbers: we change the skill in place. Update it
where you installed it: reinstall it in the apps, run `claude plugin update
owid@owid-skills` in Claude Code (or turn on auto-update for the `owid-skills`
marketplace in `/plugin`), `codex plugin marketplace upgrade owid-skills` in Codex,
or `npx skills update` for the `skills` CLI.

## License

[Apache-2.0](LICENSE)
