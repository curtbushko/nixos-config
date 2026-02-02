{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.shells;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Import theme colors for prompt
  colors = lib.importJSON ../styles/${config.curtbushko.theme.name}.json;
  a_bg = colors.statusline_a_bg;
  a_fg = colors.statusline_a_fg;
  b_bg = colors.statusline_b_bg;
  b_fg = colors.statusline_b_fg;
  c_bg = colors.statusline_c_bg;
  c_fg = colors.statusline_c_fg;

  # Custom prompt that replicates starship look
  customPrompt = ''
    # Helper to create ANSI color codes
    def prompt_color [fg: string, bg: string] {
      $"(ansi -e { fg: '($fg)', bg: '($bg)' })"
    }

    def prompt_fg [fg: string] {
      $"(ansi -e { fg: '($fg)' })"
    }

    # Get hostname with icon and centered name
    def prompt_hostname [] {
      let h = (hostname | str trim)
      let result = match $h {
        "curtbushko-X3FR7279D2" => { icon: (char -u f1d1), name: "work" },
        "gamingrig" => { icon: (char -u edd8), name: "gamingrig" },
        "m4-pro" => { icon: (char -u f1d0), name: "m4-pro" },
        "node00" => { icon: (char -u f10fe), name: "node00 (k8s)" },
        "node01" => { icon: (char -u f10fe), name: "node01 (k8s)" },
        "node02" => { icon: (char -u f10fe), name: "node02 (k8s)" },
        "relay" => { icon: (char -u f0641), name: "relay" },
        "steamdeck" => { icon: (char -u f1b6), name: "steamdeck" },
        _ => { icon: (char -u f08d8), name: $h }
      }
      let len = ($result.name | str length)
      let space = 9
      let left = ([0, (($space - $len) / 2 | into int)] | math max)
      let right = ([0, ($space - $len - $left)] | math max)
      let left_pad = ("" | fill -c ' ' -w $left)
      let right_pad = ("" | fill -c ' ' -w $right)
      $"($result.icon) ($left_pad)($result.name)($right_pad)"
    }

    # Get worktree/directory with icon
    def prompt_worktree [] {
      let git_common = (do { git rev-parse --git-common-dir } | complete)
      let result = if $git_common.exit_code == 0 {
        let common_dir = ($git_common.stdout | str trim)
        let icon = (char -u f02a2)  # git repo icon
        let name = if ($common_dir | str contains ".bare") {
          # In a worktree
          $common_dir | path dirname | path basename
        } else {
          # In normal repo
          (do { git rev-parse --show-toplevel } | complete).stdout | str trim | path basename
        }
        { icon: $icon, name: $name }
      } else {
        # Regular directory
        { icon: (char -u eaf7), name: ($env.PWD | path basename) }
      }

      # Apply icon overrides for specific directories
      let final = match $result.name {
        "consul-k8s" => { icon: (char -u f10fe), name: "consul-k8s" },
        "crusaders" => { icon: (char -u f18be), name: "crusaders" },
        "Documents" => { icon: (char -u f0219), name: "Documents" },
        "Downloads" => { icon: (char -u f019), name: "Downloads" },
        "ghostty" => { icon: (char -u f02a0), name: "ghostty" },
        "kaiju" => { icon: (char -u f0eb5), name: "kaiju" },
        "kb" => { icon: (char -u f09d1), name: "kb" },
        "Music" => { icon: (char -u f075a), name: "Music" },
        "neovim-flake" => { icon: (char -u f36f), name: "neovim-flake" },
        "nixos-config" => { icon: (char -u f1105), name: "nixos-config" },
        "Pictures" => { icon: (char -u f0100), name: "Pictures" },
        "terraform" => { icon: (char -u f1062), name: "terraform" },
        "Videos" => { icon: (char -u f03d), name: "Videos" },
        _ => $result
      }

      let len = ($final.name | str length)
      let space = 9
      let left = ([0, (($space - $len) / 2 | into int)] | math max)
      let right = ([0, ($space - $len - $left)] | math max)
      let left_pad = ("" | fill -c ' ' -w $left)
      let right_pad = ("" | fill -c ' ' -w $right)
      $"($final.icon) ($left_pad)($final.name)($right_pad)"
    }

    # Get git branch
    def prompt_git_branch [] {
      let branch = (do { git branch --show-current } | complete)
      if $branch.exit_code == 0 and ($branch.stdout | str trim | str length) > 0 {
        $" (char -u e0a0) ($branch.stdout | str trim) "
      } else {
        ""
      }
    }

    # Get git status (matching starship style)
    def prompt_git_status [] {
      let status = (do { git status --porcelain } | complete)
      if $status.exit_code != 0 {
        return ""
      }

      let lines = ($status.stdout | lines | where { |l| ($l | str length) > 0 })
      if ($lines | length) == 0 {
        return ""
      }

      # Count different status types
      mut staged = 0
      mut modified = 0
      mut untracked = 0
      mut deleted = 0

      for line in $lines {
        let chars = ($line | split chars)
        let x = ($chars | get 0)
        let y = ($chars | get 1)

        # Staged changes (index) - first column
        if $x in ["A", "M", "R", "C"] { $staged = $staged + 1 }
        if $x == "D" { $deleted = $deleted + 1 }

        # Unstaged changes (worktree) - second column
        if $y == "M" { $modified = $modified + 1 }
        if $y == "D" { $deleted = $deleted + 1 }

        # Untracked files
        if $x == "?" { $untracked = $untracked + 1 }
      }

      # Build status string (starship symbols: + staged, ! modified, ✘ deleted, ? untracked)
      let sym_staged = (char -u '002b')
      let sym_modified = (char -u '0021')
      let sym_deleted = (char -u '2718')
      let sym_untracked = (char -u '003f')

      mut result = ""
      if $staged > 0 { $result = $"($result)($sym_staged)" }
      if $modified > 0 { $result = $"($result)($sym_modified)" }
      if $deleted > 0 { $result = $"($result)($sym_deleted)" }
      if $untracked > 0 { $result = $"($result)($sym_untracked)" }

      $result
    }

    # Get truncated directory path (2 levels)
    def prompt_directory [] {
      let path = $env.PWD
      let home = $env.HOME
      let display = if ($path | str starts-with $home) {
        $"~($path | str replace $home "")"
      } else {
        $path
      }
      let parts = ($display | split row "/" | where { |it| $it != "" })
      let truncated = if ($parts | length) > 2 {
        $parts | last 2 | str join "/"
      } else {
        $parts | str join "/"
      }
      $" ($truncated) "
    }

    # Main left prompt
    $env.PROMPT_COMMAND = {||
      let a_bg = "${a_bg}"
      let a_fg = "${a_fg}"
      let b_bg = "${b_bg}"
      let b_fg = "${b_fg}"
      let c_bg = "${c_bg}"
      let c_fg = "${c_fg}"
      let reset = (ansi reset)

      let hostname = (prompt_hostname)
      let worktree = (prompt_worktree)
      let git_branch = (prompt_git_branch)
      let git_status = (prompt_git_status)

      # Build prompt with angled separators: [ ░▒▓][hostname][](worktree)[](git_branch)(git_status)[]
      #  - left angle
      #  - right angle
      let seg1 = $"(ansi -e { fg: $a_bg }) ░▒▓($reset)"
      let seg2 = $"(ansi -e { fg: $a_fg, bg: $a_bg })($reset)"
      let seg3 = $"(ansi -e { fg: $a_fg, bg: $a_bg }) ($hostname)($reset)"
      let seg4 = $"(ansi -e { fg: $a_bg, bg: $b_bg })(char -u e0bc)($reset)"
      let seg5 = $"(ansi -e { fg: $b_fg, bg: $b_bg }) ($worktree) ($reset)"
      let seg6 = $"(ansi -e { fg: $b_bg, bg: $c_bg })(char -u e0bc)($reset)"
      let seg7 = if ($git_branch | str length) > 0 {
        $"(ansi -e { fg: $c_fg, bg: $c_bg })($git_branch)($reset)"
      } else {
        ""
      }
      let seg8 = if ($git_status | str length) > 0 {
        $"(ansi -e { fg: $c_fg, bg: $c_bg })($git_status)($reset)"
      } else {
        ""
      }
      let seg9 = $"(ansi -e { fg: $c_bg })(char -u e0bc)($reset)"

      $"($seg1)($seg2)($seg3)($seg4)($seg5)($seg6)($seg7)($seg8)($seg9)"
    }

    # Right prompt with directory
    $env.PROMPT_COMMAND_RIGHT = {||
      let a_bg = "${a_bg}"
      let a_fg = "${a_fg}"
      let b_bg = "${b_bg}"
      let b_fg = "${b_fg}"
      let reset = (ansi reset)

      let dir = (prompt_directory)

      # Build right prompt with angled separators: [](directory)[▓▒░ ]
      let seg1 = $"(ansi -e { fg: $a_bg })(char -u e0ba)($reset)"
      let seg2 = $"(ansi -e { fg: $a_fg, bg: $a_bg })($dir)($reset)"
      let seg3 = $"(ansi -e { fg: $a_bg })▓▒░ ($reset)"

      $"($seg1)($seg2)($seg3)"
    }

    # Simple indicator for prompt
    $env.PROMPT_INDICATOR = {|| "❯ " }
    $env.PROMPT_INDICATOR_VI_INSERT = {|| "❯ " }
    $env.PROMPT_INDICATOR_VI_NORMAL = {|| "❮ " }
    $env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }
  '';

  # Common aliases (cross-platform)
  commonAliases = ''
    # Directory navigation
    alias "cd.." = cd ..
    alias "cd..." = cd ../..
    alias "cd...." = cd ../../..

    # Typo fixes
    alias mdkir = mkdir

    # Zoxide helpers
    alias cda = zoxide add
    alias cdr = zoxide remove

    # Directory bookmarks (using custom commands for env mutation)
    def --env foodirs [] { print $"FOO=($env.FOO? | default ""), BAR=($env.BAR? | default ""), BAZ=($env.BAZ? | default "")" }
    def --env foo [] { $env.FOO = $env.PWD; foodirs }
    def --env bar [] { $env.BAR = $env.PWD; foodirs }
    def --env baz [] { $env.BAZ = $env.PWD; foodirs }
    def --env srcdirs [] { print $"SRC=($env.SRC? | default ""), DEST=($env.DEST? | default "")" }
    def --env src [] { $env.SRC = $env.PWD; srcdirs }
    def --env dest [] { $env.DEST = $env.PWD; srcdirs }
    def --env cdsrc [] { cd $env.SRC }
    def --env cddest [] { cd $env.DEST }
    def --env cdfoo [] { cd $env.FOO }
    def --env cdbar [] { cd $env.BAR }
    def --env cdbaz [] { cd $env.BAZ }

    # Docker
    def dockerlogin [] { docker login -u cbushko -p $env.DOCKER_PAT }

    # Terminal
    alias cls = tput reset
    alias reload = exec nu

    # Git commands
    alias gitreset = git reset --hard HEAD^
    alias gs = git status
    alias pr = gh pr view --web
    alias gaa = git add -A
    def gp [] { print "Pulling..."; git pull }
    def gP [] { print "Pushing..."; git push --set-upstream origin (git branch --show-current | str trim) }
    alias gcm = git commit --message
    alias gcmsg = git commit --message
    alias gmcsg = git commit --message

    # Git worktree helpers (these source shell scripts, may need adaptation)
    alias gwta = bash -c ". git-worktree-add"
    alias gwts = bash -c ". git-worktree-switch"
    alias gwtc = bash -c ". git-worktree-clone-bare"
    alias gwtclone = bash -c ". git-worktree-clone-bare"
    alias gwtr = bash -c ". git-worktree-checkout-remote"
    alias gwtcr = bash -c ". git-worktree-checkout-remote"

    # Ghostty build commands
    def ghostty-mac-release [] { zig build -Dstatic=true -Doptimize=ReleaseFast; direnv deny; cd macos; xcodebuild -target Ghostty -configuration Release }
    def ghostty-linux-release [] { zig build -Dstatic=true -Doptimize=ReleaseFast }
    def ghostty-linux-debug [] { zig build -Dstatic=true }

    # Kubernetes
    alias kube = kubectl
    alias kubeclt = kubectl
    alias k = kubectl
    alias kaf = kubectl apply -f
    alias kdf = kubectl delete -f
    alias kev = kubectl get events --sort-by='.metadata.creationTimestamp' -A -o custom-columns=FirstSeen:.firstTimestamp,Count:.count,From:.source.component,Type:.type,Reason:.reason,Message:.message
    alias kgp = kubectl get pods
    alias kdp = kubectl describe pod
    alias kdel = kubectl delete
    alias klogs = kubectl logs -f
    alias kns = kubectl get namespaces
    alias kubedebug = kubectl run -i --tty curt-kubedebug --image=alpine -- bash

    # Common tools
    alias lg = lazygit
    alias ls = eza -lao --ignore-glob=.DS_Store --icons=always
    alias tf = terraform
    alias tree = eza -aT --git-ignore --ignore-glob=.git --icons=always
    alias vi = nvim
    alias vim = nvim
    alias weather = curl wttr.in/kitchener
    alias weztitle = wezterm cli set-tab-title

    # SSH
    def sshm1 [] { ssh $"curtbushko@($env.M1_TAILNET_ID)" }
    def sshwork [] { with-env { TERM: "xterm-256color" } { ssh $"curtbushko@($env.M1_PRO_TAILNET_ID)" } }

    # Zellij
    alias zattach = zellij attach coding
    alias zux = zellij -s coding
    alias zdel = zellij delete-session coding --force
    alias ztitle = zellij action rename-tab
    alias zkill = zellij kill-session coding

    # Tmux
    alias tg = timber-git
    alias tattach = tmux attach -t home
    def tkill [] { tmuxinator stop home; tmux kill-server }
    alias tux = tmuxinator start home
    alias mux = tmuxinator start home
    alias tdetach = tmux detach
  '';

  # Linux-specific aliases
  linuxAliases = ''
    # Monitor switching (Linux)
    def work [] { wakeonlan $env.M1_PRO_MAC_ADDRESS; ddcutil setvcp $env.DDCUTIL_DISPLAY_INPUT $env.DDCUTIL_U3419W_USBC --bus 5 }
    def work2 [] { wakeonlan $env.M1_PRO_MAC_ADDRESS; ddcutil setvcp $env.DDCUTIL_DISPLAY_INPUT $env.DDCUTIL_S2721QS_HDMI1 --bus 6 }
    def workall [] { wakeonlan $env.M1_PRO_MAC_ADDRESS; ddcutil setvcp $env.DDCUTIL_DISPLAY_INPUT $env.DDCUTIL_S2721QS_HDMI1 --bus 6; ddcutil setvcp $env.DDCUTIL_DISPLAY_INPUT $env.DDCUTIL_U3419W_USBC --bus 5 }
    def pc [] { wakeonlan $env.GAMINGRIG_MAC_ADDRESS; ddcutil setvcp $env.DDCUTIL_DISPLAY_INPUT $env.DDCUTIL_U3419W_DP1 --bus 5 }
    def pc2 [] { wakeonlan $env.GAMINGRIG_MAC_ADDRESS; ddcutil setvcp $env.DDCUTIL_DISPLAY_INPUT $env.DDCUTIL_S2721QS_HDMI2 --bus 6 }
    def pcall [] { wakeonlan $env.GAMINGRIG_MAC_ADDRESS; ddcutil setvcp $env.DDCUTIL_DISPLAY_INPUT $env.DDCUTIL_S2721QS_HDMI2 --bus 6; ddcutil setvcp $env.DDCUTIL_DISPLAY_INPUT $env.DDCUTIL_U3419W_DP1 --bus 5 }
    def steamdeck [] { ddcutil setvcp $env.DDCUTIL_DISPLAY_INPUT $env.DDCUTIL_U3419W_HDMI1 --bus 5 }
    def sleepy [] { wakeonlan $env.M1_PRO_MAC_ADDRESS; ddcutil setvcp $env.DDCUTIL_DISPLAY_INPUT $env.DDCUTIL_U3419W_USBC --bus 5; systemctl suspend }
    alias startx = niri-session
    def kill-steam [] { kill -KILL (pidof steam) }
  '';

  # Darwin-specific aliases
  darwinAliases = ''
    # Monitor switching (macOS)
    def work [] { bash -c "$M1DDC display 1 set input 27" }
    def work2 [] { bash -c "$M1DDC display 2 set input 17" }
    def workall [] { bash -c "$M1DDC display 1 set input 27; $M1DDC display 2 set input 17" }
    def home [] { bash -c "$M1DDC set input 17" }
    def pc [] { wakeonlan $env.GAMINGRIG_MAC_ADDRESS; sleep 1sec; bash -c "$M1DDC display 1 set input 15" }
    def pc2 [] { wakeonlan $env.GAMINGRIG_MAC_ADDRESS; sleep 1sec; bash -c "$M1DDC display 2 set input 18" }
    def pcall [] { wakeonlan $env.GAMINGRIG_MAC_ADDRESS; sleep 1sec; bash -c "$M1DDC display 2 set input 18; $M1DDC display 2 set input 15" }
  '';

  platformAliases = if isDarwin then darwinAliases else if isLinux then linuxAliases else "";

in {
  config = mkIf cfg.enable {
    programs.nushell = {
      enable = true;

      settings = {
        show_banner = false;
        edit_mode = "vi";
      };

      # Nushell plugins
      # TODO: re-enable plugins when updated for nushell 0.109+
      plugins = [
        pkgs.nushellPlugins.polars
        pkgs.nushellPlugins.gstat
        # pkgs.nushellPlugins.net        # compiled for 0.104.0
        # pkgs.nushellPlugins.highlight  # compiled for 0.108.0
        pkgs.nushellPlugins.formats
      ];

      # Extra configuration
      extraConfig = ''
        ${customPrompt}
        ${commonAliases}
        ${platformAliases}
      '';
    };

    # Enable zoxide with nushell integration
    programs.zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };

    # Enable atuin with nushell integration
    programs.atuin = {
      enableNushellIntegration = true;
    };
  };
}
