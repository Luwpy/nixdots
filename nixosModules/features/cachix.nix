{
  pkgs,
  lib,
  config,
  ...
}: {
  options.features.cachix = {
    enable = lib.mkEnableOption "Enable cachix";
  };

  config = lib.mkIf config.features.cachix.enable {
    nix = {
      optimise.automatic = true;
      settings.auto-optimise-store = true;
    };
  };
}
