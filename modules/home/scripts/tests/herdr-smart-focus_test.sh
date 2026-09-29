#!/usr/bin/env bash
set -euo pipefail

script="$(dirname "${BASH_SOURCE[0]}")/../herdr-smart-focus"

herdr() {
	local pane direction neighbor="" layout tab="${TEST_TAB:-w1:t1}" focused="${TEST_FOCUSED:-w1:pA}"
	case "$1 $2" in
	"pane neighbor")
		pane="$focused"
		direction="$4"
		if [[ "$*" == *' --pane '* ]]; then pane="${*: -1}"; fi
		case "$pane:$direction" in
		w1:pB:right) neighbor=w1:pC ;;
		w1:pC:left) neighbor=w1:pB ;;
		esac
		layout="$(layout_json "$tab" "$focused")"
		jq -nc --argjson layout "$layout" --arg pane "$pane" --arg neighbor "$neighbor" '{result:{neighbor:{pane_id:$pane,neighbor_pane_id:(if $neighbor == "" then null else $neighbor end),layout:$layout}}}'
		;;
	"pane layout")
		if [[ "$*" == *w1:pA* ]]; then
			layout="$(layout_json w1:t1 w1:pA)"
		else
			layout="$(layout_json w1:t2 "${TEST_ENTRY_FOCUSED:-w1:pC}")"
		fi
		jq -nc --argjson layout "$layout" '{result:{layout:$layout}}'
		;;
	"pane list") printf '%s\n' '{"result":{"panes":[{"pane_id":"w1:pA","tab_id":"w1:t1"},{"pane_id":"w1:pB","tab_id":"w1:t2"},{"pane_id":"w1:pC","tab_id":"w1:t2"}]}}' ;;
	"tab list")
		jq -nc --arg tab "$tab" '{result:{tabs:[{tab_id:"w1:t1",focused:($tab == "w1:t1")},{tab_id:"w1:t2",focused:($tab == "w1:t2")} ]}}'
		;;
	"pane focus" | "tab focus") printf '%s\n' "$*" >&2 ;;
	*)
		printf 'unexpected call: %s\n' "$*" >&2
		return 1
		;;
	esac
}
layout_json() {
	if [[ "$1" == w1:t1 ]]; then
		printf '%s\n' '{"workspace_id":"w1","tab_id":"w1:t1","focused_pane_id":"w1:pA","panes":[{"pane_id":"w1:pA","rect":{"x":0,"y":0,"width":100,"height":60}}]}'
	else
		jq -nc --arg focused "$2" '{workspace_id:"w1",tab_id:"w1:t2",focused_pane_id:$focused,panes:[{pane_id:"w1:pB",rect:{x:0,y:0,width:50,height:60}},{pane_id:"w1:pC",rect:{x:50,y:0,width:50,height:60}}]}'
	fi
}
export -f herdr layout_json

assert_output() {
	local expected="$1" actual
	shift
	actual="$("$script" "$@" 2>&1)"
	if [[ "$actual" != "$expected" ]]; then
		printf 'expected: %s\nactual: %s\n' "$expected" "$actual" >&2
		exit 1
	fi
}

TEST_TAB=w1:t1
TEST_ENTRY_FOCUSED=w1:pC
export TEST_TAB TEST_ENTRY_FOCUSED
assert_output $'tab focus w1:t2\npane focus --direction left --pane w1:pC' right
TEST_TAB=w1:t2 TEST_FOCUSED=w1:pB
export TEST_FOCUSED
assert_output 'pane focus --direction right --pane w1:pB' right
TEST_FOCUSED=w1:pC
assert_output 'tab focus w1:t1' right
assert_output 'pane focus --direction left --pane w1:pC' left
TEST_FOCUSED=w1:pB
assert_output 'tab focus w1:t1' left
printf 'Herdr smart focus checks passed\n'
