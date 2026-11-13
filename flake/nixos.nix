# flake/nixos.nix
{ inputs, ... }:

let
  lib = inputs.nixpkgs.lib;
  hostsDir = ../hosts/nixos;

  isHost =
    name: type:
    type == "directory"
    && !(lib.hasPrefix "." name)
    && builtins.pathExists (hostsDir + "/${name}/default.nix");

  hosts = builtins.attrNames (lib.filterAttrs isHost (builtins.readDir hostsDir));
in
{
  flake.nixosConfigurations = lib.genAttrs hosts (
    hostName:
    lib.nixosSystem {
      specialArgs = {
        inherit inputs hostName;
      };
      modules = [
        ../hosts/nixos/${hostName}/default.nix
        inputs.home-manager.nixosModules.home-manager # ← 新增：接 home-manager
      ];
    }
  );
}