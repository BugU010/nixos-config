{ pkgs, lib, ... }:

let
  grubTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "grub-theme-custom";
    version = "1.0.0";
    src = ./.;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp "$src/theme.txt" $out/
      cp -r "$src/assets" $out/
      chmod -R a+rX $out
      runHook postInstall
    '';
  };
in
{
  boot.loader.grub.theme = grubTheme;
}
