# Code Security: Planning and Review

Use the project's actual trust model, language and environment. Trace an input,
the transformation/authorization applied, the sensitive operation, and the
observable failure or exposure. Do not demand defensive checks at every internal
function when its caller contract already establishes an invariant.

Relevant areas include injection into SQL/shell/templates; path traversal and
symlink escapes; confused authorization or ownership; unsafe process arguments;
secret logging and error leakage; weak cryptographic choices; unsafe decoding;
races around security checks; unbounded input, allocation or retries.

The analyst contributes accepted constraints and focused negative cases to tasks.
The independent reviewer inspects the result and meaningful developer-written tests.
Local checks can use fake credentials, isolated directories, fixture servers and
controlled malformed inputs. Never probe live services or reveal real secrets.

Use evidence labels:
- Verified behavior: an identified revision and actual test/reproduction result.
- Credible code path: source/caller evidence supports the failure without an exploit run.
- Unverified suspicion: missing context or access prevents a conclusion.

An exploit demonstration is not required for every finding. Do not equate an
unreproduced exploit with safety. Record actual checks, permission limits and
remaining risk; use Block/Advise/Escalate rather than exaggerated certainty.
Dependency advisories and CVE/update automation are maintenance concerns.
