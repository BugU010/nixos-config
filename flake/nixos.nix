{ inputs, ... }:

let
  lib = inputs.nixpkgs.lib;
  hostsDir = ../hosts;

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
        grub-theme = inputs.grub-theme;
        nixos-shim = inputs.nixos-shim;
      };
      modules = [
        ../hosts/${hostName}/default.nix
      ];
    }
  );
}
