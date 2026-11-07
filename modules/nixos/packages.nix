{ pkgs, ... }:

let
  ps = pkgs;

  # ===== 基础必备 =====
  core = with ps; [
    neovim # 主力编辑器
    curl # 网络请求/下载
    wget # 下载工具
    openssl # 证书/密钥/加密
    unzip # 解压 zip
    zip # 压缩 zip
    file # 查看文件类型
  ];
    # ===== 终端增强（NixOS 系统级无 programs.* 模块，统一装包）=====
  cli = with ps; [
    eza          # 现代 ls
    bat          # 带语法高亮的 cat
    fd           # 更快的 find
    ripgrep      # 更快的 grep
    jq           # JSON 处理
    yq           # YAML 处理
    tealdeer     # 提供 tldr 命令
  ];

  # ===== 系统 / 磁盘 / 引导（Secure Boot 相关）=====
  sys = with ps; [
    sbctl
    os-prober
    efibootmgr # 管理 UEFI 启动项
    efivar # 读写 UEFI 变量
    sbsigntool # sbsign/sbverify 签名验证
    mokutil # MOK 密钥管理
    parted # 命令行分区工具
    gptfdisk # GPT 磁盘工具 (sgdisk)
    smartmontools # 硬盘健康检测 (smartctl)
    nvme-cli # NVMe 固态管理
    pciutils # lspci 查看 PCI 设备
    usbutils # lsusb 查看 USB 设备
  ];

  # ===== 网络排查 =====
  net = with ps; [
    nmap # 端口扫描
    tcpdump # 命令行抓包
    socat # 端口转发/网络调试
    ipcalc # IP 地址计算
  ];

  # ===== 监控与诊断 =====
  monitor = with ps; [
    btop # 更漂亮的资源监控
    ncdu # 磁盘占用分析
    dust # 现代版 du
    duf # 现代版 df
    lsof # 查看打开的文件
    bmon # 实时网速监控
    fastfetch # 系统信息展示
    inxi # 硬件信息查询
  ];

  # ===== Nix 效率工具 =====
  nixTools = with ps; [
    nix-tree # 查看 Nix store 依赖树
    nixfmt
    nix-output-monitor # 美化 nix build 输出
    nvd # 对比 generation 包差异
    nix-diff # 包级 nix diff
    nix-index # 命令所属包查询
  ];

  # ===== 安全 / 密钥管理 =====
  sec = with ps; [
    age # 简单加密工具
    sops # secrets 加密管理
    gh # GitHub 命令行
  ];

  # ===== 容器 / 虚拟化（按需启用，默认注释）=====
  # virt = with ps; [
  #   podman                # daemonless 容器引擎
  #   podman-compose        # podman 下的 docker-compose
  #   distrobox             # 容器整合到系统
  #   qemu                  # QEMU 虚拟机
  #   virt-manager          # 虚拟化管理界面
  # ];
  # ===== 自定义脚本 =====
  nixreload = ps.writeScriptBin "nixreload" ''
    #!/usr/bin/env bash
    set -e
    sudo nixos-rebuild switch --flake /etc/nixos#default
    cd /etc/nixos
    git add -A
    git commit -m "chore: NixOS rebuild $(date '+%Y-%m-%d %H:%M:%S')" || true
    echo "✅ rebuild + 提交完成"
  '';

  nixfmt-all = ps.writeScriptBin "nixfmt-all" ''
    #!/usr/bin/env bash
    set -euo pipefail
    fd -e nix -x nixfmt
  '';

  # ===== secrets 加密/解密 =====
  secrets-enc = ps.writeScriptBin "secrets-enc" ''
    #!/usr/bin/env bash
    set -euo pipefail

    tar czf - -C /etc/nixos secrets/ | openssl aes-256-cbc -pbkdf2 -iter 100000 -salt \
      -out /etc/nixos/secrets.tar.gz.enc

    echo "✅ secrets.tar.gz.enc 已生成"
  '';

  secrets-dec = ps.writeScriptBin "secrets-dec" ''
    #!/usr/bin/env bash
    set -euo pipefail

    openssl aes-256-cbc -d -pbkdf2 -iter 100000 \
      -in /etc/nixos/secrets.tar.gz.enc | tar xz -C /etc/nixos

    echo "✅ secrets/ 已还原"
  '';
in
{
  environment.systemPackages =
    core
    ++ sys
    ++ cli
    ++ net
    ++ monitor
    ++ nixTools
    ++ sec
    ++ [
      nixreload
      nixfmt-all
      secrets-enc
      secrets-dec
    ];
  # ++ virt;   # 需要容器/虚拟化时取消注释
}
