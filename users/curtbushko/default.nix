{ config, pkgs, lib, unstablePkgs, ... }:
{
  home.username = "curtbushko";
  home.homeDirectory = "/Users/curtbushko";
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;

  # list of programs
  # https://mipmip.github.io/home-manager-option-search
  # imports = [
  #   #nix-colors.homeManagerModules.default
  #   ./git.nix
  #   ./go.nix
  #   ./packages.nix
  #   ./bat.nix
  # ];
  #colorScheme = nix-colors.colorSchemes.tokyo-night-terminal-dark;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.htop = {
    enable = true;
    settings.show_program_path = true;
  };

  programs.exa.enable = true;
  programs.exa.enableAliases = true;
  programs.neovim.enable = true;
  programs.nix-index.enable = true;
  programs.zoxide.enable = true;

}
