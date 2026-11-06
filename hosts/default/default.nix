{
  config,
  pkgs,
  lib,
  hostName,
  ...
}:

{
  imports = [
    # 1. 导入本机专属的硬件配置
    ./hardware-configuration.nix

    # 2. 显式导入你需要的通用模块（注意这里是 ../../ 退回到根目录）
    ../../modules/nixos/grub.nix
    ../../modules/nixos/git.nix
    ../../modules/nixos/packages.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/driver.nix
  ];

  # 3. 设置主机名（由 flake/nixos.nix 自动传入）
  networking.hostName = hostName;

  time.timeZone = "Asia/Shanghai";
  system.stateVersion = "26.05";

  nix.settings = {
    substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    experimental-features = [ "nix-command" "flakes" ];
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
