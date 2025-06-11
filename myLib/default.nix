{
  nixpkgs,
  inputs,
  myNixOS,
  ...
}: {
  # mkSystem function to create NixOS configurations
  mkSystem = {
    hostname,
    system ? "x86_64-linux",
    extraModules ? [],
    specialArgs ? {},
  }: let
    # Merge provided specialArgs with inputs
    mergedSpecialArgs = specialArgs // {inherit inputs;};
  in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = mergedSpecialArgs;
      modules =
        [
          # Host-specific configuration
          ./hosts/${hostname}/configuration.nix
          
          # Custom NixOS modules loaded via haumea
          myNixOS
          
          # Home Manager integration
          inputs.home-manager.nixosModules.default
        ]
        ++ extraModules;
    };

  # mkHome function to create standalone Home Manager configurations
  mkHome = {
    username,
    system ? "x86_64-linux",
    homeDirectory ? "/home/${username}",
    extraModules ? [],
    extraSpecialArgs ? {},
  }: let
    pkgs = nixpkgs.legacyPackages.${system};
    # Load Home Manager modules using haumea if they exist
    myHomeModules = 
      if builtins.pathExists ./homeManagerModules
      then inputs.haumea.lib.load {
        src = ./homeManagerModules;
        inputs = {
          inherit (nixpkgs) lib;
        };
      }
      else {};
  in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = extraSpecialArgs // {inherit inputs;};
      modules =
        [
          # User-specific home configuration
          ./hosts/${username}/home.nix
          
          # Custom Home Manager modules if they exist
          myHomeModules
          
          # Base configuration
          {
            home = {
              inherit username homeDirectory;
              stateVersion = "24.11";
            };
            programs.home-manager.enable = true;
          }
        ]
        ++ extraModules;
    };

  # mkWSL function to create WSL NixOS configurations
  mkWSL = {
    hostname,
    username ? "nixos",
    extraModules ? [],
    specialArgs ? {},
    wslVersion ? 2,
  }: let
    # Merge provided specialArgs with inputs and WSL-specific args
    mergedSpecialArgs = specialArgs // {
      inherit inputs;
      wsl = {
        inherit wslVersion;
      };
    };
  in
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = mergedSpecialArgs;
      modules =
        [
          # Host-specific configuration
          ./hosts/${hostname}/configuration.nix
          
          # Custom NixOS modules loaded via haumea
          myNixOS
          
          # Home Manager integration
          inputs.home-manager.nixosModules.default
          
          # WSL-specific configuration
          {
            # WSL-specific settings
            wsl = {
              enable = true;
              automountPath = "/mnt";
              defaultUser = username;
              startMenuLaunchers = true;
              
              # WSL version specific settings
              version = wslVersion;
              
              # Enable systemd if WSL2
              systemd = nixpkgs.lib.mkIf (wslVersion == 2) {
                enable = true;
              };
            };
            
            # Disable unnecessary services for WSL
            services = {
              resolved.enable = false;
            };
            
            # WSL doesn't need a bootloader
            boot.loader.grub.enable = false;
            
            # Network configuration for WSL
            networking = {
              dhcpcd.enable = false;
              useNetworkd = true;
            };
            
            # Users configuration
            users.users.${username} = {
              isNormalUser = true;
              extraGroups = ["wheel" "networkmanager"];
            };
          }
        ]
        ++ extraModules;
    };

  # mkDarwin function to create macOS configurations (if needed in the future)
  mkDarwin = {
    hostname,
    system ? "aarch64-darwin",
    extraModules ? [],
    specialArgs ? {},
  }: let
    # This would require nix-darwin input
    mergedSpecialArgs = specialArgs // {inherit inputs;};
  in
    if inputs ? nix-darwin
    then
      inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = mergedSpecialArgs;
        modules =
          [
            ./hosts/${hostname}/configuration.nix
            myNixOS
          ]
          ++ extraModules;
      }
    else
      throw "nix-darwin input is required for mkDarwin function";

  # Helper function to create multiple systems at once
  mkSystems = systemsConfig: 
    nixpkgs.lib.mapAttrs (name: config: 
      if config.type or "nixos" == "nixos" then
        nixpkgs.lib.mkSystem (config // {hostname = name;})
      else if config.type == "home" then
        nixpkgs.lib.mkHome (config // {username = name;})
      else if config.type == "wsl" then
        nixpkgs.lib.mkWSL (config // {hostname = name;})
      else if config.type == "darwin" then
        nixpkgs.lib.mkDarwin (config // {hostname = name;})
      else
        throw "Unknown system type: ${config.type}"
    ) systemsConfig;

  # Utility function to enable features across multiple hosts
  enableFeatures = features: {
    features = nixpkgs.lib.genAttrs features (_: {enable = true;});
  };

  # Helper to create user configurations
  mkUser = {
    username,
    description ? username,
    extraGroups ? ["networkmanager" "wheel"],
    shell ? null,
    hashedPassword ? null,
    initialPassword ? null,
    packages ? [],
  }: {
    users.users.${username} = {
      isNormalUser = true;
      inherit description extraGroups;
    } // nixpkgs.lib.optionalAttrs (shell != null) {
      inherit shell;
    } // nixpkgs.lib.optionalAttrs (hashedPassword != null) {
      inherit hashedPassword;
    } // nixpkgs.lib.optionalAttrs (initialPassword != null) {
      inherit initialPassword;
    } // nixpkgs.lib.optionalAttrs (packages != []) {
      inherit packages;
    };
  };
}
