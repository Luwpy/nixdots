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
    # Import your custom library
    lib = import ./myLib {
      inherit inputs;
      haumea = inputs.haumea.lib;
    };
    
    # Default system for convenience
    system = "x86_64-linux";
  in {
    # NixOS Configurations
    nixosConfigurations = {
      athena = lib.mkSystem system ./hosts/athena/configuration.nix;
    };

    # Home Manager Configurations
    homeConfigurations = {
      "luwpy@athena" = lib.mkHome system ./hosts/athena/home.nix;
    };

    # Export your library for reuse
    inherit lib;

   
  };
}
