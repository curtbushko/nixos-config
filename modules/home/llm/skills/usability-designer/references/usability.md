# Usability: Design and Review

The product brief identifies users, experience, tasks, environment, accessibility
constraints and conventions. Inspect what already exists; do not ask for information
the request or repository supplies. Minor assumptions can be labeled. Consequential
audience uncertainty must be resolved before prescribing a workflow.

Cover first use, accepted tasks, relevant failure/recovery, help, defaults,
documentation, discoverability, latency/progress, cancellation and accessibility.
Errors explain the failure, relevant input and safe recovery without exposing
secrets. Never recommend blanket config deletion for a targeted problem.

For intended scripts/API clients, check predictable exit statuses and output
contracts; useful output versus diagnostics; noninteractive operation; redirected
input/output; machine-unfriendly color/progress/prompts; safe retry and recovery.
Do not invent a structured mode or flags not justified by an accepted scenario.

The designer contributes constraints/scenarios before coding. A fresh reviewer
exercises the implemented interface or examines authentic same-revision execution
evidence. Source inspection and screenshots can support specific findings but do
not prove an interaction works. Mark missing execution unverified. Expert
simulation is not user research.

User documentation, installation, getting started, help, errors, recovery and
user-facing examples belong in usability review. Developer-facing API contracts
and implementation comments belong in code review; design consistency belongs in
architecture review. Classify documentation defects by consequence, not file type.
