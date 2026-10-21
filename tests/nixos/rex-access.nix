# Host intent can be checked without evaluating macOS packages on Linux.
let
  work = import (../../homes + "/aarch64-darwin/curtbushko@curtbushko-K4W6XK6XND/default.nix") {
    pkgs = {};
    inputs = {};
  };
in
  assert !work.ns.terminals.rex.lan.enable; true
