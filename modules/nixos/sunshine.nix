{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    sunshine
    cudaPackages
  ];
 
  services.sunshine = {
    enable = true;
    description = "Sunshine self-hosted game stream host for Moonlight";
    cudaSupport = true;
    stdenv = pkgs.cudaPackages.backendStdenv;
  };
}
