let
  flake = builtins.getFlake ("git+file:" + toString ./../../../..);
  lib = flake.inputs.nixpkgs.lib;
  minimum = "2.56.1";
  hosts = [
    {
      scope = "darwin/m4-pro";
      package = flake.darwinConfigurations.m4-pro.config.home-manager.users.curtbushko.programs.git.package;
    }
    {
      scope = "nixos/gamingrig";
      package = flake.nixosConfigurations.gamingrig.config.home-manager.users.curtbushko.programs.git.package;
    }
  ];
  shells =
    lib.mapAttrsToList (system: shell: {
      scope = "devShell/" + system;
      package = builtins.head (builtins.filter (p: (p.pname or "") == "git") shell.default.nativeBuildInputs);
    })
    (builtins.removeAttrs flake.devShells [
      # nixpkgs 26.11 no longer evaluates this legacy platform.
      "x86_64-darwin"
    ]);
in
  builtins.map (sample:
    assert lib.assertMsg (lib.versionAtLeast sample.package.version minimum)
    "${sample.scope}: expected Git >= ${minimum}, got ${sample.package.version}"; {
      inherit (sample) scope;
      inherit (sample.package) version;
    }) (hosts ++ shells)
