{
  pkgs,
  lib,
  config,
  ...
}: {
  options.features.niri = {
    enable = lib.mkEnableOption "Enable niri window manager";
  };

  config = lib.mkIf config.features.niri.enable {
    programs.niri.enable = true;
  };
}
