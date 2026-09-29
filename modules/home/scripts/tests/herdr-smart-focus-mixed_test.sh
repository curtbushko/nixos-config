#!/usr/bin/env bash
set -euo pipefail

script="$(dirname "${BASH_SOURCE[0]}")/../herdr-smart-focus"
layout="$(printf '%s' '{"workspace_id":"w1","tab_id":"w1:t2","focused_pane_id":"w1:pC","panes":[{"pane_id":"w1:pC","rect":{"x":0,"y":0,"width":50,"height":60}},{"pane_id":"w1:pD","rect":{"x":50,"y":0,"width":50,"height":30}},{"pane_id":"w1:pE","rect":{"x":50,"y":30,"width":50,"height":30}}]}')"
tabs="$(printf '%s' '{"result":{"tabs":[{"tab_id":"w1:t1","focused":false},{"tab_id":"w1:t2","focused":true}]}}')"
export layout tabs

herdr() {
	local pane direction neighbor=""
	case "$1 $2" in
	"pane neighbor")
		pane="${TEST_CURRENT:-w1:pC}"
		direction="$4"
		if [[ "$*" == *' --pane '* ]]; then
			pane="${*: -1}"
			if [[ "${TEST_NO_LOOKUPS:-}" == 1 ]]; then
				printf 'unexpected neighbor lookup\n' >&2
				return 1
			fi
		fi
		case "$pane:$direction" in
		w1:pC:right) neighbor=w1:pD ;;
		w1:pC:down) if [[ "${TEST_EXTRA:-}" == 1 ]]; then neighbor=w1:pF; fi ;;
		w1:pF:up) neighbor=w1:pC ;;
		w1:pD:left | w1:pE:left) neighbor=w1:pC ;;
		w1:pD:down) neighbor=w1:pE ;;
		w1:pE:up) neighbor=w1:pD ;;
		esac
		jq -nc --argjson layout "$layout" --arg pane "$pane" --arg neighbor "$neighbor" '{result:{neighbor:{pane_id:$pane,neighbor_pane_id:(if $neighbor == "" then null else $neighbor end),layout:$layout}}}'
		;;
	"pane layout") jq -nc --argjson layout "$layout" '{result:{layout:$layout}}' ;;
	"pane list") printf '%s\n' '{"result":{"panes":[{"pane_id":"w1:pC","tab_id":"w1:t2"}]}}' ;;
	"tab list") printf '%s\n' "$tabs" ;;
	"pane focus" | "tab focus") printf '%s\n' "$*" >&2 ;;
	*)
		printf 'unexpected call: %s\n' "$*" >&2
		return 1
		;;
	esac
}
export -f herdr

assert_focus() {
	local expected="$1" direction="$2" current="$3" actual
	TEST_CURRENT="$current"
	export TEST_CURRENT
	layout="$(jq -c --arg id "$current" '.focused_pane_id = $id' <<<"$layout")"
	actual="$("$script" "$direction" 2>&1)"
	if [[ "$actual" != "$expected" ]]; then
		printf 'expected: %s\nactual: %s\n' "$expected" "$actual" >&2
		exit 1
	fi
}

assert_focus 'pane focus --direction right --pane w1:pC' right w1:pC
TEST_NO_LOOKUPS=1
export TEST_NO_LOOKUPS
assert_focus 'pane focus --direction down --pane w1:pD' right w1:pD
unset TEST_NO_LOOKUPS
assert_focus 'tab focus w1:t1' right w1:pE
assert_focus 'pane focus --direction up --pane w1:pE' left w1:pE
assert_focus 'pane focus --direction left --pane w1:pD' left w1:pD
assert_focus 'tab focus w1:t1' left w1:pC

# Consecutive panes in reading order need not share an edge.
TEST_EXTRA=1
export TEST_EXTRA
layout="$(jq -c '.panes += [{pane_id:"w1:pF",rect:{x:0,y:30,width:50,height:30}}]' <<<"$layout")"
assert_focus $'pane focus --direction up --pane w1:pF\npane focus --direction right --pane w1:pC' right w1:pF
assert_focus $'pane focus --direction left --pane w1:pD\npane focus --direction down --pane w1:pC' left w1:pD
printf 'Herdr mixed split focus checks passed\n'
