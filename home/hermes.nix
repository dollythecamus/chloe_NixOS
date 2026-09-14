{ config, pkgs, inputs, ... }:

{
  # ── Interactive Hermes CLI/TUI: its own state store at ~/.hermes ─────────
  # The gateway service owns /var/lib/hermes/.hermes exclusively, because
  # hermes 0.21.x re-hardens its own state files whenever it opens them for
  # writing:
  #   hermes_state._secure_state_db_files() -> chmod 0600 state.db/-wal/-shm
  #   hermes_constants.secure_parent_dir()  -> chmod 0700 HERMES_HOME
  # Those are ownership operations, not mode adjustments: a second uid gets
  # EPERM/EACCES however the group bits are set, so a shared HERMES_HOME
  # cannot work for the interactive user. This account gets a home it owns.
  #
  # Files that must not drift from the gateway's are linked from the flake, so
  # the declared copy is a single source of truth, refreshed at every rebuild.
  # Caveat: if the app rewrites one of these itself (e.g. `hermes model` writes
  # config.yaml), it replaces the symlink with a real file and leaves a
  # `<name>__backup` behind; the next rebuild restores the flake version.
  home.file.".hermes/config.yaml".source = ../modules/config/hermes/config.yaml;
  home.file.".hermes/SOUL.md".source = ../modules/config/hermes/SOUL.md;

  # ~/.hermes/.env is NOT declared here: it is seeded by the `hermes-user-home`
  # activation script in modules/hermes.nix, which copies the decrypted agenix
  # secret as root (the secret stays 0400 root; chloe reads the copy).
}
