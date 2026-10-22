# Phone access runbook (2026-10-22)

Config half is done in `modules/remote-access.nix`. This file is the half that needs a
keyboard, a sudo password, or a phone: run it in order.

Full write-up: `~/wiki/entities/phone-project-access.md`.

## 1. On the host (mostly already done 2026-10-22 13:38)

The config half was switched in on 2026-10-22 13:38 and `sudo tailscale up` has been run, so
these are re-checks rather than first-run steps:

```bash
sudo nixos-rebuild switch --flake ~/nixos#chloe-laptop   # NOT bare nixos-rebuild: /etc/nixos is a stale tree
systemctl is-active tailscaled syncthing sshd            # expect active active active
tailscale ip -4                                          # the 100.x address this machine answers on
grep -iE '^(PasswordAuthentication|KbdInteractiveAuthentication)' /etc/ssh/sshd_config   # expect "no" on both
```

If `tailscaled` is active but `tailscale ip -4` prints nothing, the node is not authorised yet:
`sudo tailscale up`, open the printed login URL with the same account as the phone app. That is
the one manual step and it has already been completed once.

Rollback: `sudo nixos-rebuild switch --rollback`. Nothing here touches boot or the desktop.

## 2. On the phone (Android)

| Need | App | Source | Note |
|---|---|---|---|
| Reach the host anywhere | Tailscale | Play Store | one VPN slot only; log in with the same account |
| git, ssh, editor | Termux | **F-Droid** | Play Store build is deprecated |
| Notes vault sync | Syncthing-Fork (`com.github.catfriend1.syncthingfork`) | F-Droid | official Android Syncthing app is discontinued |
| Browse `~/projects` | Material Files | F-Droid / Play | SFTP support built in; Acode also works for editing over SFTP |
| Read the vault | Obsidian | Play Store | points at the synced folder |

```bash
# in Termux
pkg install openssh git micro
ssh-keygen -t ed25519 -C phone
cat ~/.ssh/id_ed25519.pub      # copy this line to the host's ~chloe/.ssh/authorized_keys
mkdir -p ~/.ssh && cat >> ~/.ssh/config <<'EOF'
Host pc
  HostName <tailscale-ip>      # run `tailscale ip -4` on the host; or use the MagicDNS name
  User chloe
  IdentityFile ~/.ssh/id_ed25519
  ServerAliveInterval 30
EOF
ssh pc 'echo ok'               # must print ok with no password prompt before going further
```

`<tailscale-ip>` stands in for a value only the host can print — substitute the real address, do
not paste the angle brackets.

The host's `~chloe/.ssh/authorized_keys` holds exactly one line: the phone's `ssh-ed25519` key
(mode 600). Password login is already closed — `PasswordAuthentication = false` and
`KbdInteractiveAuthentication = false` in `modules/remote-access.nix`, live in
`/etc/ssh/sshd_config` as `no` on both. If that key is ever replaced (new phone, Termux
reinstall), do it in this order: re-open password auth in the module and rebuild → `ssh-copy-id
pc` the new key → verify `ssh pc 'echo ok'` → close it again. An empty `authorized_keys` with
the password path shut is a lockout with no way back in but a physical keyboard.

## 3. Repos reachable from the phone

Already applied 2026-10-22 to all 13 repos in `~/projects` (verified with
`git -C <repo> config receive.denyCurrentBranch` → `updateInstead`): a phone push updates the
host's checked-out files, and it refuses instead of clobbering when the host tree is dirty.

```bash
# from Termux (same <tailscale-ip> as the Host pc entry above)
git clone ssh://chloe@<tailscale-ip>/home/chloe/projects/ai-research-lab     # small, text
GIT_LFS_SKIP_SMUDGE=1 git clone ssh://chloe@<tailscale-ip>/home/chloe/projects/panopticon   # LFS: code only
```

Do not clone `UnityXR_3DMuseu` (23 GB) to a phone. If a repo turns out to be edited on both
sides and the dirty-tree refusal gets annoying, move it to a bare mirror
(`git init --bare ~/git/<repo>.git`) instead of fighting it.

## 4. Syncthing pairing (notes only)

```bash
# on the phone, in Termux: reach the host's web UI (bound to 127.0.0.1 by design)
ssh -N -L 8384:localhost:8384 pc
# then open http://localhost:8384 in the phone browser
```

Add the phone's device ID on the host, accept on the phone, share **`~/Mind`** and optionally
**`~/wiki`**. Never add `~/projects`. In each folder's ignore patterns put
`.obsidian/workspace*.json` (and `.stfolder` is automatic) so the vault stops churning.

## 5. Acceptance checks

- `ssh pc 'git -C ~/projects/ai-research-lab log -1 --stat'` from mobile data works.
- Push a trivial commit from the phone clone; on the host,
  `git -C ~/projects/ai-research-lab log -1 --stat` and `status --short` show it.
- A file edited in Obsidian on the phone appears in `~/Mind` on the host within seconds.
- `du -sh` the phone-side LFS clone: it must be far smaller than the host's copy.
