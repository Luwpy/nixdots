{
  # config,
  lib,
  ...
}: {
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
}
