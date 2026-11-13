# NixOS Secure Boot 配置

基于 shim + GRUB + MOK 的 Secure Boot 引导链，支持 Windows 双启动。

## 信任链架构

```
固件 (UEFI Secure Boot)
  └─→ shim (BOOTX64.EFI, 微软 CA 签名)
        └─→ MokManager (mmx64.efi, 仅首次注册 MOK 时用到)
        └─→ GRUB (grubx64.efi, MOK 签名)
              └─→ Linux 内核 (vmlinuz-*, MOK 签名)
                    └─→ initrd (cpio 数据文件，无需签名)
```

## 目录结构

```
/etc/nixos/
├── configuration.nix          # 系统主配置
├── flake.nix                  # Flake 入口
├── flake.lock
├── hardware-configuration.nix # 硬件配置（由 nixos-generate-config 生成）
├── modules/
│   ├── grub.nix               # GRUB 引导配置
│   ├── packages.nix           # 系统软件包
│   ├── secureboot.nix         # Secure Boot 签名自动化
│   └── ssh.nix                # SSH 服务配置
├── scripts/
│   └── secureboot-init.sh     # 首次部署脚本（shim + mmx + 签名 + MOK 注册）
└── secrets/                   # ⚠️ 敏感目录，切勿提交到公开仓库
    ├── MOK.priv               # MOK 私钥
    ├── MOK.pem                # MOK 公钥
    ├── MOK.der                # MOK 公钥（固件导入格式）
    ├── shimx64.efi            # shim 二进制（微软签名）
    ├── mmx64.efi              # MokManager（微软签名）
    └── 1                      # 其他待确认文件
```

## 前置条件

- NixOS 使用 `systemd-boot` 或 GRUB 可正常启动
- ESP 已挂载到 `/boot`（`lsblk -f /dev/nvme1n1p1` 可确认）
- 已存在 MOK 密钥对（`secrets/MOK.{priv,pem,der}`）
- Windows 分区未被破坏，`os-prober` 可探测到（可选，双启动需要）

## 首次部署流程

适用于一台新机器或清除 NVRAM 后的重新配置。

### 1. 准备 shim

从 Ubuntu 官方仓库下载 `shim-signed` 包并解压出 `shimx64.efi` 与 `mmx64.efi`，放入 `secrets/`：

```bash
# 示例：手动从 packages.ubuntu.com 下载 deb 后
dpkg-deb -x shim-signed_*.deb shim-extract/
cp shim-extract/usr/lib/shim/shimx64.efi.signed /etc/nixos/secrets/shimx64.efi
cp shim-extract/usr/lib/shim/mmx64.efi.signed   /etc/nixos/secrets/mmx64.efi
```

> 若网络受限（如需要代理），可用 `curl -x` 指定代理下载。

### 2. 生成 MOK 密钥（如尚未生成）

```bash
cd /etc/nixos/secrets
openssl req -new -x509 -newkey rsa:2048 -keyout MOK.priv \
  -outform PEM -out MOK.pem -nodes -days 3650 \
  -subj "/CN=NixOS Secure Boot MOK/"
openssl x509 -in MOK.pem -outform DER -out MOK.der
sudo chmod 600 MOK.priv
```

### 3. 构建系统（生成 GRUB 与内核）

```bash
sudo nixos-rebuild switch --flake /etc/nixos#default
```

### 4. 运行首次初始化脚本

```bash
sudo chmod +x /etc/nixos/scripts/secureboot-init.sh
sudo /etc/nixos/scripts/secureboot-init.sh
```

脚本会依次：

1. 部署 `shimx64.efi` 到 `/boot/EFI/BOOT/BOOTX64.EFI` 与 `/boot/EFI/NixOS-boot/`
2. 部署 `mmx64.efi` 到上述两个 GRUB 同目录
3. 复制 GRUB 到 shim 同目录（`/boot/EFI/BOOT/grubx64.efi`）
4. 用 `MOK.priv` 签名 GRUB 与所有内核
5. 发起 MOK 注册（`mokutil --import MOK.der`）

### 5. 重启进入 MokManager

```bash
sudo reboot
```

重启后应看到蓝色 MokManager 界面：

1. 按任意键继续
2. 选择 **Enroll MOK**
3. 选择 **Continue**
4. 选择 **Yes**
5. 输入刚才设置的临时密码
6. 系统自动重启

### 6. 在 BIOS 中开启 Secure Boot

重启时进入固件设置（F2 / Del / F10），找到 Secure Boot 选项，设为 **Enabled**，保存退出。

### 7. 验证

```bash
mokutil --sb-state                       # 应输出 SecureBoot enabled
dmesg | grep -i secure                   # 应含 Secure boot enabled
sbverify --cert /etc/nixos/secrets/MOK.pem /boot/EFI/BOOT/grubx64.efi
sbverify --cert /etc/nixos/secrets/MOK.pem /boot/EFI/nixos/kernel-*.efi
```

---

## 日常维护

### 普通更新

```bash
sudo nixos-rebuild switch --flake /etc/nixos#default
```

`secureboot.nix` 中的 `extraInstallCommands` 会自动完成：

- 将新 GRUB 复制到 shim 同目录
- 签名 GRUB
- 签名所有新内核

**不需要**重复运行 MOK 注册流程。

### 更新内核后验证签名

```bash
sbverify --cert /etc/nixos/secrets/MOK.pem /boot/EFI/nixos/kernel-*.efi
```

### 查看当前启动项

```bash
sudo efibootmgr -v | grep -E "BootCurrent|BootOrder|UEFI OS"
```

预期的 `Boot0003 UEFI OS` 指向：

```
\EFI\BOOT\BOOTX64.EFI   ← shim
```

---

## 故障排查

### `mokutil --sb-state` 显示 disabled

- 进入 BIOS 检查 Secure Boot 是否已开启
- 确认 `BootOrder` 中 `UEFI OS`（shim）在首位

### 重启后没有出现 MokManager 蓝屏

- 确认 `/boot/EFI/BOOT/mmx64.efi` 存在
- 确认 MOK 注册确实发起过（`sudo mokutil --list-enrolled`）
- 尝试重新运行注册流程

### 重建后启动顺序被重置

`grub-install` 可能重写 BootOrder。如发生，在 `secureboot.nix` 末尾加回：

```nix
${pkgs.efibootmgr}/bin/efibootmgr -o 0003,0001,0002,0000
```

或手动执行：

```bash
sudo efibootmgr -o 0003,0001,0002,0000
```

### `awk: command not found`

- 确保 `modules/packages.nix` 中包名是 `gawk`（不是 `awk`）
- `extraInstallCommands` 的 PATH 中包含 `${pkgs.gawk}/bin`

### `Invalid BootOrder order entry value`

- `efibootmgr -o` 中写入了不存在的 BootNum
- 先运行 `sudo efibootmgr` 查看实际启动项编号再设置

### `modprobe: can't change directory to '/lib/modules'`

- grub-install 在构建环境中的无害警告，不影响安装

---

## 安全注意事项

| 事项 | 建议 |
|---|---|
| `secrets/` 目录权限 | `sudo chmod 700 /etc/nixos/secrets` |
| `MOK.priv` 文件权限 | `sudo chmod 600 /etc/nixos/secrets/MOK.priv` |
| Git 仓库 | `.gitignore` 必须忽略 `secrets/`，否则私钥可被任何人获取 |
| MOK 私钥丢失 | 会导致新内核无法通过验证，需重新生成密钥并重走 MokManager 流程 |
| 固件恢复出厂 | 会清空 NVRAM 中的 MOK 列表，需重新导入 `MOK.der` |

---

## 相关文件速查

| 文件 | 作用 |
|---|---|
| `modules/secureboot.nix` | 声明 GRUB 配置 + 每次 rebuild 的自动签名逻辑 |
| `modules/grub.nix` | GRUB 菜单与 os-prober 配置 |
| `scripts/secureboot-init.sh` | 首次部署：shim 拷贝 + 签名 + MOK 注册 |
| `secrets/MOK.priv` | 用于签名的 RSA 私钥 |
| `secrets/MOK.pem` | 用于验证签名的公钥证书 |
| `secrets/MOK.der` | 导入固件 MokList 的 DER 格式公钥 |
| `secrets/shimx64.efi` | 微软签名的 shim 引导器 |
| `secrets/mmx64.efi` | MokManager 管理界面 |
```


## openssl 加密归档（简单备份）

只想把整个 `secrets/` 加密成一个文件丢进 git，每次需要解密后手动放回。

### 加密

```bash
cd /etc/nixos
tar czf - secrets/ | openssl aes-256-cbc -pbkdf2 -iter 100000 -salt \
  -out secrets.tar.gz.enc
```

输入一个强密码。将 `secrets.tar.gz.enc` 提交 git，原 `secrets/` 留在本机或从 git 删除。

### 解密

```bash
cd /etc/nixos
openssl aes-256-cbc -d -pbkdf2 -iter 100000 \
  -in secrets.tar.gz.enc | tar xz
```

### 缺点

- 每次修改 MOK 密钥都要重新打包提交
- 使用系统前需手动解密，与 NixOS 声明式理念相悖
- 密码靠脑记或密码管理器，没有 sops 灵活

适合纯备份场景；日常多机同步还是 sops-nix 省心。

