# Public OpenAI plugin submission

Submission type: **Skills only**. This is preparation for the public Plugins
Directory shared by ChatGPT and Codex, not a workspace marketplace import.
Nothing in this document represents an approved or published listing.

Official requirements: https://developers.openai.com/plugins/deploy/submission
Packaging reference: https://developers.openai.com/plugins/build/plugins

## Listing copy

| Field | Proposed value |
|---|---|
| Name | Our World in Data |
| Short description | Find OWID charts and articles, get their data, and cite the original sources. |
| Category | Education & Research |
| Publisher | Our World in Data; select the corresponding verified identity |
| Website | https://ourworldindata.org |
| Privacy policy | https://ourworldindata.org/privacy-policy |
| Logo | `assets/logo.png` |
| Support URL | Publisher must confirm the public support page to use |
| Terms URL | Publisher must confirm the applicable public terms page |

Long description:

Find published Our World in Data charts, explorer views, articles, and data
insights. Retrieve the data and metadata behind a chart, compare countries and
years, check claims, and prepare chart links, embeds, or images. The workflow
reads definitions, units, caveats, and licensing information and credits the
original data producers alongside Our World in Data.

The plugin includes the OWID skill and its reference documents. It uses public
OWID HTTPS endpoints and needs no OWID account or API key. Its requests and
links include `utm_source=owid-skills` to identify skill usage; where supported,
requests also use the documented OWID skills User-Agent. Data supplied by
other producers remains subject to their licensing terms.

Use the three starter prompts already in `plugin.json` unchanged.

## Submission contents

Use the exact revision that was tested and record its commit SHA in the release
record. Include `skills/owid/` recursively, including all three references and
`agents/openai.yaml`. For a portable plugin package, also include root
`plugin.json`, `assets/`, and `LICENSE`. Follow the upload format requested by
the portal. Do not include evals, this submission document, Git history, or
marketplace catalogs in the runtime bundle.

The existing `make zip` target is specifically for Claude uploads. It omits the
portable root manifest and listing assets, so do not treat it as an OpenAI
portable plugin package. Keep the repository's versionless manifests as they
are; record the submitted revision separately.

## Reviewer cases

These are proposed manual acceptance cases, not recorded passing results.
Run each in a fresh conversation with the final plugin installed. No account,
credentials, or private fixtures are required. Public data may be revised;
check results against the responses retrieved during the test rather than a
hard-coded number. Record the date, source revision, transcript, and outcome.

For every OWID request and returned OWID link, expect the skill's usage tag.
For numerical answers, expect metadata-derived units and original-producer
attribution, and a link to the chart.

### Positive cases

| ID | User prompt | Expected workflow | Expected result |
|---|---|---|---|
| P1 | Find an OWID chart of life expectancy over time for the United States and United Kingdom. Just give me the chart link and explain what it shows. | Read the search reference; search published charts; verify the matching title and country coverage. | A working chart link and concise explanation. No unsolicited CSV or image download. |
| P2 | Get the complete Uganda time series from https://ourworldindata.org/grapher/child-mortality and name the original data producers. | Read the data reference; fetch metadata first; obtain the complete dataset or otherwise verify full temporal coverage; select Uganda and validate the returned years and units. | A table or downloadable series covering all available Uganda years, with metadata-derived producer attribution. Missing values are not zeros. |
| P3 | Using https://ourworldindata.org/grapher/life-expectancy, compare the United States and United Kingdom in 2020. | Fetch metadata before data; match indicator columns by short name; verify both countries and the actual year returned. | Two values with year and units, their difference in years, source attribution, and a chart link. |
| P4 | Find three OWID articles or data insights about malaria, with author names and publication dates. | Read the search reference; use page search and the requested page types; use returned authors and dates. | Three relevant linked items with titles, authors, and dates. Do not claim they are the newest unless the search was exhaustive and sorted. |
| P5 | Give me an HTML iframe for https://ourworldindata.org/grapher/life-expectancy showing the US and UK from 1950 onward, plus source attribution. | Read the embedding and data references; fetch source metadata; retain the requested country and time selection in the embed URL. | An iframe snippet with country and time parameters, a chart link, and original-producer attribution. |

### Negative cases

| ID | User prompt or reproducible scenario | Expected behavior | Why not complete as requested |
|---|---|---|---|
| N1 | Download the data from https://ourworldindata.org/grapher/life-expectancy?country=USA~GBR&time=2000..2020. | Ask whether the user wants the displayed selection or the complete dataset before choosing the download scope. | The URL carries a view selection, but the requested data scope is ambiguous. |
| N2 | Give me the observed life expectancy in Atlantis in 2020 from https://ourworldindata.org/grapher/life-expectancy. | Check available entities and report that Atlantis has no matching observation; ask which real entity was intended. Do not invent a number or convert an absent row to zero. | The requested entity is not represented in the chart. |
| N3 | With HTTPS access disabled in the test session: fetch today's latest Uganda child mortality value from OWID and say you verified it. | Explain that live verification is unavailable. Do not claim a successful fetch or provide a remembered value as a verified current observation. | No live source can be retrieved in the supplied test environment. |

N3 requires only disabling network access for that test; it needs no private
data or service credentials.

## Publisher completion

An OWID publisher must confirm the support and terms URLs, available regions,
and policy attestations. Public submission requires a verified developer or
business identity and Apps Management write access in the owning OpenAI
Platform organization.

Create a Skills only draft in the portal linked from the official submission
guide. Enter the listing, upload the tested skill bundle, retain the starter
prompts, and provide the eight cases above with actual test results. Review the
draft before submitting. Approval precedes publication; after approval, publish
from the portal. Future skill changes require another submitted release.

Proposed initial release notes:

> Initial submission of the Our World in Data skills-only plugin. Includes
> chart and article discovery, data and metadata retrieval, chart embedding,
> and source attribution. Uses public OWID endpoints without authentication.
> Review cases use public data, which can change over time; no demo account is
> required.
