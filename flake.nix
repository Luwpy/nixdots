{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    myNixOS = inputs.haumea.lib.load {
      src = ./nixosModules;
      inputs = {
        inherit (nixpkgs) lib;
      };
    };
  in {
    nixosConfigurations.athena = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/athena/configuration.nix
        myNixOS

        inputs.home-manager.nixosModules.default
      ];
    };
  };
}
