# flake/darwin.nix
{ inputs, ... }:

let
  lib = inputs.nixpkgs.lib;
  hostsDir = ../hosts/darwin;

  isHost =
    name: type:
    type == "directory"
    && !(lib.hasPrefix "." name)
    && builtins.pathExists (hostsDir + "/${name}/default.nix");

  hosts = builtins.attrNames (lib.filterAttrs isHost (builtins.readDir hostsDir));
in
{
  flake.darwinConfigurations = lib.genAttrs hosts (
    hostName:
    inputs.nix-darwin.lib.darwinSystem {
      system = "x86_64-darwin";
      specialArgs = { inherit inputs hostName; };
      modules = [
        ../hosts/darwin/${hostName}/default.nix
        inputs.home-manager.darwinModules.home-manager # ← 新增：home-manager（darwin 用 darwinModules）
        inputs.sops-nix.darwinModules.sops # ← 新增：sops-nix（darwin 用 darwinModules）
      ];
    }
  );
}