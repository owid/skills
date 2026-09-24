---
type: llm
---
The user asked for a CSV with only the United States and the United Kingdom for 2020 from a religious-composition chart URL, and how many rows it has.

PASS if the reply reports a result containing only those two countries (two data rows) for 2020, keeping the indicator and religion selection from the URL.
FAIL if the reported result contains other countries, a different year, a different indicator, or if the reply never obtains the data.
