let
  caches = import ../../../shared/nix-caches.nix;
  module = import ../default.nix {
    config = {
      nix.enable = false;
      ns.nixCaches.enable = true;
    };
    lib = {
      mkEnableOption = _: {};
      mkIf = condition: value:
        if condition
        then value
        else {};
      concatStringsSep = builtins.concatStringsSep;
    };
    pkgs = {
      bash = "/test/bash";
      gnugrep = "/test/grep";
    };
  };
  text = module.config.environment.etc."nix/nix.repo-caches.conf".text;
  contains = needle: haystack: builtins.replaceStrings [needle] [""] haystack != haystack;
in
  assert builtins.length caches.substituters == 6;
  assert builtins.length caches.trusted-public-keys == 6;
  assert builtins.all (url: contains url text) caches.substituters;
  assert builtins.all (key: contains key text) caches.trusted-public-keys;
  assert contains "extra-substituters =" text;
  assert contains "extra-trusted-public-keys =" text;
  assert !(module.config.environment.etc ? "nix/nix.custom.conf");
  assert contains "nix-cache-include" module.config.system.activationScripts.postActivation.text; true
