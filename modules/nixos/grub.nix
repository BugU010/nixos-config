{
  config,
  pkgs,
  lib,
  grub-theme,
  ...
}:

let
  esp = "/boot";
  themeDir = "The Quintessential Quintuplets/Nakano Miku/Miku";

  grubTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "grub-theme-miku";
    version = "2026-01-01";
    src = grub-theme;

    installPhase = ''
      runHook preInstall
      mkdir -p $out

      if [ -d "$src/${themeDir}" ] && [ -f "$src/${themeDir}/theme.txt" ]; then
        cp -r "$src/${themeDir}/." $out/
      else
        echo "ERROR: 找不到 theme.txt = $src/${themeDir}/theme.txt"
        echo "仓库里可用的主题路径如下："
        find "$src" -name theme.txt -printf '可用路径: %h\n'
        exit 1
      fi

      chmod -R a+rX $out
      runHook postInstall
    '';
  };
in
{
  boot.loader = {
    efi = {
      # 使用标准的 NVRAM 写入方式，兼容性好
      canTouchEfiVariables = true;
      efiSysMountPoint = esp;
    };

    # 60 = 菜单常驻
    timeout = 60;

    grub = {
      enable = true;
      device = "nodev"; # UEFI 专用，不需要 mkForce 了
      efiSupport = true;
      efiInstallAsRemovable = false; # 必须为 false 才能与 canTouchEfiVariables 配合
      configurationLimit = 10;
      useOSProber = true; # 自动扫描 Windows
      theme = grubTheme;
      gfxmodeEfi = "1920x1080,auto";
      extraGrubInstallArgs = [
        "--modules=part_gpt part_msdos fat normal search search_fs_uuid \
         configfile gzio efi_gop efi_uga all_video gfxterm \
         gfxmenu png jpeg tga font gcry_sha256 gcry_sha512 gcry_rsa"
      ];

      # Windows 双系统兜底入口
      extraEntries = ''
        menuentry "Windows 11" {
          insmod part_gpt
          insmod fat
          search --fs-uuid --set=root 582F-0049
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';

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
