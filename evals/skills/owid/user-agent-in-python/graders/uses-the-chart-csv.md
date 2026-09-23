---
type: regex
# The URL either names the chart outright or builds it from a slug parameter
# whose value is life-expectancy; both are correct answers.
pattern: '(?=[\s\S]*life-expectancy)[\s\S]*ourworldindata\.org/grapher/(life-expectancy|\{\w+\})\.csv'
---
