# hosts/darwin/Company-macbookpro/default.nix
{ pkgs, hostName, ... }:
{
  # ===== 系统基础 =====
  networking.hostName = hostName;
  system.stateVersion = 6;

  nix = {
    enable = true;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    # 使用国内镜像源（中科大 USTC），并保留官方源作为回退
    settings.substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
    ];
    settings.trusted-substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
    ];
  };

  # ===== home-manager 接入（darwin 版，与 NixOS 同名选项）=====
  # 当前用户在 mac 上是 secvision
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.secvision = {
      # ← bugu 改为 secvision
      imports = [ ../../../modules/common ];
      home = {
        username = "secvision"; # ← /Users/secvision
        homeDirectory = "/Users/secvision";
        stateVersion = "26.05";
      };
    };
  };

  # ===== sops-nix（darwin 用 darwinModules.sops，配置选项同名）=====
  sops.defaultSopsFile = ../../../modules/nixos/secrets/secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}