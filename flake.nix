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
      flake = false;   # 关键：当源码树用，不当中不是常规 flake
    };
  };

  outputs =
    { self, nixpkgs, grub-theme, ... }@inputs:
    {
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs;
        grub-theme = inputs.grub-theme;   # 裸参数，模块里直接接
        nixos-shim = inputs.nixos-shim;   # 提前备好，后面用得到
 };
        modules = [ ./configuration.nix ];
      };
    };
}
