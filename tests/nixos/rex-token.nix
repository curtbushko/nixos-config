# Home Manager must not treat dotenv key selection as supported by sops-nix.
let
  flake = builtins.getFlake (toString ../..);
  inherit (flake.inputs.nixpkgs) lib;
  module = import ../../modules/home/secrets/default.nix {
    config = {
      ns.secrets.enable = true;
      xdg.configHome = "/test/config";
      sops.placeholder.REX_PACKAGE_TOKEN = "TOKEN_PLACEHOLDER";
      sops.templates.rex-netrc.path = "/test/runtime/rex-netrc";
    };
    inherit lib;
    inputs.sops-nix.homeManagerModules.sops = {};
    pkgs.sops = "/test/sops";
  };
  cfg = module.config.content;
in
  assert !(builtins.hasAttr "REX_PACKAGE_TOKEN" cfg.sops.secrets);
  assert !(builtins.hasAttr "templates" cfg.sops);
  assert !(builtins.hasAttr "nix" cfg);
  assert cfg.sops.secrets."secrets.env".format == "dotenv"; true
