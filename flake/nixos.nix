{ inputs, ... }:

let
  # 扫描 hosts 目录下的所有文件夹
  hostEntries = builtins.readDir ../hosts;
  
  # 使用 inputs.nixpkgs.lib.filterAttrs
  hosts = builtins.attrNames (
    inputs.nixpkgs.lib.filterAttrs (n: v: v == "directory") hostEntries
  );
in
{
  flake.nixosConfigurations = inputs.nixpkgs.lib.genAttrs hosts (hostName:
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      
      specialArgs = {
        inherit inputs hostName;
        grub-theme = inputs.grub-theme;
        nixos-shim = inputs.nixos-shim;
      };

      modules = [
        ../hosts/${hostName}/default.nix
      ];
    }
  );
}
