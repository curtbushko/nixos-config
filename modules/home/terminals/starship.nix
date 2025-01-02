{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.terminals;
  #colors = import ../../home/styles/tokyo-night-neon.nix {};
  colors = import ../../home/styles/rebel-scum.nix {};
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
        format = "[░▒▓](${a_bg})[  ](bg:${a_bg} fg:${a_fg})$hostname[](bg:${b_bg} fg:${a_bg})$directory[](fg:${b_bg}
        bg:${c_bg})$git_branch$git_status[](fg:${c_bg})$character";
        hostname = {
          format = "[ @$hostname ]($style)";
          ssh_only = true;
          style = "bg:${a_bg} fg:${a_fg}";
        };
        directory = {
          truncation_symbol = "…/";
          truncation_length = 3;
          format = "[ $path ]($style)";
          style = "fg:${b_fg} bg:${b_bg}";
        };
        directory.substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
          "ghostty" = "󰊠 ";
          "consul-k8s" = "󱃾 ";
          "nixos-config" = "󱄅 ";
          "github.com/curtbushko" = " ";
          "neovim-flake" = " ";
          "terraform" = "󱁢 ";
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
