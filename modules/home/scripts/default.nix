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

  aocgen = pkgs.writeScriptBin "aocgen" (builtins.readFile ./aocgen);
  auto-sleep = pkgs.writeScriptBin "auto-sleep" (builtins.readFile ./auto-sleep);
  build-ghostty = pkgs.writeScriptBin "build-ghostty" (builtins.readFile ./build-ghostty);
  containerwatcher = pkgs.writeScriptBin "containerwatcher" (builtins.readFile ./containerwatcher);
  context = pkgs.writeScriptBin "context" (builtins.readFile ./context);
  docker-clean = pkgs.writeScriptBin "docker-clean" (builtins.readFile ./docker-clean);
  docker-image-dates = pkgs.writeScriptBin "docker-image-dates" (builtins.readFile ./docker-image-dates);
  epub-to-mobi = pkgs.writeScriptBin "epub-to-mobi" (builtins.readFile ./epub-to-mobi);
  file-preview = pkgs.writeScriptBin "file-preview" (builtins.readFile ./file-preview);
  ghostty-update = pkgs.writeScriptBin "ghostty-update" (builtins.readFile ./ghostty-update);
  git-checkout = pkgs.writeScriptBin "git-checkout" (builtins.readFile ./git-checkout);
  git-diff = pkgs.writeScriptBin "git-diff" (builtins.readFile ./git-diff);
  git-log = pkgs.writeScriptBin "git-log" (builtins.readFile ./git-log);
  git-migrate-to-new-branch = pkgs.writeScriptBin "git-migrate-to-new-branch" (builtins.readFile ./git-migrate-to-new-branch);
  git-open = pkgs.writeScriptBin "git-open" (builtins.readFile ./git-open);
  git-recent = pkgs.writeScriptBin "git-recent" (builtins.readFile ./git-recent);
  git-stats = pkgs.writeScriptBin "git-stats" (builtins.readFile ./git-stats);
  git-switch = pkgs.writeScriptBin "git-switch" (builtins.readFile ./git-switch);
  git-worktree-add = pkgs.writeScriptBin "git-worktree-add" (builtins.readFile ./git-worktree-add);
  git-worktree-bare-clone = pkgs.writeScriptBin "git-worktree-bare-clone" (builtins.readFile ./git-worktree-bare-clone);
  git-worktree-checkout-remote = pkgs.writeScriptBin "git-worktree-checkout-remote" (builtins.readFile ./git-worktree-checkout-remote);
  git-worktree-switch = pkgs.writeScriptBin "git-worktree-switch" (builtins.readFile ./git-worktree-switch);
  gke-delete-node = pkgs.writeScriptBin "gke-delete-node" (builtins.readFile ./gke-delete-node);
  gobuildwatcher = pkgs.writeScriptBin "gobuildwatcher" (builtins.readFile ./gobuildwatcher);
  gotestwatcher = pkgs.writeScriptBin "gotestwatcher" (builtins.readFile ./gotestwatcher);
  helm-nuke = pkgs.writeScriptBin "helm-nuke" (builtins.readFile ./helm-nuke);
  hyprstart = pkgs.writeScriptBin "hyprstart" (builtins.readFile ./hyprstart);
  jira-ls = pkgs.writeScriptBin "jira-ls" (builtins.readFile ./jira-ls);
  kubewatcher = pkgs.writeScriptBin "kubewatcher" (builtins.readFile ./kubewatcher);
  makelintwatcher = pkgs.writeScriptBin "makelintwatcher" (builtins.readFile ./makelintwatcher);
  makeunitwatcher = pkgs.writeScriptBin "makeunitwatcher" (builtins.readFile ./makeunitwatcher);
  nodewatcher = pkgs.writeScriptBin "nodewatcher" (builtins.readFile ./nodewatcher);
  open-file = pkgs.writeScriptBin "open-file" (builtins.readFile ./open-file);
  pod-failed-cleanup = pkgs.writeScriptBin "pod-failed-cleanup" (builtins.readFile ./pod-failed-cleanup);
  pod-security-context = pkgs.writeScriptBin "pod-security-context" (builtins.readFile ./pod-security-context);
  podwatcher = pkgs.writeScriptBin "podwatcher" (builtins.readFile ./podwatcher);
  podwatcherwide = pkgs.writeScriptBin "podwatcherwide" (builtins.readFile ./podwatcherwide);
  postscript-man = pkgs.writeScriptBin "postscript-man" (builtins.readFile ./postscript-man);
  pr-create = pkgs.writeScriptBin "pr-create" (builtins.readFile ./pr-create);
  pr-review = pkgs.writeScriptBin "pr-review" (builtins.readFile ./pr-review);
  pr-view = pkgs.writeScriptBin "pr-view" (builtins.readFile ./pr-view);
  suspend-script = pkgs.writeScriptBin "suspend-script" (builtins.readFile ./suspend-script);
  zigbuildwatcher = pkgs.writeScriptBin "zigbuildwatcher" (builtins.readFile ./zigbuildwatcher);
in {
  home.packages =
    [
      aocgen
      build-ghostty
      containerwatcher
      context
      docker-clean
      docker-image-dates
      epub-to-mobi
      file-preview
      ghostty-update
      git-checkout
      git-diff
      git-log
      git-migrate-to-new-branch
      git-open
      git-recent
      git-stats
      git-switch
      git-worktree-add
      git-worktree-bare-clone
      git-worktree-checkout-remote
      git-worktree-switch
      gke-delete-node
      gobuildwatcher
      gotestwatcher
      helm-nuke
      jira-ls
      kubewatcher
      makelintwatcher
      makeunitwatcher
      nodewatcher
      open-file
      pod-failed-cleanup
      pod-security-context
      podwatcher
      podwatcherwide
      postscript-man
      pr-create
      pr-review
      pr-view
      suspend-script
      zigbuildwatcher
    ]
    ++ (lib.optionals isLinux [
      auto-sleep
      hyprstart
    ]);
}
