---
type: llm
---
The user gave a chart URL whose parameters select "total number of people affected by natural disasters, annual, all disaster types" and asked for the World data over the last ten years.

PASS if the reply gives World figures for roughly the last ten years for the number of people affected (not deaths, not economic damage), with the unit and the years, and names EM-DAT as the original producer.
FAIL if the figures are for a different indicator than the URL selects, are not for the World, lack years, or no producer is named.
