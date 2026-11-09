# Working in /home/chloe/nixos

Chloe's NixOS flake. These rules come from the repo's own history, not from a
generic template.

- The agent edits config and verifies it by evaluation; **Chloe runs `sudo
  nixos-rebuild switch --flake ~/nixos#<output>` herself.** Never ask for, print
  or observe a sudo password. `sudo` is refused inside the agent sandbox, so
  every root-side step is hers.
- A change is not live until she has switched. Verify what can be verified, then
  say plainly which half is unverified instead of implying the change landed.
- Every new file the flake references must be `git add`ed: evaluation only sees
  tracked or staged paths, and an untracked module fails with "is not tracked by
  Git".
- Comment style is a dated rationale explaining *why* an option exists and what
  it replaced. A bare option looks unfinished next to the rest of the tree.
- Never `git add -A` or `git commit -a`: this tree routinely carries several
  unfinished workstreams at once. Stage explicit paths, and run git with
  `HOME=/home/chloe` (the agent's own HOME has no git identity).
- Never echo a password, key or token into a file in this tree or into chat. The
  nix store is world-readable, so a secret in the flake is a published secret.
- Option names, attribute names and version numbers are read from the pinned
  nixpkgs source, never written from memory.
