---
type: tool_order
before: { tool: WebFetch, input_match: '\.metadata\.json' }
after: { tool: WebFetch, input_match: '\.csv' }
arm: with-only
---
