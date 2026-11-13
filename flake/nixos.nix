# flake/nixos.nix
{ inputs, ... }:

let
  lib = inputs.nixpkgs.lib;
  hostsDir = ../hosts/nixos; # 改为 nixos 子目录

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
        nixos-shim = inputs.nixos-shim;
      };
      modules = [ ../hosts/nixos/${hostName}/default.nix ]; # 同步修改
    }
  );
}
