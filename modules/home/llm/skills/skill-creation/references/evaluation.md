# Evaluating Skills

## Distinguish the evidence

| Check | What it establishes | What it does not establish |
|---|---|---|
| Static structure | Names, references, budgets, prohibited stale instructions | Agent compliance |
| Recall | Agent can describe a rule | Agent follows it under competing pressure |
| No-tools scenario | Judgment/output on supplied evidence | Real tool use, filesystem safety, delivery integration |
| Sandboxed execution | Actions and artifacts for a realistic task | Universal reliability or production safety |

Keep unsupported conclusions explicit. First-pass smoke tests are not a broad
model comparison. Never call synthetic observations real user research.

## Baseline -> candidate -> variations

1. Define the observable failure and score rubric before editing.
2. Run an unchanged skill and a no-guidance control where applicable. Capture
   actual behavior, not predicted rationalizations. If the control does not fail,
   keep that result; do not manufacture a baseline.
3. Make the smallest relevant change.
4. Use the same task/environment/model for candidate runs in fresh contexts.
   For wording comparisons, use at least five samples per arm when practical.
5. Inspect every apparent failure/success manually; quoted examples and unrelated
   networking vocabulary can fool regex scoring. Report variance and false positives.
6. Add realistic time pressure, incomplete evidence, conflicting requests and
   permission constraints for discipline skills. Use retrieval/application cases
   for references and counterexamples for pattern skills.
7. Confirm real behavior with a sandboxed task before calling execution validated.
   Tool access, side effects and external services must remain within authorization.

## First-pass no-tools suite

`tests/run_evals.sh MODEL OUTPUT_DIR [REPETITIONS]` runs the checked-in scenarios
through ephemeral Pi calls. It is opt-in, uses real model calls, and requires an
explicit model and an output directory that does not already exist. It disables
tools, extensions, MCP, context files and automatic skill discovery.

The suite saves prompts, raw responses, model argument and skill hashes. It does
not auto-grade prose or certify safety. Review responses against each scenario's
`expected` list and record sample counts and limitations. The authoring scenario
supports candidate, HEAD-baseline and no-guidance arms; role scenarios are smoke
tests, not full workflow execution.

Preserve results; never commit credentials or private repository content.
Use a separate authorized test checkout for live tool-use evaluations. A future
delivery exercise should cover independent Go reviewers, real regression detection,
a CVE update proposal, and a user's failure/recovery journey.

## Evidence record

Record UTC time, model/provider, exact prompt, hashes/revision of loaded skill and
references, scenario, arm, repeat number, response/artifact pointers, observed
outcome and evaluator rationale. Mark missing authorization or unavailable tools
as limitations. Deployment needs the normal Home Manager activation; editing source
does not modify already loaded agent instructions.
