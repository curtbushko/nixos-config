{
  programs.direnv = {
    enable = true;
    config = {
      whitelist = {
        prefix = [
          "$HOME/code/go/src/github.com/hashicorp"
          "$HOME/code/go/src/github.com/mitchellh"
          "$HOME/code/go/src/github.com/curtbushko"
        ];

        exact = ["$HOME/.envrc"];
      };
    };
  };
}
