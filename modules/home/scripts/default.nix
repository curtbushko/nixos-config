{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format, # A normalized name for the system target (eg. `iso`).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;

  my-awesome-script = pkgs.writeShellScriptBin "my-awesome-script" ''
    echo "hello world" | ${pkgs.cowsay}/bin/cowsay | ${pkgs.lolcat}/bin/lolcat
  '';

  auto-sleep = pkgs.writeShellScriptBin "auto-sleep" ''
    logged_in_count=$(who | wc -l)
    # We expect 2 lines of output from `lsof -i:548` at idle: one for output headers, another for the
    # server listening for connections. More than 2 lines indicates inbound connection(s).
    afp_connection_count=$(lsof -i:548 | wc -l)
    if [[ $logged_in_count < 1 && $afp_connection_count < 3 ]]; then
        systemctl suspend
    else
        echo "Not suspending, logged in users: $logged_in_count, connection count: $afp_connection_count"
    fi
  '';
in {
  home.packages =
  [
    my-awesome-script
  ]
  ++ (lib.optionals isLinux [
    auto-sleep
  ]);

  imports = [
    ./aocgen.nix
    ./containerwatcher.nix
    ./context.nix
    ./convert-sh-to-nix.nix
    ./docker-clean.nix
    ./docker-image-dates.nix
    ./epub-to-mobi.nix
    ./file-preview.nix
    ./ghostty-update.nix
    ./git-checkout.nix
    ./git-diff.nix
    ./git-log.nix
    ./git-migrate-to-new-branch.nix
    ./git-open.nix
    ./git-recent.nix
    ./git-stats.nix
    ./git-switch.nix
    ./git-worktree-add.nix
    ./git-worktree-bare-clone.nix
    ./git-worktree-checkout-remote.nix
    ./git-worktree-switch.nix
    ./gke-delete-node.nix
    ./gobuildwatcher.nix
    ./gotestwatcher.nix
    ./helm-nuke.nix
    ./jira-ls.nix
    ./kubewatcher.nix
    ./makelintwatcher.nix
    ./makeunitwatcher.nix
    ./nodewatcher.nix
    ./open-file.nix
    ./pod-failed-cleanup.nix
    ./pod-security-context.nix
    ./podwatcher.nix
    ./podwatcherwide.nix
    ./postscript-man.nix
    ./pr-create.nix
    ./pr-review.nix
    ./pr-view.nix
    ./zigbuildwatcher.nix
  ];


}
