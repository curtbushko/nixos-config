{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.terminals;

  # Read colors from flair's style.json in ~/.config/flair/
  # Note: Requires --impure flag for nix build/home-manager switch
  flairStylePath = "${config.home.homeDirectory}/.config/flair/style.json";

  # Default fallback colors if flair style.json doesn't exist
  defaultColors = {
    "statusline-a-bg" = "#1d2021";
    "statusline-a-fg" = "#d4be98";
    "statusline-b-bg" = "#282828";
    "statusline-b-fg" = "#d4be98";
    "statusline-c-bg" = "#3c3836";
    "statusline-c-fg" = "#a9b665";
  };

  colors = if builtins.pathExists flairStylePath
           then builtins.fromJSON (builtins.readFile flairStylePath)
           else defaultColors;

  a_bg = colors."statusline-a-bg";
  a_fg = colors."statusline-a-fg";
  b_bg = colors."statusline-b-bg";
  b_fg = colors."statusline-b-fg";
  c_bg = colors."statusline-c-bg";
  c_fg = colors."statusline-c-fg";
in {
  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = false;
      settings = {
        add_newline = true;
        command_timeout = 2000;
        # The  is a mix of what section came first and after
        format = "[ ░▒▓](${a_bg})[](bg:${a_bg} fg:${a_fg})\${custom.hostname_fixed}[ ](bg:${b_bg} fg:${a_bg})\${custom.worktree}[](fg:${b_bg} bg:${c_bg})$git_branch$git_status[](fg:${c_bg})$character";
        custom.hostname_fixed = {
          command = ''
            h=$(hostname)
            case "$h" in
              curtbushko-X3FR7279D2) icon=" "; name="work" ;;
              gamingrig) icon=" "; name="gamingrig" ;;
              m4-pro)    icon=" "; name="m4-pro" ;;
              node00)    icon="󱃾 "; name="node00 (k8s)" ;;
              node01)    icon="󱃾 "; name="node01 (k8s)" ;;
              node02)    icon="󱃾 "; name="node02 (k8s)" ;;
              relay)     icon="󰙁 "; name="relay" ;;
              steamdeck) icon=" "; name="steamdeck" ;;
              *)         icon="󰣘 "; name="$h" ;;
            esac
            printf '%s%s' "$icon" "$name"
          '';
          format = "[ $output ]($style)";
          when = "true";
          style = "bg:${a_bg} fg:${a_fg}";
        };
        custom.worktree = {
          command = ''
            export GIT_OPTIONAL_LOCKS=0
            git_common=$(timeout 2s git rev-parse --git-common-dir 2>/dev/null)
            if [ -n "$git_common" ]; then
              # In a git repository or worktree
              icon="󰊢 "
              # Check if this is a worktree by looking for .bare in the path
              if echo "$git_common" | grep -q '\.bare'; then
                # In a worktree - use dirname of git_common
                name=$(basename "$(dirname "$git_common")")
              else
                # In normal repo - use toplevel directory name
                name=$(basename "$(timeout 1s git rev-parse --show-toplevel 2>/dev/null)")
              fi
            else
              # Regular directory (not a git repo)
              icon=" "
              name=$(basename "$PWD")
            fi

            # Apply icon and name mappings (overrides defaults)
            case "$name" in
              consul-k8s)            icon="󱃾 "; name="consul-k8s" ;;
              crusaders)             icon="󱢾 "; name="crusaders" ;;
              Documents)             icon="󰈙 "; name="Documents" ;;
              Downloads)             icon=" "; name="Downloads" ;;
              ghostty)               icon="󰊠 "; name="ghostty" ;;
              kaiju)                 icon="󰺵 "; name="kaiju" ;;
              kb)                    icon="󰧑 "; name="kb" ;;
              Music)                 icon="󰝚 "; name="Music" ;;
              neovim-flake)          icon=" "; name="neovim-flake" ;;
              nixos-config)          icon="󱄅 "; name="nixos-config" ;;
              Pictures)              icon="󰄀 "; name="Pictures" ;;
              terraform)             icon="󱁢 "; name="terraform" ;;
              Videos)                icon=" "; name="Videos" ;;
            esac

            printf '%s%s' "$icon" "$name"
          '';
          format = "[ $output ]($style)";
          when = "true";
          style = "fg:${b_fg} bg:${b_bg}";
        };
        git_branch = {
          symbol = "";
          only_attached = true;
          format = "[ $symbol $branch ]($style)";
          style = "fg:${c_fg} bg:${c_bg}";
        };
        git_status = {
          style = "fg:${c_fg} bg:${c_bg}";
          format = "[ ($all_status$ahead_behind)]($style)";
        };
      };
    };
  };
}
