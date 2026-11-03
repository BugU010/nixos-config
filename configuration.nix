{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/grub.nix
    ./modules/secureboot.nix
    ./modules/ssh.nix
    ./modules/packages.nix
    ./modules/driver.nix
  ];

  system.stateVersion = "26.11";
  nix.settings = {
    substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
