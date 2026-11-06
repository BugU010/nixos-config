{
  config,
  pkgs,
  lib,
  ...
}:
let
  # 自动扫描 modules 目录下的所有 .nix 文件
  moduleFiles = builtins.readDir ./modules;
  autoImports = lib.mapAttrsToList (name: type: ./modules + "/${name}") (
    lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) moduleFiles
  );
in
{
  imports = [
    ./hardware-configuration.nix
  ]
  ++ autoImports;

  time.timeZone = "Asia/Shanghai";
  system.stateVersion = "26.05";
  nix.settings = {
    substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Nix 存储优化
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
}
