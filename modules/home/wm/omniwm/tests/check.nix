let
  render = import ../render-skhd.nix;
  bindings = import ../bindings.nix;
in
  assert render {"cmd - k" = bindings."cmd - k";}
  == ''
    cmd - k [
      * : omniwmctl command focus up
      "Rex" ~
      "Rex Beta" ~
    ]'';
  assert render {
    "cmd - tab" = "omniwmctl command toggle-overview";
  }
  == "cmd - tab : omniwmctl command toggle-overview"; true
