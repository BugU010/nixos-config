{
  description = "My NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    grub-theme = {
      url = "github:13atm01/GRUB-Theme";
      flake = false;
    };
    nixos-shim = {
      url = "github:RaitoBezarius/nixos-shim";
      flake = false;
    };
    # 如果你还有 disko 等其他 input，保留在这里
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        ./flake/nixos.nix
      ];
    };
}
