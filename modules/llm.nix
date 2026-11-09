{config, inputs, pkgs, pkgs-unstable,...}:

let
  # 2026-11-08: the desktop package hand-patches the bundled Bun `lms` CLI with
  #   patchelf --set-interpreter … --set-rpath …
  # and that rpath rewrite corrupts the ELF segment layout (PT_DYNAMIC moves to
  # file offset 680, into the ELF/program headers). ld.so then segfaults inside
  # _dl_check_map_versions before main — every subcommand, rc=139. Reproduced
  # byte-for-byte: the packaged binary is identical to the upstream AppImage
  # binary plus exactly those two flags, --set-interpreter alone runs fine, and
  # --set-rpath alone reproduces the crash. Diagnosis:
  # ~/projects/agent-builds/local-triage/NOTES-lms.md
  #
  # The same flake's `lmstudio-server` ships that CLI the safe way
  # (autoPatchelfHook + binary wrapper, no in-place rpath rewrite), so build the
  # desktop app without its broken copy and take `lms`/`llmster` from the server
  # output: one bin/lms in the profile, no collision. Appended to buildCommand
  # because appimageTools.wrapType2 is a runCommand — it has no install/fixup
  # phases, so a postFixup hook would silently never run.
  lmstudioDesktop =
    inputs.lmstudio.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (old: {
        buildCommand = (old.buildCommand or "") + ''
          rm -f $out/bin/lms
        '';
      });
in
{
  environment.systemPackages = [
    # opencode, for vibe coding
    pkgs-unstable.opencode
    # lm studio for running local llms (GUI). Its lms is removed: see above.
    lmstudioDesktop
    # headless daemon (llmster) + a working lms CLI, same flake output
    inputs.lmstudio.packages.${pkgs.stdenv.hostPlatform.system}.lmstudio-server
  ];

}
