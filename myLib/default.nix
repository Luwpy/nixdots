{
  inputs,
  haumea,
  ...
}: let
  inherit (inputs.nixpkgs) lib;
in {
  # Load all nixosModules using haumea
  nixosModules = haumea.load {
    src = ../nixosModules;
    inputs = {
      inherit (inputs.nixpkgs) lib;
    };
  };

  # Load all homeManagerModules using haumea
  homeManagerModules = haumea.load {
    src = ../homeManagerModules;
    inputs = {
      inherit (inputs.nixpkgs) lib;
    };
  };

  # Helper function to create NixOS systems
  mkSystem = system: configPath: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
        inherit pkgs;
      };
      modules =
        [
          configPath
          # Automatically include all nixosModules
          inputs.home-manager.nixosModules.default
        ]
        ++ (lib.attrValues (haumea.load {
          src = ../nixosModules;
          inputs = {
            inherit (inputs.nixpkgs) lib;
          };
        }));
    };

  # Helper function to create Home Manager configurations
  mkHome = system: homePath: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in
      inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs;
      };
      modules =
        [
          homePath
        ]
        ++ (lib.attrValues (haumea.load {
          src = ../homeManagerModules;
          inputs = {
            inherit (inputs.nixpkgs) lib;
          };
        }));
    };
}
