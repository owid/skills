---
description: >-
  Asks for code that downloads OWID data, pasted into the reply so no Write
  grant is needed. The skill says every request carries the owid-skills
  User-Agent, which is how OWID counts usage through the skill. The baseline
  cannot know that string, so the header grader measures the skill alone.
tags: [behaviour, webfetch-ok, user-agent]
max_turns: 15
timeout_seconds: 300
allowed_tools: [WebFetch, Skill]
expected_outcome: >-
  A Python function that reads life-expectancy.csv from the grapher and sends
  User-Agent: owid-skills/1.0 (+https://github.com/owid/skills).
---

Write me a short Python function that downloads the life expectancy data behind Our World in Data's life expectancy chart into a pandas DataFrame. Just paste the code in your reply, I'll drop it into my project.
