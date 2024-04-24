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
  jira-ls = pkgs.writeShellScriptBin "jira-ls" ''
#!/bin/bash

SEARCH_QUERY='jira issue list -a$(jira me) --plain --columns id,summary,status' 
FZF_DEFAULT_COMMAND=$SEARCH_QUERY fzf \
  --preview-window=top,60%,border-sharp \
  --reverse \
  --border=none \
  --preview-label='PREVIEW' \
  --bind "j:down,k:up,q:abort" \
  --bind 'e:execute(jira issue edit {1})'\
  --bind 'm:execute(jira issue move {1})' \
  --preview='jira issue view {1}'
'';
in {
  home.packages =
  [
    jira-ls
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
