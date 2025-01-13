{
  lib,
  pkgs,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;

  aocgen = pkgs.writeScriptBin "aocgen" (builtins.readFile ./aocgen);
  auto-sleep = pkgs.writeScriptBin "auto-sleep" (builtins.readFile ./auto-sleep);
  build-ghostty = pkgs.writeScriptBin "build-ghostty" (builtins.readFile ./build-ghostty);
  containerwatcher = pkgs.writeScriptBin "containerwatcher" (builtins.readFile ./containerwatcher);
  context = pkgs.writeScriptBin "context" (builtins.readFile ./context);
  daily-note = pkgs.writeScriptBin "daily-note" (builtins.readFile ./daily-note);
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
  leetgen = pkgs.writeScriptBin "leetgen" (builtins.readFile ./leetgen);
  makelintwatcher = pkgs.writeScriptBin "makelintwatcher" (builtins.readFile ./makelintwatcher);
  makeunitwatcher = pkgs.writeScriptBin "makeunitwatcher" (builtins.readFile ./makeunitwatcher);
  new-note = pkgs.writeScriptBin "new-note" (builtins.readFile ./new-note);
  nodewatcher = pkgs.writeScriptBin "nodewatcher" (builtins.readFile ./nodewatcher);
  open-file = pkgs.writeScriptBin "open-file" (builtins.readFile ./open-file);
  pdf-clean = pkgs.writeScriptBin "pdf-clean" (builtins.readFile ./pdf-clean);
  pod-failed-cleanup = pkgs.writeScriptBin "pod-failed-cleanup" (builtins.readFile ./pod-failed-cleanup);
  pod-security-context = pkgs.writeScriptBin "pod-security-context" (builtins.readFile ./pod-security-context);
  podwatcher = pkgs.writeScriptBin "podwatcher" (builtins.readFile ./podwatcher);
  podwatcherwide = pkgs.writeScriptBin "podwatcherwide" (builtins.readFile ./podwatcherwide);
  postscript-man = pkgs.writeScriptBin "postscript-man" (builtins.readFile ./postscript-man);
  pr-create = pkgs.writeScriptBin "pr-create" (builtins.readFile ./pr-create);
  pr-review = pkgs.writeScriptBin "pr-review" (builtins.readFile ./pr-review);
  pr-view = pkgs.writeScriptBin "pr-view" (builtins.readFile ./pr-view);
  snippet = pkgs.writeScriptBin "snippet" (builtins.readFile ./snippet);
  tailssh = pkgs.writeScriptBin "tailssh" (builtins.readFile ./tailssh);
  ollama-up = pkgs.writeScriptBin "ollama-up" (builtins.readFile ./ollama-up);
  zigbuildwatcher = pkgs.writeScriptBin "zigbuildwatcher" (builtins.readFile ./zigbuildwatcher);
in {
  home.packages =
    [
      aocgen
      build-ghostty
      containerwatcher
      context
      daily-note
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
      leetgen
      makelintwatcher
      makeunitwatcher
      new-note
      nodewatcher
      ollama-up
      open-file
      pdf-clean
      pod-failed-cleanup
      pod-security-context
      podwatcher
      podwatcherwide
      postscript-man
      pr-create
      pr-review
      pr-view
      snippet
      tailssh
      zigbuildwatcher
    ]
    ++ (lib.optionals isLinux [
      auto-sleep
      hyprstart
    ]);
}
