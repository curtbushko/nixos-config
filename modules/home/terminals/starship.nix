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
  programs.starship = let
    inherit (inputs.nix-colors.lib.conversions) hexToRGBString;
    toRGBA = color: opacity: "rgba(${hexToRGBString "," (lib.removePrefix "#" color)},${opacity})";
    colors = config.colorScheme.palette;
  in {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 2000;
      format = "[░▒▓](#a3aed2)[  ](bg:#a3aed2 fg:#090c0c)$hostname[](bg:#769ff0 fg:#a3aed2)$directory[](fg:#769ff0 bg:#394260)$git_branch$git_status[](fg:#394260 bg:#212736)$golang[](fg:#212736 bg:#1d2230)$character";
      hostname = {
        format = "[ @$hostname ]($style)";
        ssh_only = true;
        style = "bg:#a3aed2 fg:#090c0c";
      };
      directory = {
        truncation_symbol = "…/";
        truncation_length = 3;
        format = "[ $path ]($style)";
        style = "fg:#e3e5e5 bg:#769ff0";
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
        format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
        style = "bg:#394260";
      };
      git_status = {
        style = "bg:#394260";
        format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)";
      };
      golang = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };
    };
  };
}
