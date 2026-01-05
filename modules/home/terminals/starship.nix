{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.terminals;
  colors = lib.importJSON ../../home/styles/${config.curtbushko.theme.name}.json;
  a_bg = colors.statusline_a_bg;
  a_fg = colors.statusline_a_fg;
  b_bg = colors.statusline_b_bg;
  b_fg = colors.statusline_b_fg;
  c_bg = colors.statusline_c_bg;
  c_fg = colors.statusline_c_fg;
in {
  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = true;
        command_timeout = 2000;
        # The  is a mix of what section came first and after
        format = "[  ░▒▓](${a_bg})[](bg:${a_bg} fg:${a_fg})\${custom.hostname_fixed}[ ](bg:${b_bg} fg:${a_bg})\${custom.worktree}[](fg:${b_bg}
        bg:${c_bg})$git_branch$git_status[](fg:${c_bg})$character";
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
            len=''${#name}
            space=11
            left=$(( (space - len) / 2 ))
            right=$(( space - len - left ))
            printf '%s%*s%s%*s\u200B' "$icon" "$left" "" "$name" "$right" ""
          '';
          format = "[ $output ]($style)";
          when = "true";  # ssh_only = false equivalent
          style = "bg:${a_bg} fg:${a_fg}";
        };
        custom.worktree = {
          command = ''
            git_common=$(git rev-parse --git-common-dir 2>/dev/null)
            if [ -n "$git_common" ]; then
              # In a git repository or worktree
              icon="󰊢 "
              # Check if this is a worktree by looking for .bare in the path
              if echo "$git_common" | grep -q '\.bare'; then
                # In a worktree - use dirname of git_common
                name=$(basename "$(dirname "$git_common")")
              else
                # In normal repo - use toplevel directory name
                name=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
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

            len=''${#name}
            space=11
            left=$(( (space - len) / 2 ))
            right=$(( space - len - left ))
            printf '%s%*s%s%*s\u200B' "$icon" "$left" "" "$name" "$right" ""
          '';
          format = "[$output ]($style)";
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
