{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    grub-theme = {
      url = "github:13atm01/GRUB-Theme";
      flake = false;
    };
    nixos-shim = {
      url = "github:RaitoBezarius/nixos-shim";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      grub-theme,
      ...
    }@inputs:
    {
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          grub-theme = inputs.grub-theme;
          nixos-shim = inputs.nixos-shim;
        };
        modules = [
          ./configuration.nix
          ./modules/disko.nix
          inputs.disko.nixosModules.disko
        ];
      };
    };
}
