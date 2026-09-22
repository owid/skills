# Entry points for working on this repo.
#
#   Repo conventions and skill layout      -> AGENTS.md
#   How the three eval layers fit together -> evals/README.md

SHELL := /bin/bash
.DEFAULT_GOAL := help
.PHONY: help validate lint test triggers behaviour install clean

# The Agent Skills spec's own reference validator. Pinned to 0.1.x because
# skills-ref is pre-1.0, where a minor bump may change behaviour. Note the
# published package's executable is `agentskills`, not `skills-ref` as the spec
# page still shows.
SKILLS_REF := uvx --quiet --from 'skills-ref>=0.1.1,<0.2' agentskills

# The Agent Plugins manifest schema, fetched over the network, so plugin.json is
# checked against the published spec rather than a copy that can drift.
CHECK_SCHEMA := uvx --quiet --from 'check-jsonschema>=0.33,<0.40' check-jsonschema
PLUGIN_SCHEMA := https://agent-plugins.org/schemas/1.0.0/plugin.schema.json

help: ## List the available targets
	@grep -hE '^[a-z][a-z-]*:.*## ' $(MAKEFILE_LIST) \
	  | awk -F':.*## ' '{printf "  \033[1m%-9s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "  test/triggers take SKILL=<name>, behaviour CASE=<name>, install BRANCH=<name>."
	@echo "  triggers also takes RUNS/MODEL/EFFORT and behaviour RUNS - that is the cost."

validate: ## Check spec conformance, both plugin manifests and marketplace registration
	@# Spec conformance, per skill, using the validator the spec itself recommends.
	@# Agent-agnostic: these skills are also read by Codex, Gemini CLI, Cursor, ...
	@if command -v uv >/dev/null 2>&1; then \
	  fail=0; \
	  for dir in skills/*/; do \
	    $(SKILLS_REF) validate "$${dir%/}" || fail=1; \
	  done; \
	  [ $$fail -eq 0 ] || exit 1; \
	else echo "  ~ uv not found - skipping spec validation"; fi
	@# The marketplace manifest is Claude-specific and outside the spec.
	@if command -v claude >/dev/null 2>&1; then claude plugin validate .; \
	else echo "  ~ claude CLI not found - skipping manifest validation"; fi
	@# plugin.json is what ChatGPT and Codex read, and neither CLI above looks at
	@# it. Its schema forbids unknown keys, so a typo makes the whole package
	@# unreadable rather than degrading - worth catching here.
	@if command -v uv >/dev/null 2>&1; then \
	  $(CHECK_SCHEMA) --schemafile $(PLUGIN_SCHEMA) plugin.json; \
	else echo "  ~ uv not found - skipping plugin.json validation"; fi
	@# Eval files must never be referenced from a SKILL.md. A reference would pull
	@# test prose into the context budget of every user who triggers the skill, and
	@# it is the one way the evals could leak into an agent's context at all.
	@if grep -rnE '(^|[^a-z-])evals?/|triggers\.json|evals\.json|contract\.sh' skills/*/SKILL.md; then \
	  echo "  x a SKILL.md references eval files - drop the reference or inline the content"; \
	  exit 1; \
	else echo "  ok  no SKILL.md references eval files"; fi
	@# Eval JSON is hand-authored and hand-reviewed, so it must stay readable. A
	@# python json.dumps without ensure_ascii=False silently rewrites every em dash
	@# and accent as a \uXXXX escape, which is unreviewable prose.
	@if grep -rln '\\u[0-9a-fA-F]\{4\}' evals/skills/*/*.json 2>/dev/null; then \
	  echo "  x the file(s) above contain escaped unicode - rewrite with ensure_ascii=False"; \
	  exit 1; \
	else echo "  ok  eval json has no escaped unicode"; fi
	@# Registration: none of the validators above knows about marketplace.json, and an
	@# unregistered skill is installable by neither route.
	@fail=0; \
	for dir in skills/*/; do \
	  name=$$(basename "$$dir"); \
	  if ! grep -q "\"./skills/$$name\"" .claude-plugin/marketplace.json; then \
	    echo "  x $$name: not registered in .claude-plugin/marketplace.json"; fail=1; \
	  fi; \
	done; \
	if [ $$fail -eq 0 ]; then \
	  echo "  ok  every skill is registered in the marketplace"; \
	else exit 1; fi

lint: ## Lint the harness: shellcheck for shell, ruff for Python
	@# --external-sources lets shellcheck follow the dynamic `source "$$EVALS_LIB/..."`.
	@if command -v uv >/dev/null 2>&1; then \
	  uvx --quiet --from shellcheck-py shellcheck --severity=warning \
	    --external-sources --source-path=evals/lib \
	    evals/lib/assert.sh evals/skills/*/contract.sh evals/run-contract-tests.sh && \
	  uvx --quiet ruff check --select E,F,W,UP --line-length 130 \
	    evals/run-trigger-eval.py evals/skills/owid-catalog/contract_check.py && \
	  echo "  ok  shell and python lint clean"; \
	else echo "  ~ uv not found - skipping lint"; fi

test: ## Contract tests: do the OWID endpoints still match what the skills document?
	@./evals/run-contract-tests.sh $(SKILL)

triggers: ## Trigger evals: does the right skill fire? (needs the claude CLI, costs tokens)
	@# Cost scales as queries x RUNS x skills. While iterating on a description, pin
	@# SKILL and RUNS=1; use the defaults for a measurement you intend to record.
	@./evals/run-trigger-eval.py $(if $(SKILL),--skill $(SKILL),--all) \
	  $(if $(RUNS),--runs $(RUNS),) $(if $(MODEL),--model $(MODEL),) $(if $(EFFORT),--effort $(EFFORT),)

behaviour: ## Behaviour evals: what does the plugin change about what Claude does? (costs tokens)
	@# Grants are deliberately narrow. WebFetch to ourworldindata.org is all these
	@# cases need, and it is what makes the no-plugin arm a fair comparison: the
	@# baseline can reach the same site, so a positive delta is the skill's doing
	@# and not the tool grant's. Granting Bash would also pull in the OS sandbox,
	@# whose preconditions vary by machine.
	@claude plugin eval . \
	  $(if $(CASE),--case $(CASE),) $(if $(RUNS),--runs $(RUNS),) \
	  --allow-tools "WebFetch(domain:ourworldindata.org)" --no-publish

install: ## Install this repo as a plugin for Codex and the ChatGPT app (BRANCH=<name> to try a branch)
	@command -v codex >/dev/null 2>&1 || { \
	  echo "  x codex CLI not found - install it from https://developers.openai.com/codex"; exit 1; }
	@# `marketplace add` refuses to re-point an existing marketplace at a different
	@# source, which is what a second run with a different BRANCH is. Clearing ours
	@# first makes the target idempotent; both removes are no-ops on a clean machine.
	@codex plugin remove owid@owid-skills >/dev/null 2>&1 || true
	@codex plugin marketplace remove owid-skills >/dev/null 2>&1 || true
	@codex plugin marketplace add owid/skills $(if $(BRANCH),--ref $(BRANCH),)
	@codex plugin add owid@owid-skills
	@echo
	@echo "  Codex is ready - run /plugins in a session to see it."
	@echo "  For the ChatGPT app: turn on Settings > Security and login > Developer mode,"
	@echo "  restart the desktop app, then install Our World in Data from Plugins."
	@echo "  To undo: codex plugin remove owid@owid-skills && codex plugin marketplace remove owid-skills"

clean: ## Delete eval run outputs (evals/results/)
	@rm -rf evals/results
