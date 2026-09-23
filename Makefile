# Entry points for working on this repo.
#
#   Repo conventions and skill layout      -> AGENTS.md
#   How the three eval layers fit together -> evals/README.md

SHELL := /bin/bash
.DEFAULT_GOAL := help
.PHONY: help validate lint test triggers behaviour install zip clean

# The Agent Skills spec's own reference validator. Pinned to 0.1.x because
# skills-ref is pre-1.0, where a minor bump may change behaviour. Note the
# published package's executable is `agentskills`, not `skills-ref` as the spec
# page still shows.
SKILLS_REF := uvx --quiet --from 'skills-ref>=0.1.1,<0.2' agentskills

# The Agent Plugins manifest schema, fetched over the network, so plugin.json is
# checked against the published spec rather than a copy that can drift.
CHECK_SCHEMA := uvx --quiet --from 'check-jsonschema>=0.33,<0.40' check-jsonschema
PLUGIN_SCHEMA := https://agent-plugins.org/schemas/1.0.0/plugin.schema.json

# `make install` installs this worktree. BRANCH=<ref> installs from GitHub
# instead, for the Codex half - to check what is actually published, or if the
# ChatGPT app does not list a local source.

# Where `make zip` writes the archive the Claude app uploads. Downloads by
# default, because that dialog is a file picker.
ZIP ?= $(HOME)/Downloads/owid-plugin.zip

help: ## List the available targets
	@grep -hE '^[a-z][a-z-]*:.*## ' $(MAKEFILE_LIST) \
	  | awk -F':.*## ' '{printf "  \033[1m%-9s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "  test/triggers take SKILL=<name>, behaviour CASE=<name>, install BRANCH=<ref>, zip ZIP=<path>."
	@echo "  install and zip both package this worktree; BRANCH= makes install resolve from GitHub."
	@echo "  triggers also takes RUNS/MODEL/EFFORT and behaviour RUNS/JOBS - RUNS is the cost, JOBS the wall clock."

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
	@# Eval files must never be referenced from a skill (SKILL.md or anything under
	@# references/). A reference would pull test prose into the context budget of
	@# every user who triggers the skill, and it is the one way the evals could
	@# leak into an agent's context at all.
	@if grep -rnE '(^|[^a-z-])evals?/|triggers\.json|evals\.json|contract\.sh' skills/ --include='*.md'; then \
	  echo "  x a skill file references eval files - drop the reference or inline the content"; \
	  exit 1; \
	else echo "  ok  no skill file references eval files"; fi
	@# Every markdown link inside a skill must resolve to a file that ships with it,
	@# otherwise the agent is told to read a reference that does not exist.
	@fail=0; \
	for dir in skills/*/; do \
	  for f in $$(find "$$dir" -name '*.md'); do \
	    for link in $$(grep -oE '\]\(([^)#:]+)(#[^)]*)?\)' "$$f" | sed -E 's/^\]\(([^)#]+).*$$/\1/'); do \
	      case "$$link" in http*|mailto*) continue ;; esac; \
	      if [ ! -e "$$(dirname "$$f")/$$link" ]; then \
	        echo "  x $$f links to $$link, which does not exist"; fail=1; \
	      fi; \
	    done; \
	  done; \
	done; \
	if [ $$fail -eq 0 ]; then echo "  ok  every relative link inside skills/ resolves"; else exit 1; fi
	@# `strict: false` makes the marketplace entry the whole definition, which
	@# conflicts with the plugin.json that ships beside it: Claude Code then refuses
	@# to load the plugin at install time. Neither validator above catches it.
	@if grep -q '"strict": *false' .claude-plugin/marketplace.json; then \
	  echo "  x marketplace.json sets strict: false, which conflicts with plugin.json - drop the field"; \
	  exit 1; \
	else echo "  ok  no marketplace entry overrides plugin.json"; fi
	@# The ChatGPT and Codex listing falls back to a generic icon when an interface
	@# asset path does not resolve, which looks exactly like never having set one.
	@fail=0; \
	for path in $$(grep -oE '"\./assets/[^"]+"' plugin.json | tr -d '"'); do \
	  if [ ! -e "$$path" ]; then echo "  x plugin.json references $$path, which does not exist"; fail=1; fi; \
	done; \
	if [ $$fail -eq 0 ]; then echo "  ok  plugin.json asset paths resolve"; else exit 1; fi
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
	    evals/run-trigger-eval.py && \
	  echo "  ok  shell and python lint clean"; \
	else echo "  ~ uv not found - skipping lint"; fi

test: ## Contract tests: do the OWID endpoints still match what the skills document?
	@./evals/run-contract-tests.sh $(SKILL)

triggers: ## Trigger evals: does the right skill fire? (needs the claude CLI, costs tokens)
	@# Cost scales as queries x RUNS x skills. While iterating on a description, pin
	@# SKILL and RUNS=1; use the defaults for a measurement you intend to record.
	@./evals/run-trigger-eval.py $(if $(SKILL),--skill $(SKILL),--all) \
	  $(if $(RUNS),--runs $(RUNS),) $(if $(MODEL),--model $(MODEL),) $(if $(EFFORT),--effort $(EFFORT),)

JOBS ?= 4

behaviour: ## Behaviour evals: what does the plugin change about what Claude does? (costs tokens)
	@# Grants are deliberately narrow. WebFetch to ourworldindata.org is all these
	@# cases need, and it is what makes the no-plugin arm a fair comparison: the
	@# baseline can reach the same site, so a positive delta is the skill's doing
	@# and not the tool grant's. Granting Bash would also pull in the OS sandbox,
	@# whose preconditions vary by machine.
	@# JUDGE=sonnet swaps the default small judge for a stronger one when an llm
	@# grader keeps failing an answer that reads as correct.
	@# Runs are independent claude sessions, so they parallelise; the CLI allows
	@# 1-8, and all of them share your rate limit. JOBS=1 if it starts throttling.
	@# --keep-temp keeps each run's trace.jsonl (its tool calls and final reply) at
	@# the tracePath in aggregate-result.json. The HTML report shows only verdicts,
	@# and reading why a grader failed needs the reply it failed on.
	@claude plugin eval . -j $(JOBS) \
	  $(if $(CASE),--case $(CASE),) $(if $(TAG),--tag $(TAG),) $(if $(RUNS),--runs $(RUNS),) \
	  $(if $(JUDGE),--judge-model $(JUDGE),) $(if $(MODEL),--model $(MODEL),) \
	  --allow-tools "WebFetch(domain:ourworldindata.org)" --keep-temp --no-publish

install: ## Install this worktree as a plugin for Claude Code, Codex and the ChatGPT app
	@# Both CLIs read a local marketplace live, so both halves get this worktree,
	@# uncommitted edits included, and neither needs the branch pushed. That is the
	@# only way to try a branch at all: `claude plugin marketplace add` takes no
	@# ref, and for the ChatGPT app a local marketplace is what stands in for one.
	@if command -v claude >/dev/null 2>&1; then \
	  claude plugin marketplace remove owid-skills >/dev/null 2>&1 || true; \
	  claude plugin marketplace add "$(CURDIR)" >/dev/null && \
	  claude plugin install owid@owid-skills >/dev/null && \
	  echo "  ok  Claude Code: owid@owid-skills -> $(CURDIR)"; \
	else echo "  ~ claude CLI not found - skipping Claude Code"; fi
	@# BRANCH=<ref> swaps this half to GitHub, where a ref that was never pushed -
	@# or a typo - would otherwise install something else without saying so.
	@if ! command -v codex >/dev/null 2>&1; then \
	  echo "  ~ codex CLI not found - skipping Codex and the ChatGPT app"; \
	  echo "      install it from https://developers.openai.com/codex"; \
	else \
	  if [ -n "$(BRANCH)" ]; then \
	    git ls-remote --exit-code --heads origin "$(BRANCH)" >/dev/null 2>&1 || { \
	      echo "  x origin has no branch $(BRANCH) - push it first"; exit 1; }; \
	    src="owid/skills at $(BRANCH)"; \
	  else src="$(CURDIR)"; fi; \
	  codex plugin remove owid@owid-skills >/dev/null 2>&1 || true; \
	  codex plugin marketplace remove owid-skills >/dev/null 2>&1 || true; \
	  codex plugin marketplace add $(if $(BRANCH),owid/skills --ref $(BRANCH),"$(CURDIR)") >/dev/null && \
	  codex plugin add owid@owid-skills >/dev/null && \
	  echo "  ok  Codex: owid@owid-skills -> $$src"; \
	fi
	@echo
	@echo "  Claude Code picks it up in the next session - /plugin shows it."
	@echo "  For the ChatGPT app: turn on Settings > Security and login > Developer mode,"
	@echo "  restart the desktop app, then install Our World in Data from Plugins."
	@echo "  To undo: claude plugin marketplace remove owid-skills"
	@echo "           codex plugin remove owid@owid-skills && codex plugin marketplace remove owid-skills"

zip: ## Package the plugin as an archive the Claude app can upload (ZIP=<path>)
	@# The app's "Upload a plugin" wants an archive with .claude-plugin/plugin.json
	@# at its root. The rest of this repo serves the other install routes: the Agent
	@# Plugins manifest is ChatGPT's, and a marketplace entry beside plugin.json is
	@# what makes Claude Code refuse to load the plugin - so ship neither.
	@# This is a snapshot of the worktree, which is the point: uploading is the only
	@# way to try a branch in the Claude app, whose marketplaces serve main.
	@stage=$$(mktemp -d) && \
	  mkdir -p "$$stage/.claude-plugin" "$$(dirname "$(ZIP)")" && \
	  cp .claude-plugin/plugin.json "$$stage/.claude-plugin/" && \
	  cp -R skills "$$stage/skills" && \
	  rm -f "$(ZIP)" && \
	  (cd "$$stage" && zip -qr "$(ZIP)" . -x '*.DS_Store') && \
	  rm -rf "$$stage" && \
	  echo "  ok  $(ZIP)" && \
	  echo "      Customize > Plugins > + > Upload a plugin. Turn the installed owid" && \
	  echo "      plugin off first, or both answer the same prompts."

clean: ## Delete eval run outputs (evals/results/)
	@rm -rf evals/results
