---
type: llm
---
Judge the final reply against this checklist. PASS only if every item that applies is satisfied; FAIL if any applicable item is clearly not met. Quote the part of the reply that decides each item.

- The function loads the CSV URL with csvType=full and useColumnShortNames=true
- Requests set the owid-skills User-Agent
- The docstring explains entity, code (ISO3 and OWID_ codes) and year, from the metadata
- The citation from the metadata is included so pipeline users can credit the source
