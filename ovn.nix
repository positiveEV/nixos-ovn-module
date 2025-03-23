{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    ./ovn-central.nix
    ./ovn-host.nix
  ];
  services.ovn-central.enable = true;
  services.ovn-host.enable = true;
}
