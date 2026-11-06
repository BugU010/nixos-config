{
  config,
  pkgs,
  lib,
  grub-theme,
  ...
}:

let
  esp = "/boot";

in
{
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = esp;
    };

    timeout = 60;

    grub = {
      enable = true;
      device = "nodev"; # UEFI 专用，不需要 mkForce 了
      efiSupport = true;
      efiInstallAsRemovable = false; # 必须为 false 才能与 canTouchEfiVariables 配合
      configurationLimit = 10;
      useOSProber = true; # 自动扫描 Windows
      gfxmodeEfi = "1920x1080,auto";
      extraGrubInstallArgs = [
        "--modules=part_gpt part_msdos fat normal search search_fs_uuid \
         configfile gzio efi_gop efi_uga all_video gfxterm \
         gfxmenu png jpeg tga font gcry_sha256 gcry_sha512 gcry_rsa"
      ];

      # 合并过来的 Secure Boot 签名脚本
      extraInstallCommands = ''
        set -euo pipefail
        export PATH="${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin:${pkgs.gnugrep}/bin:${pkgs.sbsigntool}/bin:$PATH"

        ESP="${esp}"
        KEY="/etc/nixos/secrets/MOK.priv"
        CERT="/etc/nixos/secrets/MOK.pem"

        # 复制 grub-install 生成的新 GRUB 到 shim 同目录
        GRUB_SRC="$ESP/EFI/NixOS-boot/grubx64.efi"
        if [ -f "$GRUB_SRC" ]; then
          mkdir -p "$ESP/EFI/BOOT"
          cp "$GRUB_SRC" "$ESP/EFI/BOOT/grubx64.efi"
        fi

        # 签名 GRUB
        if [ -f "$ESP/EFI/BOOT/grubx64.efi" ]; then
          sbsign --key "$KEY" --cert "$CERT" --output "$ESP/EFI/BOOT/grubx64.efi" "$ESP/EFI/BOOT/grubx64.efi"
        fi

        # 签名内核（不用碰 initrd）
        find /boot -type f \( -name 'vmlinuz*' -o -name 'kernel*' -o -name 'bzImage*' \) \
          -exec sbsign --key "$KEY" --cert "$CERT" --output {} {} \; || true
      '';
    };
  };
}
