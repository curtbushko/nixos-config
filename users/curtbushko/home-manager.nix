{ pkgs, config, user, nix-colors, ... }: {
    home.username = "${user}"; 
    home.homeDirectory = "/Users/${user}"; 
    home.stateVersion = "22.11";
    programs.home-manager.enable = true;

    imports = [
        nix-colors.homeManagerModules.default
        ./modules/git.nix
        ./modules/go.nix
        ./modules/packages.nix
        ./modules/zsh.nix
        ./modules/bat.nix
    ];
    colorScheme = nix-colors.colorSchemes.tokyo-night-terminal-dark;

}
