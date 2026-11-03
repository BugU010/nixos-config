{
  config,
  pkgs,
  lib,
  grub-theme,
  ...
}:

let
  # ↓↓↓ 改成你想用的主题目录（相对仓库根目录） ↓↓↓
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
    efi.canTouchEfiVariables = true;

    # -1 = 菜单常驻
    timeout = 60;

    grub = {
      enable = true;
      device = "nodev"; # UEFI 专用
      efiSupport = true;
      useOSProber = true; # 自动扫描 Windows

      # 直接把主题目录传给 GRUB，不要再手动 set theme
      theme = grubTheme;

      gfxmodeEfi = "2560x1440,1920x1080,auto";

      # Windows 双系统兜底入口
      extraEntries = ''
        menuentry "Windows 11" {
          insmod part_gpt
          insmod fat
          search --fs-uuid --set=root 582F-0049
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };
  };
}
