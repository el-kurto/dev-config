{
  pkgs,
  lib,
}: {
  enable = lib.mkEnableOption "codegraph code graph CLI";

  package = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    default = import ./package.nix pkgs;
    description = "The wrapped CLI, with telemetry and the daemon off.";
  };
}
