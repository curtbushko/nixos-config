#!/usr/bin/env bash
set -euo pipefail
unset MTN_WORKFLOW_COORDINATOR
for command in jq git mtn mktemp dirname shasum bash; do
	command -v "$command" >/dev/null || exit 1
done
skill="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo="$(git -C "$skill" rev-parse --show-toplevel)"
script="$repo/modules/home/scripts/mtn-workflow"

# Synthetic digests exercise binding here; the native fixture below hashes real bytes.
jq -n -e -L "$skill/scripts" '
include "workflow";
include "facade";
def common($id;$kind): {schemaVersion:1,eventId:$id,kind:$kind,recordRef:"prds/demo.md",specHash:"current",attempt:1};
def approval($id): common($id;"approval")+{decision:"approved",approvedBy:"fixture user",decisionEvidence:"registration only"};
def bad: approval("bad")|.specHash="old"|.decisionEvidence={response:"yes"};
def recovery: common("recover";"recovery")+{decision:"approved",approvedBy:"fixture user",decisionEvidence:"authorize exact quarantine only",collectionRoot:"/fixture/.tasks",disposition:"quarantine-malformed-approval",target:{eventId:"bad",specHash:"old",intent:("a"*64),contentDigest:("sha256:"+("b"*64))},replacementEventId:"replacement"};
def reassessment: recovery+{eventId:"reassess",specHash:"revised",replacementEventId:"revised-approval",supersedesRecoveryEventId:"recover"};
def note($event): {content:($event|tojson),intent:(if $event.eventId=="bad" then "a"*64 else "native-"+$event.eventId end),timestamp:"2026-01-01T00:00:00Z",author:"fixture"};
def view($events): {result:{ref:"prds/demo.md",frontmatter:{workflowKind:"prd"},evidence:($events|map(note(.)))},recoveryContext:{collectionRoot:"/fixture/.tasks",specHash:"current",contentDigests:($events|map("sha256:"+("b"*64)))}};
def snapshot: {ref:"prds/demo.md",specHash:"current",events:evidence_events(valid_event)};
def rejected: try (evidence_events(valid_event)|all(.[];valid_event)|not) catch true;
def check($name; assertion): if assertion then true else error($name) end;
[
 check("typed recovery shape"; recovery|valid_event),
 check("malformed approval alone blocks"; view([bad])|rejected),
 check("correct approval append alone blocks"; view([bad,approval("replacement")])|rejected),
 check("quarantine alone cannot approve, including prior valid approval"; view([approval("prior"),bad,recovery])|snapshot|document_approved|not),
 check("authorized replacement approves"; view([bad,recovery,approval("replacement")])|snapshot|document_approved),
 check("projection preserves original envelope and exact content"; view([bad,recovery]) as $v|($v|evidence_events(valid_event)|.[0]) as $h|$h.kind=="historical" and $h.gateEligible==false and $h.originalNote==$v.result.evidence[0] and $h.content==$v.result.evidence[0].content),
 check("projection retains original immutable event identity"; view([bad,recovery])|evidence_events(valid_event)|.[0].eventId=="bad"),
 check("wrong collection"; view([bad,recovery])|.recoveryContext.collectionRoot="/other/.tasks"|rejected),
 check("missing context"; view([bad,recovery])|del(.recoveryContext)|rejected),
 check("wrong current fingerprint"; view([bad,recovery])|.recoveryContext.specHash="new"|rejected),
 check("wrong target record"; view([bad,(recovery|.recordRef="prds/other.md")])|rejected),
 check("wrong target event"; view([bad,(recovery|.target.eventId="absent")])|rejected),
 check("wrong target intent"; view([bad,(recovery|.target.intent=("c"*64))])|rejected),
 check("wrong target fingerprint"; view([bad,(recovery|.target.specHash="wrong")])|rejected),
 check("wrong content digest"; view([bad,(recovery|.target.contentDigest=("sha256:"+("c"*64)))])|rejected),
 check("missing authority"; view([bad,(recovery|del(.approvedBy))])|rejected),
 check("malformed authority"; view([bad,(recovery|.decisionEvidence={response:"yes"})])|rejected),
 check("wrong scope"; view([bad,(recovery|.disposition="approve")])|rejected),
 check("self reference"; view([bad,(recovery|.target.eventId="recover")])|rejected),
 check("valid rejection cannot be quarantined"; view([(approval("bad")|.specHash="old"|.decision="rejected"),recovery])|rejected),
 check("blockers cannot be quarantined"; view([(common("bad";"blocker")+{reason:"stop"}),recovery])|rejected),
 check("future target"; view([recovery,bad])|rejected),
 check("duplicate IDs remain ambiguous"; view([bad,bad,recovery])|rejected),
 check("duplicate native intents remain ambiguous"; view([bad,recovery,approval("other")])|.result.evidence[2].intent=("a"*64)|rejected),
 check("conflicting recovery"; view([bad,recovery,(recovery|.eventId="recover2")])|rejected),
 check("unsupported target version"; view([(bad|.schemaVersion=2),recovery])|rejected),
 check("unsupported recovery version"; view([bad,(recovery|.schemaVersion=2)])|rejected),
 check("unrelated malformed event stays blocking"; view([bad,recovery,(bad|.eventId="unrelated")])|rejected),
 check("legacy import cannot recover typed event"; view([bad,(common("import";"historical")+{content:"import",provenance:"fixture",gateEligible:false,approvedBy:"user",decisionEvidence:"legacy only",legacyIntents:[("a"*64)]})])|rejected),
 check("replacement before authorization"; view([bad,approval("replacement"),recovery])|rejected),
 check("replacement wrong fingerprint"; view([bad,recovery,(approval("replacement")|.specHash="wrong")])|rejected),
 check("replacement wrong record"; view([bad,recovery,(approval("replacement")|.recordRef="prds/other.md")])|rejected),
 check("recovery on implementation task"; view([bad,recovery])|.result.frontmatter.workflowKind="task"|rejected),
 check("malformed digest spelling"; recovery|.target.contentDigest="sha256:bad"|valid_event|not),
 check("no-argument callers cannot enable recovery"; try (view([bad,recovery])|evidence_events|false) catch true),
 check("invalid original attempt remains preserved, not copied into projection"; view([(bad|.attempt=0),recovery])|evidence_events(valid_event)|.[0]|valid_event and .originalNote.content==(bad|.attempt=0|tojson)),
 check("designated rejection must be refused"; view([bad,recovery,(approval("replacement")|.decision="rejected")])|rejected),
 check("ordinary rejection can be recorded without consuming reserved identity"; view([bad,recovery,(approval("another-id")|.decision="rejected")])|snapshot|document_approved|not),
 check("explicit reassessment restores revised document"; view([bad,recovery,approval("replacement"),reassessment,(approval("revised-approval")|.specHash="revised")])|.recoveryContext.specHash="revised"|{ref:"prds/demo.md",specHash:"revised",events:evidence_events(valid_event)}|document_approved),
 check("reassessment alone grants no new approval"; view([bad,recovery,approval("replacement"),reassessment])|.recoveryContext.specHash="revised"|{ref:"prds/demo.md",specHash:"revised",events:evidence_events(valid_event)}|document_approved|not),
 check("branching reassessment rejected"; view([bad,recovery,reassessment,(reassessment|.eventId="fork"|.replacementEventId="fork-approval")])|.recoveryContext.specHash="revised"|rejected),
 check("unknown superseded authorization rejected"; view([bad,(reassessment|.supersedesRecoveryEventId="absent")])|.recoveryContext.specHash="revised"|rejected),
 check("reassessment cannot change original binding"; view([bad,recovery,(reassessment|.target.intent=("c"*64))])|.recoveryContext.specHash="revised"|rejected),
 check("reassessment cannot reuse replacement identity"; view([bad,recovery,(reassessment|.replacementEventId="replacement")])|.recoveryContext.specHash="revised"|rejected),
 check("supersession cycle rejected"; view([bad,(recovery|.supersedesRecoveryEventId="reassess"),reassessment])|.recoveryContext.specHash="revised"|rejected),
 check("authorized scalar JSON legacy content remains importable"; view([bad,recovery,(common("import";"historical")+{content:"import",provenance:"fixture",gateEligible:false,approvedBy:"user",decisionEvidence:"legacy only",legacyIntents:["scalar"]})])|.result.evidence += [{intent:"scalar",content:"42"}]|.recoveryContext.contentDigests += ["unused"]|evidence_events(valid_event)|all(.[];valid_event)),
 check("quarantine does not consume an unrelated blocker"; view([bad,recovery,(common("block";"blocker")+{reason:"explicit gate"})])|snapshot|unresolved_blockers|map(.eventId)==["block"]),
 check("replacement cannot reserve a generated legacy historical identity"; view([bad,(recovery|.replacementEventId="legacy/3/scalar"),(common("import";"historical")+{content:"import",provenance:"fixture",gateEligible:false,approvedBy:"user",decisionEvidence:"legacy only",legacyIntents:["scalar"]})])|.result.evidence += [{intent:"scalar",content:"42"}]|.recoveryContext.contentDigests += ["unused"]|rejected),
 check("duplicate effective identities remain rejected"; view([bad,recovery,(common("import";"historical")+{content:"import",provenance:"fixture",gateEligible:false,approvedBy:"user",decisionEvidence:"legacy only",legacyIntents:["scalar"]})])|.result.evidence += [{intent:"scalar",content:"42"},note(approval("legacy/3/scalar"))]|.recoveryContext.contentDigests += ["unused","unused"]|rejected),
 check("untyped object fields are not protocol identities or authority"; view([bad,recovery,(common("import";"historical")+{content:"import",provenance:"fixture",gateEligible:false,approvedBy:"user",decisionEvidence:"legacy only",legacyIntents:["object1","object2","object3"]})])|.result.evidence += [{intent:"object1",content:"{\"old\":1}"},{intent:"object2",content:"{\"old\":2}"},{intent:"object3",content:"{\"eventId\":\"bad\",\"kind\":\"recovery\",\"replacementEventId\":\"replacement\"}"}]|.recoveryContext.contentDigests += ["unused","unused","unused"]|evidence_events(valid_event)|length==6 and all(.[];valid_event))
]|all' >/dev/null

work="$(mktemp -d "${TMPDIR:-/tmp}/mtn-recovery.XXXXXX")"
export HOME="$work/home"
mkdir -p "$HOME" "$work/repo with spaces"
fixture="$(cd "$work/repo with spaces" && pwd -P)"
git init -q "$fixture"
mtn init "$fixture/.tasks" >/dev/null
cli() { bash "$script" --repo "$fixture" "$@"; }
native() { mtn --path "$fixture/.tasks" agent "$@" --json; }
expect_rejected() {
	if "$@" >"$work/rejected.out" 2>"$work/rejected.err"; then
		printf 'Expected rejection: %s\n' "$*" >&2
		exit 1
	fi
}
jq -n '{title:"Fixture PRD",path:"prds/demo.md",description:"Registration only",fields:{workflowKind:"prd"}}' | native create --input - >/dev/null
hash="$(cli fingerprint prds/demo.md)"
# Include Unicode and trailing newlines: command substitution must not trim content before hashing.
jq -n --arg hash "$hash" '{content:(({schemaVersion:1,eventId:"bad",kind:"approval",recordRef:"prds/demo.md",specHash:$hash,attempt:1,decision:"approved",approvedBy:"fixture user",decisionEvidence:{response:"yes é"}}|tojson)+"\n\n"),category:"approval",adopt:true,retryKey:"bad"}' | native note prds/demo.md --input - >/dev/null
native show prds/demo.md >"$work/before.json"
expect_rejected cli snapshot prds/demo.md
jq -n --arg hash "$hash" '{schemaVersion:1,eventId:"replacement",kind:"approval",recordRef:"prds/demo.md",specHash:$hash,attempt:1,decision:"approved",approvedBy:"fixture user",decisionEvidence:"synthetic registration approval"}' >"$work/replacement.json"
expect_rejected env MTN_WORKFLOW_COORDINATOR=1 bash "$script" --repo "$fixture" publish "$work/replacement.json"
digest="$(jq -j '.result.evidence[0].content' "$work/before.json" | shasum -a 256)"
digest="sha256:${digest%% *}"
jq --arg hash "$hash" --arg root "$fixture/.tasks" --arg digest "$digest" '{schemaVersion:1,eventId:"recover",kind:"recovery",recordRef:"prds/demo.md",specHash:$hash,attempt:1,decision:"approved",approvedBy:"fixture user",decisionEvidence:"synthetic explicit exact-target quarantine authority",collectionRoot:$root,disposition:"quarantine-malformed-approval",target:{eventId:"bad",specHash:$hash,intent:.result.evidence[0].intent,contentDigest:$digest},replacementEventId:"replacement"}' "$work/before.json" >"$work/recovery.json"
expect_rejected cli publish "$work/recovery.json"
jq '.target.contentDigest="sha256:"+("0"*64)' "$work/recovery.json" >"$work/wrong.json"
expect_rejected env MTN_WORKFLOW_COORDINATOR=1 bash "$script" --repo "$fixture" publish "$work/wrong.json"
[[ "$(native show prds/demo.md | jq '.result.evidence|length')" == 1 ]]
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/recovery.json" >/dev/null
cli status prds/demo.md | jq -e '.state=="approval-needed"' >/dev/null
jq '.decision="rejected"' "$work/replacement.json" >"$work/rejection.json"
expect_rejected env MTN_WORKFLOW_COORDINATOR=1 bash "$script" --repo "$fixture" publish "$work/rejection.json"
[[ "$(native show prds/demo.md | jq '.result.evidence|length')" == 2 ]]
# Legacy imports must pass the same reserved-identity checks before any append.
jq -n '{content:"42",category:"historical",adopt:true,retryKey:"scalar-legacy"}' | native note prds/demo.md --input - >/dev/null
legacy_intent="$(native show prds/demo.md | jq -r '.result.evidence[2].intent')"
jq -n --arg hash "$hash" --arg intent "$legacy_intent" '{schemaVersion:1,eventId:"replacement",kind:"historical",recordRef:"prds/demo.md",specHash:$hash,attempt:1,content:"Authorized scalar legacy import",provenance:"synthetic fixture",gateEligible:false,approvedBy:"fixture user",decisionEvidence:"synthetic import authorization",legacyIntents:[$intent]}' >"$work/reserved-import.json"
expect_rejected env MTN_WORKFLOW_COORDINATOR=1 bash "$script" --repo "$fixture" publish "$work/reserved-import.json"
[[ "$(native show prds/demo.md | jq '.result.evidence|length')" == 3 ]]
jq '.eventId="distinct-import"' "$work/reserved-import.json" >"$work/distinct-import.json"
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/distinct-import.json" >/dev/null
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/distinct-import.json" | jq -e '.ok and .result.changed==false' >/dev/null
cli status prds/demo.md | jq -e '.state=="approval-needed"' >/dev/null
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/recovery.json" | jq -e '.ok and .result.changed==false' >/dev/null
jq '.decisionEvidence="changed intent"' "$work/recovery.json" >"$work/changed.json"
expect_rejected env MTN_WORKFLOW_COORDINATOR=1 bash "$script" --repo "$fixture" publish "$work/changed.json"
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/replacement.json" >/dev/null
cli status prds/demo.md | jq -e '.state=="approved"' >/dev/null
native show prds/demo.md | jq -e --slurpfile before "$work/before.json" '.result.evidence[0]==$before[0].result.evidence[0] and (.result.evidence|length)==5 and .result.description==$before[0].result.description' >/dev/null
[[ "$hash" == "$(cli fingerprint prds/demo.md)" ]]
# A new semantic revision needs an explicit linear reassessment, never implicit carryforward.
jq -n '{description:"Revised registration requirements"}' | native describe prds/demo.md --input - >/dev/null
revised_hash="$(cli fingerprint prds/demo.md)"
[[ "$revised_hash" != "$hash" ]]
expect_rejected cli snapshot prds/demo.md
jq --arg hash "$revised_hash" '.eventId="reassess"|.specHash=$hash|.supersedesRecoveryEventId="recover"|.replacementEventId="revised-approval"|.decisionEvidence="synthetic explicit reassessment for revised requirements"' "$work/recovery.json" >"$work/reassess.json"
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/reassess.json" >/dev/null
cli status prds/demo.md | jq -e '.state=="approval-needed"' >/dev/null
jq --arg hash "$revised_hash" '.eventId="revised-approval"|.specHash=$hash|.decisionEvidence="synthetic explicit revised approval"' "$work/replacement.json" >"$work/revised-approval.json"
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/revised-approval.json" >/dev/null
cli status prds/demo.md | jq -e '.state=="approved"' >/dev/null
native show prds/demo.md | jq -e --slurpfile before "$work/before.json" '.result.evidence[0]==$before[0].result.evidence[0] and (.result.evidence|length)==7' >/dev/null
# Multiple recovered targets must be reassessable serially, in either order.
jq -n --arg hash "$revised_hash" '{content:({schemaVersion:1,eventId:"other-bad",kind:"approval",recordRef:"prds/demo.md",specHash:$hash,attempt:1,decision:"approved",approvedBy:"fixture user",decisionEvidence:{response:"yes"}}|tojson),category:"approval",adopt:true,retryKey:"other-bad"}' | native note prds/demo.md --input - >/dev/null
native show prds/demo.md >"$work/two-originals.json"
other_digest="$(jq -j '.result.evidence[-1].content' "$work/two-originals.json" | shasum -a 256)"
jq --arg hash "$revised_hash" --arg root "$fixture/.tasks" --arg digest "sha256:${other_digest%% *}" '{schemaVersion:1,eventId:"other-recover",kind:"recovery",recordRef:"prds/demo.md",specHash:$hash,attempt:1,decision:"approved",approvedBy:"fixture user",decisionEvidence:"synthetic exact authority for second target",collectionRoot:$root,disposition:"quarantine-malformed-approval",target:{eventId:"other-bad",specHash:$hash,intent:.result.evidence[-1].intent,contentDigest:$digest},replacementEventId:"other-approval"}' "$work/two-originals.json" >"$work/other-recovery.json"
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/other-recovery.json" >/dev/null
jq --arg hash "$revised_hash" '.eventId="other-approval"|.specHash=$hash' "$work/replacement.json" >"$work/other-approval.json"
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/other-approval.json" >/dev/null
cli status prds/demo.md | jq -e '.state=="approved"' >/dev/null
cp "$work/reassess.json" "$work/current-first.json"
cp "$work/other-recovery.json" "$work/current-second.json"
for round in 1 2; do
	jq -n --arg description "Multi-target revision $round" '{description:$description}' | native describe prds/demo.md --input - >/dev/null
	multi_hash="$(cli fingerprint prds/demo.md)"
	expect_rejected cli snapshot prds/demo.md
	for target in first second; do
		jq --arg hash "$multi_hash" --arg id "multi-$target-$round" '.supersedesRecoveryEventId=.eventId|.eventId=$id|.specHash=$hash|.replacementEventId=($id+"-approval")|.decisionEvidence="synthetic explicit multi-target reassessment"' "$work/current-$target.json" >"$work/next-$target.json"
		jq --arg hash "$multi_hash" --arg id "multi-$target-$round-approval" '.eventId=$id|.specHash=$hash|.decisionEvidence="synthetic revised requirement approval"' "$work/replacement.json" >"$work/next-$target-approval.json"
	done
	order=(first second)
	if [[ "$round" == 2 ]]; then order=(second first); fi
	MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/next-${order[0]}.json" >/dev/null
	expect_rejected cli snapshot prds/demo.md
	# Unrelated publications cannot opt into the reassessment-only stale-tip allowance.
	expect_rejected env MTN_WORKFLOW_COORDINATOR=1 bash "$script" --repo "$fixture" publish "$work/next-${order[0]}-approval.json"
	MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/next-${order[1]}.json" >/dev/null
	cli status prds/demo.md | jq -e '.state=="approval-needed"' >/dev/null
	MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/next-first-approval.json" >/dev/null
	cli status prds/demo.md | jq -e '.state=="approval-needed"' >/dev/null
	MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/next-second-approval.json" >/dev/null
	cli status prds/demo.md | jq -e '.state=="approved"' >/dev/null
	cp "$work/next-first.json" "$work/current-first.json"
	cp "$work/next-second.json" "$work/current-second.json"
done
native show prds/demo.md | jq -e --slurpfile originals "$work/two-originals.json" '.result.evidence[0]==$originals[0].result.evidence[0] and .result.evidence[7]==$originals[0].result.evidence[7]' >/dev/null
# Reservations must include effective identities synthesized by legacy projection.
count_before="$(native show prds/demo.md | jq '.result.evidence|length')"
jq --arg replacement "legacy/2/$legacy_intent" '.supersedesRecoveryEventId=.eventId|.eventId="legacy-collision-reassess"|.replacementEventId=$replacement|.decisionEvidence="synthetic identity collision probe"' "$work/current-first.json" >"$work/legacy-collision.json"
expect_rejected env MTN_WORKFLOW_COORDINATOR=1 bash "$script" --repo "$fixture" publish "$work/legacy-collision.json"
[[ "$(native show prds/demo.md | jq '.result.evidence|length')" == "$count_before" ]]
cli status prds/demo.md | jq -e '.state=="approved"' >/dev/null
# Multiple explicitly imported object notes have effective IDs, not null/raw protocol IDs.
jq -n '{title:"Object legacy PRD",path:"prds/objects.md",description:"Object import fixture",fields:{workflowKind:"prd"}}' | native create --input - >/dev/null
object_hash="$(cli fingerprint prds/objects.md)"
for number in 1 2; do
	jq -n --argjson number "$number" '{content:({old:$number}|tojson),category:"historical",adopt:true,retryKey:("object-"+($number|tostring))}' | native note prds/objects.md --input - >/dev/null
done
jq -n '{content:({eventId:"object-bad",kind:"recovery",replacementEventId:"objects-approved"}|tojson),category:"historical",adopt:true,retryKey:"object-with-fields"}' | native note prds/objects.md --input - >/dev/null
native show prds/objects.md | jq --arg hash "$object_hash" '{schemaVersion:1,eventId:"objects-import",kind:"historical",recordRef:"prds/objects.md",specHash:$hash,attempt:1,content:"Import original objects",provenance:"synthetic fixture",gateEligible:false,approvedBy:"fixture user",decisionEvidence:"synthetic explicit import",legacyIntents:[.result.evidence[].intent]}' >"$work/objects-import.json"
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/objects-import.json" >/dev/null
cli snapshot prds/objects.md | jq -e '.events|length==4 and all(.[];.kind=="historical")' >/dev/null
jq -n --arg hash "$object_hash" '{content:({schemaVersion:1,eventId:"object-bad",kind:"approval",recordRef:"prds/objects.md",specHash:$hash,attempt:1,decision:"approved",approvedBy:"fixture user",decisionEvidence:{response:"yes"}}|tojson),category:"approval",adopt:true,retryKey:"object-bad"}' | native note prds/objects.md --input - >/dev/null
native show prds/objects.md >"$work/objects-before.json"
object_digest="$(jq -j '.result.evidence[-1].content' "$work/objects-before.json" | shasum -a 256)"
jq --arg hash "$object_hash" --arg root "$fixture/.tasks" --arg digest "sha256:${object_digest%% *}" '{schemaVersion:1,eventId:"objects-recover",kind:"recovery",recordRef:"prds/objects.md",specHash:$hash,attempt:1,decision:"approved",approvedBy:"fixture user",decisionEvidence:"synthetic exact recovery authority",collectionRoot:$root,disposition:"quarantine-malformed-approval",target:{eventId:"object-bad",specHash:$hash,intent:.result.evidence[-1].intent,contentDigest:$digest},replacementEventId:"objects-approved"}' "$work/objects-before.json" >"$work/objects-recovery.json"
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/objects-recovery.json" >/dev/null
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/objects-recovery.json" | jq -e '.ok and .result.changed==false' >/dev/null
cli status prds/objects.md | jq -e '.state=="approval-needed"' >/dev/null
jq --arg hash "$object_hash" '.eventId="objects-approved"|.recordRef="prds/objects.md"|.specHash=$hash' "$work/replacement.json" >"$work/objects-approved.json"
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/objects-approved.json" >/dev/null
cli status prds/objects.md | jq -e '.state=="approved"' >/dev/null
native show prds/objects.md | jq -e --slurpfile before "$work/objects-before.json" '.result.evidence[:5]==$before[0].result.evidence and (.result.evidence|length)==7' >/dev/null
printf 'Evidence recovery checks passed (disposable fixture retained: %s)\n' "$work"
