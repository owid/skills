---
description: >-
  The shell twin of user-agent-in-python: a one-off command rather than
  library code, which is where a header is easiest to forget.
tags: [behaviour, webfetch-ok, user-agent]
max_turns: 15
timeout_seconds: 300
allowed_tools: [WebFetch, Skill]
expected_outcome: >-
  A curl (or wget) command against co-emissions-per-capita.csv, filtered to
  Germany and France, that sends the owid-skills User-Agent.
---

What's a curl command to download CO2 emissions per capita for Germany and France from Our World in Data as a CSV? I'll run it myself.
