#!/usr/bin/env bash
# Assess the Haskell example in each chapter (code/chN/Algebra.lhs).
#
# Mechanical checks only; the judgment criteria are in
# docs/chapter-code-assessment.md.
#
# Checks per chapter:
#   run        runghc exits 0 and prints something (gate)
#   sections   required headings are present (gate for ch4+; ch3 is reported)
#   laws       every law binding (`> testN = ...`) evaluates to True (gate)
#   scorecard  number of ✓ / ✗ rows in "Algebraic Scorecard" and whether any
#              law backs them (warning if ✓ rows exist and there are no law
#              bindings at all)
#
# Usage (from repo root):
#   tools/assess_chapter_code.sh                  # all chapters
#   tools/assess_chapter_code.sh 4 6              # selected chapters
#   tools/assess_chapter_code.sh --run-prefix "" 4  # already inside nix develop
#
# Exit status: 0 if every assessed chapter passes its gates, 1 otherwise.

set -u
export LC_ALL=C.UTF-8

RUN_PREFIX="nix develop --command"
RUN_TIMEOUT=300
REQUIRED_HEADINGS="Types Algebra Observations Example Algebraic Scorecard"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

usage() {
    sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# Run a command through the toolchain prefix. Unquoted expansion of
# RUN_PREFIX is intentional: it splits into words, and an empty prefix
# expands to nothing.
toolchain() {
    timeout "$RUN_TIMEOUT" $RUN_PREFIX "$@"
}

# First GHC error line from a stderr file, else its last line.
first_error() {
    local hit
    hit="$(grep -m 1 -i 'error' "$1")"
    [ -n "$hit" ] && { printf '%s' "$hit"; return; }
    tail -n 1 "$1"
}

# check_run CHAPTER PATH -> sets RUN_OK, RUN_DETAIL
check_run() {
    local path="$2" out rc
    out="$(cd "$ROOT" && toolchain runghc "$path" 2>"$TMP/run.err")"
    rc=$?
    if [ "$rc" -eq 124 ]; then
        RUN_OK=0; RUN_DETAIL="timeout"; return
    fi
    local lines
    lines="$(printf '%s\n' "$out" | grep -c .)"
    RUN_DETAIL="exit $rc, $lines output lines"
    RUN_OK=0
    if [ "$rc" -eq 0 ] && [ -n "$(printf '%s' "$out" | tr -d '[:space:]')" ]; then
        RUN_OK=1
    fi
    if [ "$rc" -ne 0 ]; then
        RUN_DETAIL="$RUN_DETAIL; stderr: $(first_error "$TMP/run.err")"
    fi
}

# check_sections FILE CHAPTER -> sets SEC_OK, SEC_MISSING, SEC_GATED
check_sections() {
    local file="$1" chapter="$2" h
    SEC_MISSING=""
    for h in "Types" "Algebra" "Observations" "Example" "Algebraic Scorecard"; do
        if ! grep -qE "^${h}[[:space:]]*$" "$file"; then
            SEC_MISSING="${SEC_MISSING:+$SEC_MISSING, }$h"
        fi
    done
    SEC_OK=1
    [ -n "$SEC_MISSING" ] && SEC_OK=0
    SEC_GATED=0
    [ "$chapter" -ge 4 ] && SEC_GATED=1
}

# check_laws FILE CHAPTER(relative path) -> sets LAW_OK, LAW_COUNT, LAW_FAILED, LAW_DETAIL
check_laws() {
    local file="$1" path="$2" names n expr out rc
    names="$(grep -E '^> test[A-Za-z0-9_]*[[:space:]]*=' "$file" \
        | sed -E 's/^> (test[A-Za-z0-9_]*).*/\1/' | awk '!seen[$0]++')"
    LAW_COUNT=0
    LAW_FAILED=""
    if [ -z "$names" ]; then
        LAW_OK=1; LAW_DETAIL="no law bindings"; return
    fi

    # Build: mapM_ (\(n, v) -> putStrLn (n ++ " " ++ show v)) [("testN", testN), ...]
    local items=""
    while IFS= read -r n; do
        LAW_COUNT=$((LAW_COUNT + 1))
        items="${items:+$items, }(\"$n\", $n)"
    done <<< "$names"
    expr="mapM_ (\\(n, v) -> putStrLn (n ++ \" \" ++ show v)) [$items]"

    out="$(cd "$ROOT" && toolchain ghc -v0 -e "$expr" "$path" 2>"$TMP/ghc.err")"
    rc=$?
    if [ "$rc" -eq 124 ]; then
        LAW_OK=0; LAW_FAILED="$names"; LAW_DETAIL="timeout"; return
    fi
    if [ "$rc" -ne 0 ]; then
        LAW_OK=0; LAW_FAILED="$names"
        LAW_DETAIL="ghc -e failed: $(tail -n 1 "$TMP/ghc.err")"
        return
    fi

    local true_count=0
    while IFS= read -r n; do
        if printf '%s\n' "$out" | grep -qxF "$n True"; then
            true_count=$((true_count + 1))
        else
            LAW_FAILED="${LAW_FAILED:+$LAW_FAILED, }$n"
        fi
    done <<< "$names"

    LAW_OK=1
    [ -n "$LAW_FAILED" ] && LAW_OK=0
    LAW_DETAIL="$true_count/$LAW_COUNT laws True"
}

# check_scorecard FILE LAW_COUNT -> sets SC_HOLDS, SC_FAILS, SC_WARNING
check_scorecard() {
    local file="$1" law_count="$2" start rows
    SC_WARNING=""
    start="$(grep -n "Algebraic Scorecard" "$file" | head -n 1 | cut -d: -f1)"
    if [ -z "$start" ]; then
        SC_HOLDS=0; SC_FAILS=0; SC_WARNING="no scorecard"; return
    fi
    rows="$(tail -n "+$start" "$file")"
    SC_HOLDS="$(printf '%s\n' "$rows" | grep -cE '^[[:space:]]+[^[:space:]][^✓✗]*[[:space:]]+✓' || true)"
    SC_FAILS="$(printf '%s\n' "$rows" | grep -cE '^[[:space:]]+[^[:space:]][^✓✗]*[[:space:]]+✗' || true)"
    if [ "$SC_HOLDS" -gt 0 ] && [ "$law_count" -eq 0 ]; then
        SC_WARNING="$SC_HOLDS ✓ claims but no machine-checked law bindings"
    fi
}

# assess CHAPTER -> prints a report block, returns 0 on pass, 1 on fail
assess() {
    local chapter="$1" path file gates_ok=1
    path="code/ch$chapter/Algebra.lhs"
    file="$ROOT/$path"

    check_run "$chapter" "$path"
    check_sections "$file" "$chapter"
    check_laws "$file" "$path"
    check_scorecard "$file" "$LAW_COUNT"

    [ "$RUN_OK" -eq 1 ] || gates_ok=0
    [ "$LAW_OK" -eq 1 ] || gates_ok=0
    if [ "$SEC_GATED" -eq 1 ] && [ "$SEC_OK" -eq 0 ]; then gates_ok=0; fi

    local status=FAIL
    [ "$gates_ok" -eq 1 ] && status=PASS
    echo "ch$chapter  $status  $path"

    echo "  run:       $([ "$RUN_OK" -eq 1 ] && echo ok || echo FAIL) ($RUN_DETAIL)"
    if [ -n "$SEC_MISSING" ]; then
        local note=""
        [ "$SEC_GATED" -eq 0 ] && note=" (not gated before ch4)"
        echo "  sections:  missing $SEC_MISSING$note"
    else
        echo "  sections:  ok"
    fi
    local lawline="  laws:      $LAW_DETAIL"
    [ -n "$LAW_FAILED" ] && lawline="$lawline FAILED: $LAW_FAILED"
    echo "$lawline"
    echo "  scorecard: $SC_HOLDS ✓, $SC_FAILS ✗"
    [ -n "$SC_WARNING" ] && echo "  warning:   $SC_WARNING"
    echo

    [ "$gates_ok" -eq 1 ]
}

main() {
    local chapters="" run_prefix_set=0 c dir n passed=0 total=0

    while [ $# -gt 0 ]; do
        case "$1" in
            --run-prefix) RUN_PREFIX="${2-}"; shift 2 ;;
            --run-prefix=*) RUN_PREFIX="${1#--run-prefix=}"; shift ;;
            -h|--help) usage; return 0 ;;
            -*) echo "unknown option: $1" >&2; usage >&2; return 2 ;;
            *)
                case "$1" in
                    ''|*[!0-9]*) echo "not a chapter number: $1" >&2; return 2 ;;
                esac
                chapters="$chapters $((10#$1))"
                shift
                ;;
        esac
    done

    if [ -z "$chapters" ]; then
        for dir in "$ROOT"/code/ch*/; do
            [ -f "${dir}Algebra.lhs" ] || continue
            n="$(basename "$dir")"
            n="${n#ch}"
            chapters="$chapters $n"
        done
        chapters="$(printf '%s\n' $chapters | sort -n | tr '\n' ' ')"
    fi

    for c in $chapters; do
        total=$((total + 1))
        if assess "$c"; then
            passed=$((passed + 1))
        fi
    done
    echo "$passed/$total chapters pass the gates"

    [ "$passed" -eq "$total" ]
}

main "$@"
