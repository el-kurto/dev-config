pkgs:
pkgs.symlinkJoin {
  name = "codegraph-${pkgs.codegraph.version}";
  paths = [pkgs.codegraph];
  nativeBuildInputs = [pkgs.makeWrapper];
  postBuild =
    # bash
    ''
      wrapProgram "$out/bin/codegraph" \
        --set-default DO_NOT_TRACK 1 \
        --set-default CODEGRAPH_TELEMETRY 0 \
        --set-default CODEGRAPH_NO_DAEMON 1
    '';
  inherit (pkgs.codegraph) meta;
}
