#!/usr/bin/env bash
set -euo pipefail

# ===== 路径配置 =====
ESP="/boot"
SECRETS="/etc/nixos/secrets"
SHIM_SRC="$SECRETS/shimx64.efi"
MMX_SRC="$SECRETS/mmx64.efi"
KEY="$SECRETS/MOK.priv"
CERT="$SECRETS/MOK.pem"
DER="$SECRETS/MOK.der"

# ===== 依赖检查 =====
for bin in sbsign mokutil efibootmgr find; do
  command -v "$bin" >/dev/null 2>&1 || { echo "缺少命令: $bin"; exit 1; }
done

# ===== 1. 部署 shim + mmx64 =====
echo "==> 部署 shim / mmx64"
[ -f "$SHIM_SRC" ] || { echo "找不到 $SHIM_SRC"; exit 1; }
[ -f "$MMX_SRC" ]  || { echo "找不到 $MMX_SRC"; exit 1; }

mkdir -p "$ESP/EFI/BOOT" "$ESP/EFI/NixOS-boot"
cp "$SHIM_SRC" "$ESP/EFI/BOOT/BOOTX64.EFI"
cp "$SHIM_SRC" "$ESP/EFI/NixOS-boot/shimx64.efi"
cp "$MMX_SRC"  "$ESP/EFI/BOOT/mmx64.efi"
cp "$MMX_SRC"  "$ESP/EFI/NixOS-boot/mmx64.efi"

# ===== 2. 复制 GRUB 到 shim 同目录 =====
echo "==> 复制 GRUB"
GRUB_SRC="$ESP/EFI/NixOS-boot/grubx64.efi"
[ -f "$GRUB_SRC" ] || { echo "找不到 $GRUB_SRC，请先 nixos-rebuild 生成"; exit 1; }
cp "$GRUB_SRC" "$ESP/EFI/BOOT/grubx64.efi"

# ===== 3. 签名 GRUB =====
echo "==> 签名 GRUB"
sbsign -q --key "$KEY" --cert "$CERT" \
  --output "$ESP/EFI/BOOT/grubx64.efi" \
  "$ESP/EFI/BOOT/grubx64.efi"

# ===== 4. 签名所有内核 =====
echo "==> 签名内核"
find /boot -type f \( -name 'vmlinuz*' -o -name 'kernel*' -o -name 'bzImage*' \) \
  -exec sbsign -q --key "$KEY" --cert "$CERT" --output {} {} \;

# ===== 5. 注册 MOK（首次需要，之后不用再跑）=====
echo "==> 注册 MOK 到固件"
if mokutil --sb-state 2>/dev/null | grep -qi enabled; then
  echo "Secure Boot 已启用，MOK 应已注册，跳过 import"
else
  mokutil --import "$DER"
  echo
  echo "下一步："
  echo "  1) sudo reboot"
  echo "  2) 蓝屏 MokManager -> Enroll MOK -> Continue -> Yes"
  echo "  3) 输入刚才设置的临时密码"
  echo "  4) 进 BIOS 开启 Secure Boot"
fi
