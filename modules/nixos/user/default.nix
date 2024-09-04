{
  inputs,
  pkgs,
  ...
}: {
  environment.localBinInPath = true;

  programs.zsh.enable = true;

  users.users.curtbushko = {
    isNormalUser = true;
    home = "/home/curtbushko";
    extraGroups = ["input" "networkmanager" "docker" "wheel" "i2c" "jackaudio"];
    shell = pkgs.zsh;
  };

  # Keep in async with vm-shared.nix. (todo: pull this out into a file)
  nix = {
    # We need to enable flakes
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';

    settings = {
      trusted-public-keys = [
        nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
        cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
      ];
      trusted-substituters = [
        https://nix-community.cachix.org
        https://cache.nixos.org
      ];
      trusted-users = ["root" "@wheel"];
    };
  };
}
