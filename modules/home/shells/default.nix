{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.shells;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  options.curtbushko.shells = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable shells
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
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
      };
      # environment variables
      sessionVariables =
        {
          BUSHKO = "$HOME/workspace/github.com/curtbushko";
          KLEIO = "$HOME/workspace/github.com/kleioverse";
          DOTFILES = "$HOME/.dotfiles";
          GHOSTTY = "$HOME/workspace/github.com/ghostty-org/ghostty";
          GITHUB = "$HOME/workspace/github.com";
          KB = "$BUSHKO/kb";
          NIXOS_CONFIG = "$HOME/workspace/github.com/curtbushko/nixos-config";
          SYNCTHING = "$HOME/Sync";
          WORKSPACE = "$HOME/workspace";
          M1DDC = "$HOME/.dotfiles/bin/m1ddc";
        };
      shellAliases =
        {
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          mdkir = "mkdir";
          cat = "bat";
          cda = "zoxide add";
          cdr = "zoxide remove";
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
          dockerlogin = "docker login -u cbushko -p $DOCKER_PAT";
          cls = "tput reset";
          gitreset = "git reset --hard HEAD^";
          ghostty-mac-release = "zig build -Dstatic=true -Doptimize=ReleaseFast && direnv deny && cd macos && xcodebuild -target Ghostty -configuration Release";
          ghostty-linux-release = "zig build -Dstatic=true -Doptimize=ReleaseFast";
          ghostty-linux-debug = "zig build -Dstatic=true";
          gs = "git status";
          pr = "gh pr view --web";
          hg = "history |grep $1";
          gaa = "git add -A";
          gp = "echo 'Pulling... ' && git pull";
          gP = "echo 'Pushing...' && git push --set-upstream origin \"$(git branch --show-current)\"";
          gcm = "git commit --message";
          gcmsg = "git commit --message";
          gmcsg = "git commit --message";
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
          # ssh machines
          sshm1 = "ssh curtbushko@$M1_TAILNET_ID";
          sshwork = "TERM=xterm-256color ssh curtbushko@$M1_PRO_TAILNET_ID";
          # zellij things
          zattach = "zellij attach coding";
          zux = "zellij -s coding";
          zdel = "zellij delete-session coding --force";
          ztitle = "zellij action rename-tab";
          zkill = "zellij kill-session coding";
          mux = "tmuxinator start home";
          muxkill = "tmux kill-server";
          aid = "aider --no-auto-commits --model ollama/llama3.1:8b";
        }
        # monitor switching
        // lib.optionalAttrs isLinux
        {
          work = "wakeonlan $M1_PRO_MAC_ADDRESS; ddcutil setvcp $DDCUTIL_DISPLAY_INPUT $DDCUTIL_U3419W_USBC --bus 5";
          work2 = "wakeonlan $M1_PRO_MAC_ADDRESS; ddcutil setvcp $DDCUTIL_DISPLAY_INPUT $DDCUTIL_S2721QS_HDMI1 --bus 6";
          workall = "wakeonlan $M1_PRO_MAC_ADDRESS; ddctuil setvcp $DDCUTIL_DISPLAY_INPUT $DDCUTIL_S2721QS_HDMI1 --bus 6; ddcutil setvcp $DDCUTIL_DISPLAY_INPUT $DDCUTIL_U3419W_USBC --bus 5";
          pc = "wakeonlan $GAMINGRIG_MAC_ADDRESS; ddcutil setvcp $DDCUTIL_DISPLAY_INPUT $DDCUTIL_U3419W_DP1 --bus 5";
          pc2 = "wakeonlan $GAMINGRIG_MAC_ADDRESS; ddcutil setvcp $DDCUTIL_DISPLAY_INPUT $DDCUTIL_S2721QS_HDMI2 --bus 6";
          pcall = "wakeonlan $GAMINGRIG_MAC_ADDRESS; ddcutil setvcp $DDCUTIL_DISPLAY_INPUT $DDCUTIL_S2721QS_HDMI2 --bus ddcutil setvcp $DDCUTIL_DISPLAY_INPUT $DDCUTIL_U3419W_DP1 --bus 5";
          steamdeck = "ddcutil setvcp $DDCUTIL_DISPLAY_INPUT $DDCUTIL_U3419W_HDMI1 --bus 5";
        }
        // lib.optionalAttrs isDarwin
        {
          work = "$M1DDC display 1 set input 27";
          work2 = "$M1DDC display 2 set input 17";
          workall = "$M1DDC display 1 set input 27; $M1DDC display 2 set input 17";
          home = "$M1DDC set input 17";
          pc = "wakeonlan $GAMINGRIG_MAC_ADDRESS; sleep 1; $M1DDC display 1 set input 15";
          pc2 = "wakeonlan $GAMINGRIG_MAC_ADDRESS; sleep 1; $M1DDC display 2 set input 18";
          pcall = "wakeonlan $GAMINGRIG_MAC_ADDRESS; sleep 1; $M1DDC display 2 set input 18; $M1DDC display 2 set input 15";
        };
      initExtra = ''
         #if [ -f $GHOSTTY/zig-out/bin/ghostty ]; then
         #  mkdir -p $HOME/.local/bin
        #  ln -s $GHOSTTY/zig-out/bin/ghostty $HOME/.local/bin/ghostty
         #fi

         # Work around only supporting session environment variables
         if [ -f $HOME/.config/env/secrets.env ]; then
           source $HOME/.config/env/secrets.env
         fi
         export DIRENV_WARN_TIMEOUT="20s"
         export DDCUTIL_DISPLAY_INPUT="60"
         export DDCUTIL_S2721QS_HDMI1="0x11"
         export DDCUTIL_S2721QS_HDMI2="0x12"
         export DDCUTIL_U3419W_DP1="0x0f"
         export DDCUTIL_U3419W_USBC="0x1b"
         export DDCUTIL_U3419W_HDMI1="0x11"
         export DDCUTIL_U3419W_HDMI2="0x12"

         # Support local only aliases & secrets for work
         if [ -f $HOME/.private.post.source ]; then
           source $HOME/.private.post.source
         fi

         # nap configs
         export NAP_CONFIG=$HOME/.config/nap/config.yaml

         # Needed to run mason downloads in neovim
         # 02/25/2025 - I do not think this is needed anymore because I no longer use mason
         #export NIX_LD=$(nix eval --extra-experimental-features nix-command --impure --raw --expr 'let pkgs = import <nixpkgs> {}; NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker"; in NIX_LD')

         eval "$(zoxide init --cmd cd zsh)"
         # Pre-load several directories that I always use

         if [ -d $WORKSPACE ]; then
           zoxide add $WORKSPACE
         fi

         if [ -d $GITHIB ]; then
           zoxide add $GITHUB
         fi

         if [ -d $GHOSTTY ]; then
           zoxide add $GHOSTTY
         fi

         if [ -d $WORKSPACE ]; then
           zoxide add $WORKSPACE
         fi

         if [ -d $BUSHKO/leetcode ]; then
           zoxide add $BUSHKO/leetcode
         fi

         if [ -d $KLEIO ]; then
           zoxide add $KLEIO
         fi

         if [ -d $KB ]; then
           zoxide add $KB
         fi

         if [ -d $NIXOS_CONFIG ]; then
           zoxide add $NIXOS_CONFIG
         fi

         if [ -d $GITHUB/hasicorp ]; then
           zoxide add $GITHUB/hashicorp
         fi

         # Add $HOME/bin to PATH
         export PATH=$PATH:$HOME/bin:$HOME/go/bin
      '';
    };
    programs.zsh.oh-my-zsh = {
      enable = true;
      plugins = ["git" "vi-mode"];
      theme = "agnoster";
    };
    programs.bash = {
      enable = true;
      shellOptions = [];
      historyControl = ["ignoredups" "ignorespace"];
    };
  };
}
