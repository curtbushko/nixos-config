<p align="center">
  <a href="https://github.com/curtbushko/nixos-config">
    <picture>
      <img src="https://raw.githubusercontent.com/curtbushko/nixos-config/main/nix-snowflake-colours.svg" width="500px" alt="Nix logo">
    </picture>
  </a>
</p>

* * *

### Nix Config

This repository is used for configuring dotfiles and packages across several systems. Current systems used are:

2 x Mac M* Laptops
1 x AMD Gaming PC running NixOS
3 x Kubernetes nodes running NixOS

* * *
### Design

When using Nix, on the of the key things to understand is that Nix is a system that builds up its final config into what it
calls as derivation. It is layer upon layer upon layer and each layer can overwrite pieces of another.

For my setup it follows:

*Linux*: flake (flake.nix) -> systems (/systems) -> nixos (/modules/nixos) -> home (/modules/home)
*Mac*: flake (flake.nix) -> systems (/systems) -> darwin (/modules/nixos) -> home (/modules/home)

*Most* of my packages are in /modules/home as those are shared across all computers I used (ghostty, zsh, scripts, etc). Nixos packages are linux only packages that don't make sense on Mac (hyprland, waybar, etc)

#### Options

Some packages can be turned on and off which allows for an easy way to toggle features. There are two sets of options, NixOS and Home Manager. Macs only use Home Manager while NixOS machines use both.

Example options:

NixOS: [NixOS services](https://github.com/curtbushko/nixos-config/blob/main/systems/x86_64-linux/gamingrig/default.nix#L15) + [Home Manager](https://github.com/curtbushko/nixos-config/blob/main/homes/x86_64-linux/curtbushko%40gamingrig/default.nix#L20)
Mac: [Home Manager](https://github.com/curtbushko/nixos-config/blob/main/homes/aarch64-darwin/curtbushko%40m1-air/default.nix#L17)

[An example of creating an
option](https://github.com/curtbushko/nixos-config/blob/main/modules/home/git/default.nix#L11)

* * *
### Installation 

This repository is not meant to be installed but can be used as a frame of reference for your own nix conifg.

Of note though is that I use the Determinate Systems Nix Installer on Mac

* * *
### Libraries / Packages of Note

#### [Snowfall lib](https://snowfall.org/) - After several itterations of layouts and custom support libraries I decided to use Snowfall lib to base the layout of my Nix config on. It was the closest layout and supporting package that I could find that was "standard". If you look at other peoples nix configs you will often notice that they have their own /lib directory containing several scripts. There are enough things to learn about Nix as it is that I didn't need to write my own custom libraries too!

#### [sops-nix](https://github.com/Mic92/sops-nix) - Sops lets you store secrets in your git repository. The secrets are encrypted at rest and can be safely checked into git. When you run nix, the secrets are unencrypted and extracted to /run/secrets.d (or /var/folders/random on Mac). There are a few other packages that you can use for secrets but sops was pretty straight toward to us

#### [curtbushko/neovim flake](https://github.com/curtbushko/neovim) - I was using LazyVim for quite a while (Thanks Folke!) but it kept on breaking on me. I decided to go all in and create my own neovim flake to use everywhere. It took a while to setup but it was worth it as it never breaks on me now (unless I change it)

#### [stylix](https://github.com/danth/stylix) - Stylix is is this useful nix package that provides default styling to tools as an overlay. For example, if you installed 'bat', it would set the colours for that tool. My setup is a little custom as I created my own [styles](https://github.com/curtbushko/nixos-config/tree/main/modules/home/styles) and I feed the colours into several modules. This is odd but there are places, such as waybar, where I want my own custom styles.

* * *
### Inspiration:

All of the repositories below use Snowfall and have served as references to my config.

[Jake Hamilton](https://github.com/jakehamilton/config) - huge Snowfall contributor
[IogaMaster](https://github.com/IogaMaster/dotfiles)
[Khaneliman](https://github.com/khaneliman/khanelinix)
