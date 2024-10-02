{pkgs, ...}: {
  programs.go = {
    enable = true;
  };

  home.packages = [
    pkgs.gopls
    pkgs.golangci-lint
    pkgs.gotestsum
  ];
}
