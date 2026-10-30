# Session Lock Proposal — Awaiting Policy Approval

This proposal is not an enabled locking mechanism. The facade still requires one
explicitly authorized coordinator; its environment marker is a role guard, not a
security boundary or a lock. Do not claim atomic coordination until the session
supervisor is implemented and tested on the actual agent host.

## Proposed mechanism

Use a kernel `flock` on a stable repository-local file under the excluded/ignored
`.tasks/.mtn/` directory. Launch the top-level coordinator through a session supervisor
that owns the lock for the ENTIRE session, not one individual publish call. Require
an installed compatible flock; fail closed if unavailable. Local filesystems only;
NFS/shared multi-machine coordination requires a different service.

Use nonblocking acquisition, with a distinctive conflict exit code and readable
owner/run metadata. A competing session fails immediately; it does not queue or
steal after a timeout. The lock file stays in place forever: deleting/recreating it
would allow different sessions to lock different inodes.

A flock supervisor can close the lock FD in the executed agent (`--close`) so child
agents do not accidentally retain it. The supervisor remains responsible for the
coordinator lifecycle. All mutation helpers require its session identity; dispatch
strips coordinator authority from workers. Metadata is diagnostic, never the lock.

## Conflicts and restarts

- **Live holder:** refuse the second coordinator; point the user to the existing
  session. Never kill it or transfer authority automatically.
- **Coordinator/supervisor crash:** the kernel releases the lock when its last owner
  closes. Stale metadata/file presence cannot keep the lock held.
- **Only the supervisor died:** the coordinator or workers may still be alive. A
  newly available lock is NOT proof those processes stopped. Compare host/run/process
  identities and reconcile before any new mutation/dispatch.
- **Normal restart:** acquire the lock, then reconcile dispatch reservations, agents,
  worktrees, evidence and target history. Resume missing steps idempotently; do not
  relaunch a reserved task merely because its former coordinator vanished.
- **Uncertain owner or remote host:** stop and ask. PID alone is insufficient because
  of PID reuse; use host, boot/session identity and process start identity where available.
- **Deliberate takeover:** explicit user authorization plus confirmed prior coordinator
  and writer stoppage. No automatic lease expiry or force-unlock-by-file-deletion.

Required tests before enabling: acquisition races, conflict reporting, clean exit,
coordinator crash, supervisor-only crash, inherited-FD behavior, stale metadata,
PID reuse and restart with live workers. Host supervision may be needed for process-
group termination; the shell wrapper alone must not assert it killed every child.
