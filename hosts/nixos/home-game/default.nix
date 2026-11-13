{
  config,
  pkgs,
  lib,
  hostName,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./driver.nix

    # 系统级通用模块（NixOS 平台）
    ../../../modules/nixos/grub.nix
    ../../../modules/nixos/grub-theme/mod.nix
    ../../../modules/nixos/packages.nix
    ../../../modules/nixos/ssh.nix
    ../../../modules/nixos/gnupg.nix
  ];

  # 主机名
  networking.hostName = hostName;

  time.timeZone = "Asia/Shanghai";
  system.stateVersion = "26.05";

  # 用户：bugu
  users.users.bugu = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };
  users.defaultUserShell = pkgs.zsh;

  # ===== home-manager 接入 =====
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.bugu = {
    imports = [ ../../../modules/common ];
    home.username = "bugu";
    home.homeDirectory = "/home/bugu";
    home.stateVersion = "26.05";
  };

  # ===== nix 优化 =====
  nix.settings = {
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
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