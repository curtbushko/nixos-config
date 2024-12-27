{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.browsers;
  isLinux = pkgs.stdenv.isLinux;
in
{
  options.curtbushko.browsers = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable browsers
      '';
    };
  };

  imports = [
    ./firefox.nix
  ];

  config = mkIf cfg.enable {
    home.packages =
    [
    ]
    ++ (lib.optionals isLinux [
      inputs.zen-browser.packages.${system}.default
    ]);
  };
}
