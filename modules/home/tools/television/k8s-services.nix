{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;
in {
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.kubectl
    ];
    xdg.configFile."television/cable/k8s-services.toml".text = ''
      [metadata]
      name = "k8s-services"
      description = """List and preview Services in a Kubernetes Cluster.

      The first source lists only from the current namespace, while the second lists from all.

      keybindings

      Press `ctrl-d` to delete the selected Service.
      """
      requirements = ["kubectl"]

      [source]
      command = [
        """
        ${pkgs.kubectl}/bin/kubectl get services -o go-template --template '{{range .items}}{{.metadata.namespace}} {{.metadata.name}}{{"\\n"}}{{end}}'
        """,
        """
        ${pkgs.kubectl}/bin/kubectl get services -o go-template --template '{{range .items}}{{.metadata.namespace}} {{.metadata.name}}{{"\\n"}}{{end}}' --all-namespaces
        """,
      ]
      output = "{1}"

      [preview]
      command = "${pkgs.kubectl}/bin/kubectl describe -n {0} services/{1}"

      [ui.preview_panel]
      size = 60

      [keybindings]
      ctrl-d = "actions:delete"

      [actions.delete]
      description = "Delete the selected Service"
      command = "${pkgs.kubectl}/bin/kubectl delete -n {0} services/{1}"
      mode = "execute"
    '';
  };
}
