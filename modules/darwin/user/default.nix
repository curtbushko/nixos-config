{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf getExe;
  inherit (lib.internal) mkOpt;

  cfg = config.curtbushko.user;
in
{
  options.curtbushko.user = {
    name = mkOpt types.str "curtbushko" "The user account.";
    email = mkOpt types.str "cbushko@gmail.com" "The email of the user.";
    fullName = mkOpt types.str "Curt Bushko" "The full name of the user.";
    uid = mkOpt (types.nullOr types.int) 501 "The uid for the user account.";
  };

  config = {
    users.users.${cfg.name} = {
      uid = mkIf (cfg.uid != null) cfg.uid;
      shell = pkgs.zsh;
    };

  };
}
