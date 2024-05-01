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
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    defaultKeymap = "viins";
    enableVteIntegration = true;
    history.expireDuplicatesFirst = true;
    history.ignoreDups = true;
    # these become shortcuts like cd ~docs
    dirHashes = {
      docs = "$HOME/Documents";
      vids = "$HOME/Videos";
      dl = "$HOME/Downloads";
      nixos-config = "$HOME/workspace/github.com/curtbushko/nixos-config";
      ghostty = "$HOME/workspace/github.com/mitchellh/ghostty";
    };
    # environment variables
    sessionVariables = {
      BUSHKO = "$HOME/workspace/github.com/curtbushko";
      DDCCTL = "$HOME/.dotfiles/bin/m1ddc";
      DOTFILES = "$HOME/.dotfiles";
      GHOSTTY = "$HOME/workspace/github.com/mitchellh/ghostty";
      GITHUB = "$HOME/workspace/github.com";
      KB = "$HOME/Sync/KB";
      NIXOS_CONFIG = "$HOME/workspace/github.com/curtbushko/nixos-config";
      SYNCTHING = "$HOME/Sync";
      WORKSPACE = "$HOME/workspace";
      WALLPAPERS = "$HOME/Sync/wallpapers";
      ZIGBIN = "$HOME/bin/zig";
    };
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      mdkir = "mkdir";
      cat = "bat";
      za = "zoxide add";
      zr = "zoxide remove";
      foodirs = "echo FOO=$FOO, BAR=$BAR, BAZ=$BAZ";
      foo = "export FOO=$PWD; foodirs";
      bar = "export BAR=$PWD; foodirs";
      baz = "export BAZ=$PWD; foodirs";
      srcdirs = "echo SRC=$SRC, DEST=$DEST";
      src = "export SRC=$PWD; srcdirs";
      dest = "export DEST=$PWD; srcdirs";
      cdsrc = "cd $SRC";
      cddest = "cd $DEST";
      cdfoo = "cd $FOO";
      cdbar = "cd $BAR";
      cdbaz = "cd $BAZ";
      cdworkspace = "cd $WORKSPACE";
      cdgithub = "cd $GITHUB";
      cdghostty = "cd $GHOSTTY";
      cdleetcode = "cd $BUSHKO/leetcode";
      cddemo = "cd $BUSHKO/cni-demo";
      cdbushko = "cd $BUSHKO";
      cdkb = "cd $KB";
      cdsync = "cd $SYNC";
      cddot = "cd $DOTFILES";
      cddotfiles = "cd $DOTFILES";
      cdnvim = "cd $DOTFILES/nvim/.config/nvim";
      cdnixosconfig = "cd $NIXOS_CONFIG";
      cdhashi = "cd $GITHUB/hashicorp";
      cdk8s = "cd $GITHUB/hashicorp/consul-k8s";
      cdconsul = "cd $GITHUB/hashicorp/consul";
      cddataplane = "cd $GITHUB/hashicorp/consul-dataplane";
      cdworkflows = "cd $GITHUB/hashicorp/consul-k8s-workflows";
      cls = "tput reset";
      gitreset = "git reset --hard HEAD^";
      ghostty-release = "zig build -Dstatic=true -Doptimize=ReleaseFast && direnv deny && cd macos && xcodebuild -target Ghostty -configuration Release";
      gs = "git status";
      pr = "gh pr view --web";
      hg = "history |grep $1";
      gaa = "git add -A";
      gp = "echo 'Pulling... ' && git pull";
      gP = "echo 'Pushing...' && git push --set-upstream origin $(git branch --show-current)";
      gcm = "git commit --message";
      gcmsg = "git commit --message";
      gwta = ". git-worktree-add";
      gwts = ". git-worktree-switch";
      gwtc = ". git-worktree-clone-bare";
      gwtclone = ". git-worktree-clone-bare";
      gwtr = ". git-worktree-checkout-remote";
      gwtcr = ". git-worktree-checkout-remote";
      kube = "kubectl";
      kubeclt = "kubectl";
      k = "kubectl";
      kaf = "kubectl apply -f";
      kdf = "kubectl delete -f";
      kev = "kubectl get events --sort-by='.metadata.creationTimestamp' -A -o custom-columns=FirstSeen:.firstTimestamp,Count:.count,From:.source.component,Type:.type,Reason:.reason,Message:.message";
      kgp = "kubectl get pods";
      kdp = "kubectl describe pod";
      kdel = "kubectl delete";
      klogs = "kubectl get logs -f";
      kns = "kubectl get namespaces";
      kubedebug = "kubectl run -i --tty curt-kubedebug --image=alpine -- bash";
      lg = "lazygit";
      ls = "eza -lao --ignore-glob=.DS_Store --icons=always";
      reload = "source ~/.zshrc";
      tf = "terraform";
      tree = "eza -aT --git-ignore --ignore-glob=.git --icons=always";
      vi = "nvim";
      vim = "nvim";
      weather = "curl wttr.in/kitchener";
      weztitle = "wezterm cli set-tab-title";
      # monitor switching
      work = "ddcutil setvcp 60 0x1b";
      home = "$DDCCTL set input 17";
      pc = "wakeonlan e8:9c:25:c3:da:13; $DDCCTL set input 15";
      # ssh machines
      sshgamingrig = "wakeonlan e8:9c:25:c3:da:13; ssh curtbushko@gamingrig.basilisk-jazz.ts.net";
      sshm1 = "ssh curtbushko@m1-air.basilisk-jazz.ts.net";
      # zellij things
      zattach = "zellij attach coding";
      zux = "zellij -s coding";
      zdel = "zellij delete-session coding";
      ztitle = "zellij action rename-tab";
      zkill = "zellij kill-session coding";
    };
    initExtra = ''
      if [ ! -L $HOME/.local/bin/ghostty ]; then
      	ln -s $GHOSTTY/zig-out/bin/ghostty $HOME/.local/bin/ghostty 
      fi
      if [ -f $HOME/.private.post.source ]; then
          source $HOME/.private.post.source
      fi
    '';
  };
}
