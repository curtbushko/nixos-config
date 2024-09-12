{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format, # A normalized name for the system target (eg. `iso`).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = with config.lib.stylix.colors.withHashtag; {
      add_newline = true;
      command_timeout = 2000;
      # gradient from dark grey to light grey (black rebel), light blue (white text), dark grey (blue text)
      format = "[░▒▓](${base06})[  ](bg:${base06} fg:${base01})$hostname[](bg:${base0D} fg:${base06})$directory[](fg:${base0D} bg:${base03})$git_branch$git_status[](fg:${base03} bg:${base02})$golang[](fg:${base02} bg:${base00})$character";
      hostname = {
        format = "[ @$hostname ]($style)";
        ssh_only = true;
        style = "bg:${base06} fg:${base01}";
      };
      directory = {
        truncation_symbol = "…/";
        truncation_length = 3;
        format = "[ $path ]($style)";
        style = "fg:${base06} bg:${base0D}";
      };
      directory.substitutions = {
        "Documents" = "󰈙 ";
        "Downloads" = " ";
        "Music" = " ";
        "Pictures" = " ";
        "ghostty" = "󰊠";
        "consul-k8s" = "󱃾";
        "nixos-config" = "󱄅";
        "github.com/curtbushko" = "";
      };
      git_branch = {
        symbol = "";
        only_attached = true;
        format = "[[ $symbol $branch ](fg:${base0D} bg:${base03})]($style)";
        style = "bg:${base03}";
      };
      git_status = {
        style = "bg:${base03}";
        format = "[[($all_status$ahead_behind )](fg:${base0D} bg:${base03})]($style)";
      };
      golang = {
        symbol = "";
        style = "bg:${base02}";
        format = "[[ $symbol ($version) ](fg:${base0D} bg:${base02})]($style)";
      };
    };
  };
}
