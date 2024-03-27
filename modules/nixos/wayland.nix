{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    wayland
  ];

  # Xserver settings
  services.xserver = {
    enable = true;
    #videoDrivers = ["nvidia"];
    layout = "us";
    xkb = {
      layout = "us";
      variant = "";
      options = "caps:escape";
    };

    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      enableHidpi = true;
      theme = "chili";
    };
  };
  # Used to disable gdm suspend.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.login1.suspend" ||
            action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
            action.id == "org.freedesktop.login1.hibernate" ||
            action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
        {
            return polkit.Result.NO;
        }
    });
  '';
}
