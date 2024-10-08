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
}: {
  programs.git = {
    enable = true;
    userName = "Curt Bushko";
    userEmail = "cbushko@gmail.com";
    ignores = ["*~" ".DS_Store" ".direnv" ".env" ".rgignore" ".aider*"];
    extraConfig = {
      init = {defaultBranch = "main";};
      push.autoSetupRemote = true;
      pull = {ff = "only";};
      url."ssh://git@github.com".insteadOf = "https://github.com";
      oh-my-zsh = {hide-dirty = "1";}; # this stops slowdowns in some repos with zsh
      submodule.recurse = true;
    };
    delta = {
      enable = true;
      options = {
        side-by-side = true;
        line-numbers = true;
        decorations = {
          commit-decoration-style = "blue ol";
          hunk-header-decoration-style = "blue box";
          hunk-header-file-style = "blue";
          hunk-header-line-number-style = "#ff9e64";
          hunk-header-style = "file line-number";
          file-decoration-style = "none";
          file-style = "bold yellow ul";
          minus-style = "red";
          minus-emph-style = "#ff5370";
          plus-style = "green";
          zero-style = "white";
          commit-style = "raw";
          line-numbers-minus-style = "red";
          line-numbers-plus-style = "green";
          line-numbers-zero-style = "purple";
        };
        features = "decorations, syntax-theme, line-numbers";
        whitespace-error-style = "22 reverse";
      };
    };
    aliases = {
      addp = "add -p";
      al = "!git config --get-regexp 'alias.*' | colrm 1 6 | sed 's/[ ]/ = /'";
      as = "update-index --assume-unchanged";
      br = "checkout";
      ci = "commit";
      co = "checkout";
      cp = "cherry-pick";
      di = "diff";
      dif = "diff";
      diffs = "diff --cached";
      gerp = "grep";
      grpe = "grep";
      hist = "log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short";
      nas = "update-index --no-assume-unchanged";
      pub = "push -u origin HEAD";
      pullf = "pull --ff-only";
      shoe = "show";
      st = "status";
    };
  };

  home.packages = [
    pkgs.gh
    pkgs.lazygit
    pkgs.git-lfs
  ];
}
