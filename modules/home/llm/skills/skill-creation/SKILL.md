---
name: skill-creation
description: Use when creating, editing, evaluating, or preparing to deploy an agent skill.
---

# Skill Authoring

Edit canonical source under `modules/home/llm/skills/<name>/`, not deployed
Home Manager links. Skills are reusable guidance, not session narratives.
Preserve the user's decision authority and repository safety rules.

## Authoring contract

1. Identify the role, trigger, inputs, owned decisions, procedure, output and
   boundaries. Separate role accountability from shared language knowledge.
2. State only when to load the skill in its description, beginning "Use when".
   Put workflow and tool details in the body, not the discovery summary.
3. Keep role SKILL.md files under 500 words; aim below 200 for frequently loaded
   entries. Link substantial examples, tools and detailed knowledge as references.
   Keep critical authority and completion rules in the main file.
4. Use positive recipes for output shape, required fields for omissions, and
   observable condition/action rules. Reserve explicit prohibitions and
   rationalization examples for demonstrated discipline failures.
5. Automate mechanical constraints. Avoid duplicating shared contracts or adding
   a rule for every hypothetical failure. Prefer one relevant, runnable example.
6. Test actual application before claiming behavioral improvement. Read
   [evaluation guidance](references/evaluation.md) for controls, repeated samples,
   pressure scenarios and limitations.

## Verification

Run `bash tests/contracts_test.sh` from this skill directory for the first-pass
role structure checks. Check links, descriptions, word budgets and source diffs.
Static checks do not prove agent behavior.

For behavioral changes, capture the old/no-guidance baseline before edits, then
evaluate the candidate on the same scenarios in fresh contexts. Record model,
skill version, scenario, sample count, observations and limitations.
If execution is unavailable, report the behavioral result as unverified.

## Output

Report: intended behavior; observed baseline; changed guidance; static results;
behavioral evidence; unresolved failures; deployment status. A passing keyword
search or an agent reciting the rules is not an execution evaluation.

## Boundaries

Never invent passing evaluations, claim deployed behavior from source edits,
force cleanup, or override approved scope. Do not copy an external framework's
authority, destructive commands or waiver policy without checking local constraints.
New independent review gates require actual workflow routing and guard tests, not
just an extra role name in prose.
