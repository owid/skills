---
description: >-
  A factual question that needs the data fetched. The skill says to tag every
  ourworldindata.org URL with utm_source=owid-skills, including the ones the
  agent fetches itself; WebFetch cannot set a User-Agent, so the tag is the
  only way these requests can be attributed to the skill.
tags: [behaviour, webfetch-ok, usage-tag]
max_turns: 15
timeout_seconds: 300
allowed_tools: [WebFetch, Skill, Read, Glob, Grep]
expected_outcome: >-
  Every WebFetch to ourworldindata.org carries utm_source=owid-skills, and so
  does every ourworldindata.org link in the reply.
---

What was life expectancy in Japan in 1950, and what is it in the latest year Our World in Data has?
