{ pkgs, lib, ... }:

let
  esp = "/boot";
in
{
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = esp;
    };
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      efiInstallAsRemovable = false;

      extraGrubInstallArgs = [
        "--modules=part_gpt part_msdos fat normal search search_fs_uuid \
         configfile gzio efi_gop efi_uga all_video gfxterm \
         gfxmenu png jpeg tga font gcry_sha256 gcry_sha512 gcry_rsa"
      ];

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
        sbsign --key "$KEY" --cert "$CERT" --output "$ESP/EFI/BOOT/grubx64.efi" "$ESP/EFI/BOOT/grubx64.efi"

        # 签名内核（不用碰 initrd）
        find /boot -type f \( -name 'vmlinuz*' -o -name 'kernel*' -o -name 'bzImage*' \) \
          -exec sbsign --key "$KEY" --cert "$CERT" --output {} {} \;
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    sbsigntool
    mokutil
    openssl
    efibootmgr
  ];
}
