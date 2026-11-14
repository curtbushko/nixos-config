{
  config,
  inputs,
  pkgs,
  ...
}: let
  rexPackage = inputs.rex.packages.${pkgs.stdenv.hostPlatform.system}.rex.overrideAttrs (old: {
    # Keep the same loader workaround as Gamingrig's Rex package.
    patchelfFlags = (old.patchelfFlags or []) ++ ["--no-sort"];
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      "$out/bin/rex" --help >/dev/null
      runHook postInstallCheck
    '';
  });
  rexServer = pkgs.writeShellScript "steamdeck-rex-server" ''
    set -euo pipefail
    rex_tailnet_ip="$(${pkgs.tailscale}/bin/tailscale ip -4)"
    if [[ -z "$rex_tailnet_ip" ]]; then
      echo "Cannot start Rex: Tailscale has no IPv4 address." >&2
      exit 1
    fi
    exec ${rexPackage}/bin/rex server run \
      --extra-listen "tailnet://''${rex_tailnet_ip}:7297" \
      --tailscaled-socket /run/tailscale/tailscaled.sock
  '';
in {
  ns.terminals.rex.enable = true;
  home.packages = [rexPackage];

  systemd.user.services.rex-server = {
    Unit = {
      Description = "Rex server for Steam Deck Desktop Mode";
      PartOf = ["plasma-workspace.target"];
      ConditionEnvironment = "XDG_CURRENT_DESKTOP=KDE";
    };
    Service = {
      ExecStart = "${rexServer}";
      WorkingDirectory = config.home.homeDirectory;
      Environment = ["PATH=${config.home.profileDirectory}/bin:/usr/bin:/bin"];
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = ["plasma-workspace.target"];
  };
}
