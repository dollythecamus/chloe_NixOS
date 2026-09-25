{ lib, buildGoModule, fetchFromGitHub }:
buildGoModule {
  pname = "termagotchi";
  version = "0-unstable-2026-09-25";
  src = fetchFromGitHub {
    owner = "ezeoleaf";
    repo = "termagotchi";
    rev = "f20c23e68627b51d216d80ab591d212b2dd3fcd9";
    hash = "sha256-QucaPdI2jfY9zPCCpR8TlGUtqVmWAvx7FrZ7mnfqP5Q=";
  };
  vendorHash = "sha256-/oB6etdjPhf4v0PjLReb/sf+UHB3elsSDuoLqVmiixg=";
  subPackages = [ "cmd/termagotchi" ];
  # Off-session time must not punish disabling an optional, on-demand process.
  # Keep normal decay while the TUI is running; preserve YAML state on clean exit.
  postPatch = ''
    substituteInPlace internal/app/app.go \
      --replace-fail 'a.applyOfflineProgress()' '// No decay while closed.'
  '';
  meta = {
    description = "On-demand terminal virtual pet (offline decay disabled for the prototype)";
    homepage = "https://github.com/ezeoleaf/termagotchi";
    license = lib.licenses.mit;
    mainProgram = "termagotchi";
    platforms = lib.platforms.linux;
  };
}
