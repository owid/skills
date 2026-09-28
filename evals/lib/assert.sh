#!/usr/bin/env bash
# Assertion helpers for skill contract tests (see ../README.md, layer 1).
#
# Contract tests check that the endpoints and response shapes a SKILL.md
# documents still match what the API actually returns. No model in the loop, so
# they are cheap and deterministic enough to run on every PR and nightly.
#
# Source this from evals/skills/<skill-name>/contract.sh:
#
#   source "$EVALS_LIB/assert.sh"
#
# The runner exports EVALS_LIB, EVAL_DIR, SKILL_DIR, SKILL_NAME and WORK before
# invoking each contract.sh. When running a contract.sh directly, they are
# derived below from its own location: evals/skills/<skill-name>/contract.sh.

# Deliberately no `set -e`: one failing check must not abort the remaining ones.
set -uo pipefail

: "${EVAL_DIR:="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"}"
: "${SKILL_NAME:="$(basename "$EVAL_DIR")"}"
REPO_ROOT="$(cd "$EVAL_DIR/../../.." && pwd)"
: "${SKILL_DIR:="$REPO_ROOT/skills/$SKILL_NAME"}"
: "${WORK:="$REPO_ROOT/evals/results/contract/$SKILL_NAME"}"
SKILL_MD="$SKILL_DIR/SKILL.md"
mkdir -p "$WORK"

_PASS=0
_FAIL=0
_SKIP=0
_FAILURES=()

_pass() {
    _PASS=$((_PASS + 1))
    printf '  \033[32m✓\033[0m %s\n' "$1"
}

_fail() {
    _FAIL=$((_FAIL + 1))
    _FAILURES+=("$1${2:+ — $2}")
    printf '  \033[31m✗\033[0m %s\n' "$1"
    [[ -n "${2:-}" ]] && printf '      %s\n' "$2"
    return 0
}

# skip <name> <reason> — record a check that could not run (e.g. missing tool).
skip() {
    _SKIP=$((_SKIP + 1))
    printf '  \033[33m∼\033[0m %s (skipped: %s)\n' "$1" "$2"
}

# note <text> — informational output, not a check. Use to surface values a
# reviewer may want to eyeball (a timespan, a row count).
note() {
    printf '    \033[2m%s\033[0m\n' "$1"
}

# section <text> — group heading.
section() {
    printf '\n  \033[1m%s\033[0m\n' "$1"
}

# fetch <url> <outfile> — GET the url, assert HTTP 200, save the body.
# Returns non-zero on failure so callers can guard dependent checks:
#   if fetch "$url" "$WORK/x.json"; then jq_true ... ; fi
fetch() {
    local url="$1" out="$2" code
    code=$(curl -sS -L --retry 3 --retry-delay 2 --max-time 90 \
        -H 'User-Agent: owid-skills contract tests (tech@ourworldindata.org)' \
        -o "$out" -w '%{http_code}' "$url" 2>"$WORK/curl.err") || code="000"
    if [[ "$code" == "200" ]]; then
        _pass "GET $url → 200"
        return 0
    fi
    _fail "GET $url → 200" "got HTTP $code$([[ -s $WORK/curl.err ]] && printf ' (%s)' "$(tr -d '\n' <"$WORK/curl.err")")"
    return 1
}

# ok <name> <cmd...> — the command exits 0.
ok() {
    local name="$1"
    shift
    local out
    if out=$("$@" 2>&1); then
        _pass "$name"
    else
        _fail "$name" "${out:-command exited $?}"
    fi
}

# jq_true <name> <file> <filter> — the jq filter evaluates to true.
jq_true() {
    local name="$1" file="$2" filter="$3" result
    result=$(jq -r "$filter" "$file" 2>&1)
    if [[ "$result" == "true" ]]; then
        _pass "$name"
    else
        _fail "$name" "jq '$filter' → ${result:-<empty>}"
    fi
}

# jq_eq <name> <file> <filter> <expected> — the jq filter equals expected.
jq_eq() {
    local name="$1" file="$2" filter="$3" expected="$4" actual
    actual=$(jq -r "$filter" "$file" 2>&1)
    if [[ "$actual" == "$expected" ]]; then
        _pass "$name"
    else
        _fail "$name" "expected '$expected', got '${actual:-<empty>}'"
    fi
}

# jq_type <name> <file> <filter> <type> — the value at filter has this jq type
# (string, number, boolean, array, object, null).
jq_type() {
    local name="$1" file="$2" filter="$3" expected="$4" actual
    actual=$(jq -r "($filter) | type" "$file" 2>&1)
    if [[ "$actual" == "$expected" ]]; then
        _pass "$name"
    else
        _fail "$name" "expected type '$expected', got '${actual:-<empty>}'"
    fi
}

# has_keys <name> <file> <filter> <key>... — the object at filter has all keys.
has_keys() {
    local name="$1" file="$2" filter="$3"
    shift 3
    local missing=()
    for key in "$@"; do
        if [[ "$(jq -r "($filter) | has(\"$key\")" "$file" 2>&1)" != "true" ]]; then
            missing+=("$key")
        fi
    done
    if [[ ${#missing[@]} -eq 0 ]]; then
        _pass "$name"
    else
        _fail "$name" "missing key(s): ${missing[*]}"
    fi
}

# --- collection assertions -------------------------------------------------
#
# These take a jq *selector* (which elements) and a jq *predicate* (what must be
# true of each), instead of one filter that fuses both. That keeps quoting sane
# and, more importantly, lets the helper insist the selector actually matched
# something: jq's `all` is true of an empty array, so a fused filter silently
# passes when the sample happens to contain none of the thing being described.

# all_match <name> <file> <selector> <predicate> — every selected element
# satisfies the predicate. Skips loudly if the selector matches nothing.
all_match() {
    local name="$1" file="$2" selector="$3" predicate="$4" count bad
    count=$(jq -r "[$selector] | length" "$file" 2>&1)
    if [[ ! "$count" =~ ^[0-9]+$ ]]; then
        _fail "$name" "selector '$selector' failed: $count"
        return
    fi
    if [[ "$count" -eq 0 ]]; then
        skip "$name" "the sample contains no elements matching '$selector'"
        return
    fi
    bad=$(jq -r "[$selector | select(($predicate) | not)] | length" "$file" 2>&1)
    if [[ "$bad" == "0" ]]; then
        _pass "$name"
    else
        _fail "$name" "$bad of $count element(s) fail '$predicate'"
    fi
}

# none_match <name> <file> <selector> <predicate> — no selected element
# satisfies the predicate. Skips loudly if the selector matches nothing.
none_match() {
    local name="$1" file="$2" selector="$3" predicate="$4" count bad
    count=$(jq -r "[$selector] | length" "$file" 2>&1)
    if [[ ! "$count" =~ ^[0-9]+$ ]]; then
        _fail "$name" "selector '$selector' failed: $count"
        return
    fi
    if [[ "$count" -eq 0 ]]; then
        skip "$name" "the sample contains no elements matching '$selector'"
        return
    fi
    bad=$(jq -r "[$selector | select($predicate)] | length" "$file" 2>&1)
    if [[ "$bad" == "0" ]]; then
        _pass "$name"
    else
        _fail "$name" "$bad of $count element(s) satisfy '$predicate' and should not"
    fi
}

# --- CSV assertions --------------------------------------------------------
#
# Columns are addressed by name, not position. That reads better and it is more
# correct: useColumnShortNames=true lowercases the first three headers, so an
# index- or case-sensitive check only works for one of the two documented forms.

# csv_column <file> <column-name> — print one column's values, header excluded.
# Quote-aware, because OWID quotes long column titles that contain commas.
# Exits non-zero if the column is absent.
csv_column() {
    awk -v want="$2" '
    function csvsplit(line, arr,   i, c, n, field, inq) {
        n = 0; field = ""; inq = 0
        for (i = 1; i <= length(line); i++) {
            c = substr(line, i, 1)
            if (c == "\"") { inq = !inq; continue }
            if (c == "," && !inq) { arr[++n] = field; field = ""; continue }
            field = field c
        }
        arr[++n] = field
        return n
    }
    { sub(/\r$/, "") }
    NR == 1 {
        n = csvsplit($0, head)
        for (i = 1; i <= n; i++) if (tolower(head[i]) == tolower(want)) col = i
        if (!col) exit 1
        next
    }
    { if (csvsplit($0, row) >= col) print row[col] }
    ' "$1"
}

# csv_has_columns <name> <file> <column>... — all named columns exist.
csv_has_columns() {
    local name="$1" file="$2"
    shift 2
    local missing=()
    for column in "$@"; do
        csv_column "$file" "$column" >/dev/null 2>&1 || missing+=("$column")
    done
    if [[ ${#missing[@]} -eq 0 ]]; then
        _pass "$name"
    else
        _fail "$name" "missing column(s): ${missing[*]}; header is '$(head -1 "$file" | tr -d '\r')'"
    fi
}

# csv_min_rows <name> <file> <n> — the file has at least n data rows.
csv_min_rows() {
    local name="$1" file="$2" min="$3" rows
    rows=$(($(grep -c '' "$file") - 1))
    if [[ "$rows" -ge "$min" ]]; then
        _pass "$name"
    else
        _fail "$name" "$rows data row(s), expected at least $min"
    fi
}

# csv_column_set <name> <file> <column> <expected> — the distinct values in the
# column are exactly the expected space-separated set.
csv_column_set() {
    local name="$1" file="$2" column="$3" expected="$4" actual
    actual=$(csv_column "$file" "$column" 2>/dev/null | sort -u | tr '\n' ' ')
    expected=$(printf '%s' "$expected" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    if [[ "$actual" == "$expected" ]]; then
        _pass "$name"
    else
        _fail "$name" "column '$column' holds { ${actual}}, expected { ${expected}}"
    fi
}

# csv_column_range <name> <file> <column> <min> <max> — every value in the
# column is numeric and within [min, max].
csv_column_range() {
    local name="$1" file="$2" column="$3" min="$4" max="$5" values lo hi
    values=$(csv_column "$file" "$column" 2>/dev/null | grep -E '^-?[0-9]+$' | sort -n)
    if [[ -z "$values" ]]; then
        _fail "$name" "column '$column' is absent or holds no integers"
        return
    fi
    lo=$(printf '%s\n' "$values" | head -1)
    hi=$(printf '%s\n' "$values" | tail -1)
    if [[ "$lo" -ge "$min" && "$hi" -le "$max" ]]; then
        _pass "$name"
    else
        _fail "$name" "column '$column' spans $lo..$hi, expected within $min..$max"
    fi
}

# csv_column_matches <name> <file> <column> <ere> — every value in the column
# matches the extended regular expression.
csv_column_matches() {
    local name="$1" file="$2" column="$3" pattern="$4" total bad
    total=$(csv_column "$file" "$column" 2>/dev/null | grep -c '' || true)
    if [[ "$total" == "0" ]]; then
        _fail "$name" "column '$column' is absent or empty"
        return
    fi
    bad=$(csv_column "$file" "$column" 2>/dev/null | grep -cvE "$pattern" || true)
    if [[ "$bad" == "0" ]]; then
        _pass "$name"
    else
        _fail "$name" "$bad of $total value(s) in '$column' do not match /$pattern/"
    fi
}

# csv_header <name> <file> <expected-prefix> — the CSV header starts with this
# comma-separated prefix.
csv_header() {
    local name="$1" file="$2" expected="$3" actual
    actual=$(head -1 "$file" | tr -d '\r')
    if [[ "$actual" == "$expected"* ]]; then
        _pass "$name"
    else
        _fail "$name" "header is '$actual', expected it to start with '$expected'"
    fi
}

# --- documentation drift ---------------------------------------------------
#
# A skill is SKILL.md plus, optionally, the files under references/ that it
# tells the agent to read. Claims about the API live in both, so the drift
# checks take the file to inspect. Paths are relative to the skill directory
# ("SKILL.md", "references/search-api.md") or absolute.

_doc_path() {
    case "$1" in
        /*) printf '%s' "$1" ;;
        *) printf '%s/%s' "$SKILL_DIR" "$1" ;;
    esac
}

# doc_contains <name> <file> <pattern> — the file matches this grep -E pattern.
# Use to catch documentation drifting away from the API, in either direction.
doc_contains() {
    local name="$1" file pattern="$3"
    file=$(_doc_path "$2")
    if [[ ! -f "$file" ]]; then
        _fail "$name" "$2 does not exist"
    elif grep -qE "$pattern" "$file"; then
        _pass "$name"
    else
        _fail "$name" "$2 has no match for /$pattern/"
    fi
}

# doc_table_covers <name> <file> <observed-values> — every value in the
# newline-separated list appears in the first column of a two-column mapping
# table in the file, i.e. a row of the form:
#
#     | `Value` | `mapped-to` | description |
#
# This catches doc drift in the direction that actually hurts: a value the API
# returns that an agent has no documented mapping for.
doc_table_covers() {
    local name="$1" file observed="$3" documented missing
    file=$(_doc_path "$2")
    if [[ ! -f "$file" ]]; then
        _fail "$name" "$2 does not exist"
        return
    fi
    documented=$(sed -n 's/^| *`\([A-Za-z][A-Za-z]*\)` *| *`[a-z-][a-z-]*` *|.*/\1/p' "$file" | sort -u)
    if [[ -z "$observed" ]]; then
        skip "$name" "no observed values to compare against"
        return
    fi
    missing=$(comm -13 <(printf '%s\n' "$documented") <(printf '%s\n' "$observed" | sort -u))
    if [[ -z "$missing" ]]; then
        _pass "$name"
    else
        _fail "$name" "missing from the table in $2: $(printf '%s' "$missing" | tr '\n' ' ')"
    fi
}

# skill_md_contains <name> <pattern> — shorthand for doc_contains on SKILL.md.
skill_md_contains() {
    doc_contains "$1" "$SKILL_MD" "$2"
}

# skill_md_table_covers <name> <observed-values> — shorthand for
# doc_table_covers on SKILL.md.
skill_md_table_covers() {
    doc_table_covers "$1" "$SKILL_MD" "$2"
}

# http_status <name> <url> <expected-code> [outfile] — the url returns exactly
# this HTTP status. For the cases fetch cannot express: an endpoint that must
# reject bad input, or a success whose body you do not need.
http_status() {
    local name="$1" url="$2" expected="$3" out="${4:-/dev/null}" code
    # No --retry here: curl counts a 5xx as a transient failure and retries it,
    # and on some curl versions exhausting the retries exits non-zero, which
    # hid the status behind a 000. A check that expects a 500 must see the 500.
    code=$(curl -sS -L --max-time 90 \
        -H 'User-Agent: owid-skills contract tests (tech@ourworldindata.org)' \
        -o "$out" -w '%{http_code}' "$url" 2>/dev/null)
    [[ "$code" =~ ^[0-9]{3}$ ]] || code="000"
    if [[ "$code" == "$expected" ]]; then
        _pass "$name"
    else
        _fail "$name" "GET $url → HTTP $code, expected $expected"
    fi
}

# content_type <name> <url> <ere> — the response's Content-Type header matches.
content_type() {
    local name="$1" url="$2" pattern="$3" ctype
    ctype=$(curl -sS -L --retry 3 --retry-delay 2 --max-time 90 \
        -H 'User-Agent: owid-skills contract tests (tech@ourworldindata.org)' \
        -o /dev/null -w '%{content_type}' "$url" 2>/dev/null) || ctype="<request failed>"
    if [[ "$ctype" =~ $pattern ]]; then
        _pass "$name"
    else
        _fail "$name" "Content-Type is '$ctype', expected /$pattern/"
    fi
}

# finish — print the summary, write summary.json, exit non-zero on any failure.
finish() {
    printf '\n  %s: %d passed, %d failed, %d skipped\n' "$SKILL_NAME" "$_PASS" "$_FAIL" "$_SKIP"
    {
        printf '{\n  "skill": "%s",\n  "passed": %d,\n  "failed": %d,\n  "skipped": %d,\n  "failures": [' \
            "$SKILL_NAME" "$_PASS" "$_FAIL" "$_SKIP"
        local first=1
        for f in ${_FAILURES+"${_FAILURES[@]}"}; do
            [[ $first -eq 0 ]] && printf ','
            printf '\n    %s' "$(printf '%s' "$f" | jq -Rs .)"
            first=0
        done
        [[ $first -eq 0 ]] && printf '\n  '
        printf ']\n}\n'
    } >"$WORK/summary.json"
    [[ $_FAIL -eq 0 ]]
}
