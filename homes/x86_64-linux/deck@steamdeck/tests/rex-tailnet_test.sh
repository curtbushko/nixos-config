#!/usr/bin/env bash
set -euo pipefail

for command in dirname nix-instantiate jq mktemp mkdir chmod diff bash; do
	command -v "$command" >/dev/null || exit 1
done
module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
launcher="$(nix-instantiate --eval --strict --json --expr "
  (import (builtins.toPath \"$module_dir/rex.nix\") {
    config.home = { homeDirectory = \"/home/deck\"; profileDirectory = \"/home/deck/.nix-profile\"; };
    inputs.rex.packages.x86_64-linux.rex.overrideAttrs = f: \"/rex\";
    pkgs = {
      stdenv.hostPlatform.system = \"x86_64-linux\";
      tailscale = \"/tailscale\";
      writeShellScript = name: text: text;
    };
  }).systemd.user.services.rex-server.Service.ExecStart
" | jq -r .)"
fixture="$(mktemp -d)"
mkdir -p "$fixture/bin"
export REX_ARGS="$fixture/rex.args"
# Only these mock executables run; no daemon, network, or secret access.
cat >"$fixture/bin/tailscale" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "$*" == 'ip -4' ]]
[[ "${FAIL_IP:-no}" != yes ]] || exit 1
printf '%s\n' "${TAILNET_IP-100.64.0.2}"
EOF
cat >"$fixture/bin/rex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" >"$REX_ARGS"
EOF
chmod +x "$fixture/bin/tailscale" "$fixture/bin/rex"
launcher="${launcher//\/tailscale\/bin\/tailscale/$fixture/bin/tailscale}"
launcher="${launcher//\/rex\/bin\/rex/$fixture/bin/rex}"

# Offline Tailscale must fail without launching Rex on a fallback interface.
if FAIL_IP=yes bash -eu -c "$launcher"; then
	printf 'Offline Tailscale should prevent Rex startup\n' >&2
	exit 1
fi
[[ ! -e "$REX_ARGS" ]]
if TAILNET_IP='' bash -eu -c "$launcher"; then
	printf 'Missing tailnet IP should prevent Rex startup\n' >&2
	exit 1
fi
[[ ! -e "$REX_ARGS" ]]

bash -eu -c "$launcher"
diff -u <(printf '%s\n' server run --extra-listen tailnet://100.64.0.2:7297 --tailscaled-socket /run/tailscale/tailscaled.sock) "$REX_ARGS"
printf 'Rex tailnet launcher checks passed (fixtures: %s)\n' "$fixture"
