{
  config,
  lib,
  inputs,
  ...
}: let
  inherit (lib) types mkOption mkIf mkEnableOption;
  cfg = config.curtbushko.networking.stevenBlackHosts;
  alternatesList =
    (lib.optional cfg.blockFakenews "fakenews")
    ++ (lib.optional cfg.blockGambling "gambling")
    ++ (lib.optional cfg.blockPorn "porn")
    ++ (lib.optional cfg.blockSocial "social");
  alternatesPath = "alternates/" + builtins.concatStringsSep "-" alternatesList + "/";
  hostsContent = let
    orig = builtins.readFile (
      "${inputs.stevenblack-hosts}/" + (lib.optionalString (alternatesList != []) alternatesPath) + "hosts"
    );
  in
    orig;
in {
  options.curtbushko.networking.stevenBlackHosts = {
    enable = mkEnableOption "Steven Black's hosts file blocklist on macOS";
    blockFakenews = mkEnableOption "fakenews hosts entries";
    blockGambling = mkEnableOption "gambling hosts entries";
    blockPorn = mkEnableOption "porn hosts entries";
    blockSocial = mkEnableOption "social hosts entries";
  };

  config = mkIf cfg.enable {
    environment.etc."hosts" = {
      text = let
        localhost = ''
          ##
          # Host Database
          #
          # localhost is used to configure the loopback interface
          # when the system is booting.  Do not change this entry.
          ##
          127.0.0.1	localhost
          255.255.255.255	broadcasthost
          ::1             localhost
        '';
      in
        localhost + "\n" + hostsContent;
    };
  };
}
