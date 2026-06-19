{lib, ...}: let
  inherit (lib) types mkOption;
in {
  options.curtbushko.services.llm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable NixOS llm services (ollama)
      '';
    };
  };

  imports = [
    ./llm.nix
    ./cuda.nix
  ];
}
