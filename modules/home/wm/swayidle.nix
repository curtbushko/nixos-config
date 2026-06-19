{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm.niri;
  suspend-script = pkgs.writeShellScriptBin "suspend-script" ''
    #!/usr/bin/env bash

    # Give people time to login before trying to shut down right away
    ${pkgs.coreutils}/bin/sleep 30

    count_processes() {
      ${pkgs.procps}/bin/ps -eo comm,args \
        | ${pkgs.gnugrep}/bin/grep -Ei "$1" \
        | ${pkgs.gnugrep}/bin/grep -Ev "grep|suspend-script" \
        | ${pkgs.coreutils}/bin/wc -l \
        | ${pkgs.findutils}/bin/xargs
    }

    # only suspend if LLM agents are not running
    CLAUDE_RUNNING=$(count_processes '(^|[ /])(claude)( |$)')
    CODEX_RUNNING=$(count_processes '(^|[ /])(codex|cdx)( |$)')
    PI_RUNNING=$(count_processes '(^|[ /])(pi|pi-coding-agent|coding-agent)( |$)')
    OPENCODE_RUNNING=$(count_processes '(^|[ /])(opencode|oc)( |$)')
    DS4_RUNNING=$(count_processes '(^|[ /])(ds4|ds4-server|ds4-bench|ds4-eval)( |$)')

    # only suspend if audio is not running
    MUSIC_RUNNING=$(${pkgs.pipewire}/bin/pw-cli i all 2>&1 | ${pkgs.ripgrep}/bin/rg running -q)

    # only suspend if steam is not running
    STEAM_RUNNING=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -i "steam.sh" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )
  
    # only suspend if no ssh connections
    SSH_CONNECTION=$(${pkgs.iproute2}/bin/ss | ${pkgs.gnugrep}/bin/grep ssh | ${pkgs.gnugrep}/bin/grep ESTAB | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )

    # only suspend if not converting pdfs. Also, ignore grep to stop a false positive
    #convert_pdfs=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -i "convert-pdfs.sh" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )
 
    echo "claude running: $CLAUDE_RUNNING, codex running: $CODEX_RUNNING, pi running: $PI_RUNNING, opencode running: $OPENCODE_RUNNING, ds4 running: $DS4_RUNNING, music running: $MUSIC_RUNNING, ssh connection: $SSH_CONNECTION, steam: $STEAM_RUNNING"
    if [[ $CLAUDE_RUNNING -eq 0 && $CODEX_RUNNING -eq 0 && $PI_RUNNING -eq 0 && $OPENCODE_RUNNING -eq 0 && $DS4_RUNNING -eq 0 && $MUSIC_RUNNING -eq 0 && $SSH_CONNECTION -eq 0 && $STEAM_RUNNING -eq 0 ]]; then
      ${pkgs.coreutils}/bin/sleep 10
      ${pkgs.systemd}/bin/systemctl suspend
       echo "Suspending..."
    else
       echo "Not suspending."
    fi
  '';
in {
  config = mkIf cfg.enable {
    services.swayidle = {
      enable = true;
      systemdTargets = ["graphical-session.target"];
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
          command = ''${pkgs.coreutils}/bin/sleep 10; ${suspend-script}/bin/suspend-script'';
        }
      ];
    };
  };
}
