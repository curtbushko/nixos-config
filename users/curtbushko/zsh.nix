{
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
            docs  = "$HOME/Documents";
            vids  = "$HOME/Videos";
            dl    = "$HOME/Downloads";
            nixcfg  = "$HOME/workspace/github.com/curtbushko/nixos-config";
        };
        # environment variables
        sessionVariables = {
            SYNCTHING = "$HOME/Sync";
            SCRIPTS = "$HOME/scripts";
            WALLPAPERS = "$HOME/Sync/wallpapers";
            KB = "$HOME/Sync/KB";
            DOTFILES = "$HOME/.dotfiles";
            ZIGBIN = "$HOME/bin/zig";
            WORKSPACE = "$HOME/workspace";
            GITHUB = "$HOME/workspace/github.com";
            GHOSTTY = "$HOME/workspace/github.com/mitchellh/ghostty";
            BUSHKO = "$HOME/workspace/github.com/curtbushko";
            DDCCTL = "$HOME/.dotfiles/bin/m1ddc";
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
            vi = "nvim";
            vim = "nvim";
            reload = "source ~/.zshrc";
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
            cdscripts = "cd $SCRIPTS";
            lsscripts = "ls $SCRIPTS";
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
            tf = "terraform";
            gitreset = "git reset --hard HEAD^";
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
            weztitle = "wezterm cli set-tab-title";
            ls = "exa -la --ignore-glob=.DS_Store";
            tree = "exa -aT --git-ignore --ignore-glob=.git";
            tmuxwork = "tmuxinator start work";
            tmuxhome = "tmuxinator start home";
            tmuxkill = "tmux kill-server";
            tmuxserver = "tmux new";
            weather = "curl wttr.in/kitchener";
            # monitor switching
            work = "$DDCCTL set input 27";
            home = "$DDCCTL set input 17";
            pc = "$DDCCTL set input 15";
            ghostty-release = "zig build -Dstatic=true -Doptimize=ReleaseFast && direnv deny && cd macos && sh -c xcodebuild -configuration Release";
        };
        initExtra = ''
            if [ -f $HOME/.private.post.source ]; then
                source $HOME/.private.post.source
            fi
        '';
    };
}
