{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  # An instance of `pkgs` with your overlays and packages applied is also available.
  # You also have access to your flake's inputs.
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];
  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/curtbushko/.config/sops/age/keys.txt";

  # this is a little more manual than I'd like but it works and is easy to grow
  sops.secrets."hosts/gamingrig/syncthing_id" = {};
  sops.secrets."hosts/m1/syncthing_id" = {};
  sops.secrets."hosts/m1-pro/syncthing_id" = {};
}
