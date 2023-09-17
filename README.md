# DOTFILES 

This setup includes my dotfiles that I used to configure the computers I work on.

# TOOLS

The setup uses nix, nix flakes and home-manger to manage the software 


# INSTALLATION

1) clone this repo by running `git clone https://github.com/curtbushko/dotfiles.git ${HOME}/.dotfiles`
2) `cd $HOME/.dotfiles`
3) `./setup.sh`
4) Choose `yes` when prompted by the Determinate Nix installer
5) run `.  /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh` as the Determinate Nix Installer recommends.

# PACKAGES


# TODO
- move home-manager packages into users
- pass colors through to home-manager configs
- set colorscheme in flake
- pull homebrew configs from github.com/malob  or ryan4yin darwin kickstarter
- fully convert zsh or switch to fish
- fully convert neovim
- fully convert wezterm
- loop through all modules to load
- multi-arch support

# TOOLS
- tealdeer
- goenv - no can do, maybe asdf?
- goreleaser
- fish
- starship

# MISSING
- bash-language-server
- tfenv
- helm (not on silicon)

tap "homebrew/bundle" || true
tap "homebrew/cask" || true
tap "homebrew/core" || true
tap "homebrew/cask-fonts" || true
tap "homebrew/cask-versions" || true
tap "hashicorp/tap" || true
tap "goreleaser/tap" || true
rectangle
syncthing
brew "mas"
cask "syncthing"
cask "docker"
cask "firefox"
cask "ngrok"
cask "rectangle"
cask "slack"
cask "steam"
cask "vlc"
cask "wezterm-nightly"
cask "font-hack-nerd-font"
cask "font-jetbrains-mono-nerd-font"
cask "google-cloud-sdk"
brew "mveritym/homebrew-mel/kubedecode"
brew "helm"
brew "gnu-tar"
cask "rectangle"
brew "goreleaser/tap/goreleaser"
brew "parallel"
brew "tldr"
brew "asdf"

brew "hashicorp/tap/terraform-ls"

mas "GoodNotes", id: 1444383602


go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.3.0


gh extension install eikster-dk/gh-worktree

go install github.com/kisunji/gen-changelog@latest



gcloud components install gke-gcloud-auth-plugin
