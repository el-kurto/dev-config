{
  pkgs,
  lib,
  codegraph,
}:
pkgs.buildGoModule {
  pname = "codegraph-hook";
  version = "0.1.0";
  src = ./hook;
  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
    "-X main.gitBin=${lib.getExe pkgs.git}"
    "-X main.codegraphBin=${lib.getExe codegraph}"
  ];

  nativeCheckInputs = [pkgs.git codegraph];

  meta = {
    description = "Claude Code hooks that keep a codegraph index per worktree";
    mainProgram = "codegraph-hook";
  };
}
