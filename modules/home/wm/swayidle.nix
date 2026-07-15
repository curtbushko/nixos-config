{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.wm.niri;
  # Re-checks every 10 minutes while the session stays idle, suspending as
  # soon as nothing is busy. swayidle's resumeCommand stops this loop on
  # the first user input.
  idle-suspend-loop = pkgs.writeShellScriptBin "idle-suspend-loop" ''
    while true; do
      # only suspend if LLM agents are not running
      CLAUDE_RUNNING=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -i "claude" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs)
      CODEX_RUNNING=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -Ei "codex|cdx" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs)
      PI_RUNNING=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -Ei "pi-coding-agent|coding-agent" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs)
      OPENCODE_RUNNING=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -Ei "opencode" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs)
      DS4_RUNNING=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -Ei "ds4|ds4-server|ds4-bench|ds4-eval" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs)

      # only suspend if audio is not running
      if ${pkgs.pipewire}/bin/pw-cli i all 2>&1 | ${pkgs.ripgrep}/bin/rg -q running; then
        MUSIC_RUNNING=1
      else
        MUSIC_RUNNING=0
      fi

      # only suspend if steam is not running
      STEAM_RUNNING=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -i "steam.sh" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )

      # only suspend if no ssh connections
      SSH_CONNECTION=$(${pkgs.iproute2}/bin/ss | ${pkgs.gnugrep}/bin/grep ssh | ${pkgs.gnugrep}/bin/grep ESTAB | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )

      echo "claude running: $CLAUDE_RUNNING, codex running: $CODEX_RUNNING, pi running: $PI_RUNNING, opencode running: $OPENCODE_RUNNING, ds4 running: $DS4_RUNNING, music running: $MUSIC_RUNNING, ssh connection: $SSH_CONNECTION, steam: $STEAM_RUNNING"
      if [[ $CLAUDE_RUNNING -eq 0 && $CODEX_RUNNING -eq 0 && $PI_RUNNING -eq 0 && $OPENCODE_RUNNING -eq 0 && $DS4_RUNNING -eq 0 && $MUSIC_RUNNING -eq 0 && $SSH_CONNECTION -eq 0 && $STEAM_RUNNING -eq 0 ]]; then
        echo "Suspending..."
        ${pkgs.systemd}/bin/systemctl suspend
        # Woken up. If it was user input, swayidle's resumeCommand stops
        # this unit; if woken remotely (WoL), keep looping so the machine
        # suspends again once idle work drains.
        ${pkgs.coreutils}/bin/sleep 60
      else
        echo "Not suspending."
      fi
      ${pkgs.coreutils}/bin/sleep 600
    done
  '';
in {
  config = mkIf cfg.enable {
    services.swayidle = {
      enable = true;
      systemdTargets = ["niri.service"];
      events = {
        after-resume = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      };
      timeouts = [
        {
          timeout = 900;
          command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        }
        {
          timeout = 2700;
          command = "${pkgs.systemd}/bin/systemd-run --user --collect --unit=idle-suspend-loop ${idle-suspend-loop}/bin/idle-suspend-loop";
          resumeCommand = "${pkgs.systemd}/bin/systemctl --user stop idle-suspend-loop.service";
        }
      ];
    };

    # Override systemd unit to wait for niri and handle restarts gracefully
    systemd.user.services.swayidle = {
      Unit = {
        After = ["niri.service"];
        Requires = ["niri.service"];
      };
      Service = {
        RestartSec = 3;
      };
    };
  };
}
