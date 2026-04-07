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
    xdg.configFile."television/cable/k8s-deployments.toml".text = ''
      [metadata]
      name = "k8s-deployments"
      description = """List and preview Deployments in a Kubernetes Cluster.

      The first source lists only from the current namespace, while the second lists from all.

      Keybindings

      Press `ctrl-d` to delete the selected Deployment.
      """
      requirements = ["kubectl"]

      [source]
      command = [
        """
        ${pkgs.kubectl}/bin/kubectl get deployments -o go-template --template '{{range .items}}{{.metadata.namespace}} {{.metadata.name}}{{"\\n"}}{{end}}'
        """,
        """
        ${pkgs.kubectl}/bin/kubectl get deployments -o go-template --template '{{range .items}}{{.metadata.namespace}} {{.metadata.name}}{{"\\n"}}{{end}}' --all-namespaces
        """,
      ]
      output = "{1}"

      [preview]
      command = "${pkgs.kubectl}/bin/kubectl describe -n {0} deployments/{1}"

      [ui.preview_panel]
      size = 60

      [keybindings]
      ctrl-d = "actions:delete"

      [actions.delete]
      description = "Delete the selected Deployment"
      command = "${pkgs.kubectl}/bin/kubectl delete -n {0} deployments/{1}"
      mode = "execute"
    '';
  };
}
