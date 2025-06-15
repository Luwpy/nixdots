{
  lib,
  config,
  ...
}: {
  options.features.doas = {
    enable = lib.mkEnableOption "Enable doas instead of sudo";
  };

  config = lib.mkIf config.features.doas.enable {
    security.sudo.enable = lib.mkForce false;
    security.doas = {
      enable = true;
      extraRules = [
        {
          groups = ["wheel"];
          keepEnv = true;
          persist = true;
        }
      ];
    };
  };
}
