# Run with nix eval --json --file modules/home/terminals/tests/removed-tools.nix
let
  lib = {
    types.bool = "bool";
    mkOption = value: value;
    mkIf = condition: value:
      if condition
      then value
      else {};
    optionalAttrs = condition: value:
      if condition
      then value
      else {};
  };
  terminals = import ../default.nix {inherit lib;};
  imports = map builtins.baseNameOf terminals.imports;
  aliasesFor = isLinux:
    (import ../../shells/zsh.nix {
      inherit lib;
      config.ns.shells.enable = true;
      pkgs.stdenv.hostPlatform = {
        inherit isLinux;
        isDarwin = !isLinux;
      };
    }).config.programs.zsh.shellAliases;
  niri = import ../../wm/niri.nix {
    inherit lib;
    inputs.niri.homeModules.niri = {};
    config.ns.wm.niri.enable = true;
    pkgs = {
      alacritty = "alacritty";
      niri = "niri";
      swaybg = "swaybg";
      swayidle = "swayidle";
      xwayland-satellite = "xwayland-satellite";
      playerctl = "playerctl";
    };
  };
in
  assert imports == ["ghostty.nix" "rex.nix" "starship.nix"];
  assert !(builtins.pathExists ../alacritty.nix);
  assert !(builtins.pathExists ../tmux.nix);
  assert !(builtins.elem "alacritty" niri.config.home.packages);
  assert builtins.all (isLinux: let
    aliases = aliasesFor isLinux;
  in
    builtins.all (name: !(builtins.hasAttr name aliases)) ["tattach" "tkill" "tux" "mux" "tdetach"]
    && aliases.vi == "nvim") [true false]; true
