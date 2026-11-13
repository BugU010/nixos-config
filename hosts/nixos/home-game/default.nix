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
    ./driver.nix
    # 2. 显式导入你需要的通用模块（注意这里是 ../../ 退回到根目录）

    ../../modules/nixos/grub.nix
    ../../modules/nixos/grub-theme/mod.nix
    ../../modules/nixos/git.nix
    ../../modules/nixos/packages.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/zsh.nix
    ../../modules/nixos/gnupg.nix
  ];

  # 3. 设置主机名（由 flake/nixos.nix 自动传入）
  networking.hostName = hostName;

  time.timeZone = "Asia/Shanghai";
  system.stateVersion = "26.05";
  users.users.bugu = {
    isNormalUser = true;
    useDefaultShell = true;
    extraGroups = [ "wheel" ]; # 如果有，保留原有配置
  };

  # 同时确保全局默认 Shell 已设置（如果 zsh.nix 里已有，可跳过）
  users.defaultUserShell = pkgs.zsh;

  nix.settings = {
    substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
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
