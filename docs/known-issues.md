# Known Issues & Fixes

Real problems hit during the build and how they were solved. This is where most of the actual learning happened.

## SSH: keypair generated on the wrong machine
- **Symptom:** after disabling password auth, `Permission denied (publickey)` from the Mac — nearly a lockout.
- **Cause:** `ssh-keygen`/`ssh-copy-id` were run *from inside an SSH session on the Pi* (prompt showed `user@pi`), so the key was generated on the Pi and the Pi authorized *itself*. The Mac never had a key.
- **Fix:** generate the keypair on the **Mac** (confirm the prompt is the Mac's). Because password auth was already off, `ssh-copy-id` couldn't log in — so the public key was pasted manually into `~/.ssh/authorized_keys` using the still-open original session.
- **Lesson:** always keep one working session open when changing SSH/auth settings. It was the safety net that prevented a full lockout.

## SSH: password auth wouldn't disable
- **Symptom:** set `PasswordAuthentication no` in `sshd_config`, restarted, still prompted for password.
- **Cause:** an override file `/etc/ssh/sshd_config.d/50-cloud-init.conf` had `PasswordAuthentication yes`. `Include`d files override the main config.
- **Fix:** edit the override file, not just the main config.

## DNS outage after enabling Tailscale "Override local DNS"
- **Symptom:** enabling override in Tailscale made browsing/dashboard fail; looked like the internet broke.
- **Cause:** devices were told to use the Pi for DNS over Tailscale *before* Pi-hole was configured to accept Tailscale queries (`listeningMode` was `LOCAL`), so lookups went unanswered.
- **Fix:** correct order is (1) set Pi-hole `listeningMode = ALL` first, (2) *then* enable override. Toggling override off instantly reverts — the escape hatch.
- **Lesson:** SSH doesn't use DNS, so the Pi stayed reachable to fix it. Order of operations matters.

## exFAT backup drive: rsync permission denied
- **Symptom:** `rsync` to the backup drive failed with `Operation not permitted` / `Permission denied`, and tried to copy `lost+found`.
- **Causes:** (1) drive not owned by the user (exFAT sets ownership at mount time via `uid=`/`gid=`; needed a remount to apply); (2) `rsync -a` tries to preserve Linux ownership/permissions that exFAT can't store; (3) it tried to copy the ext4-only `lost+found` folder.
- **Fix:** remount to apply `uid=1000,gid=1000`; use `rsync -rt` (not `-a`) to skip owner/perms; add `--exclude 'lost+found'`.

## ntfy: no push notifications on iPhone
- **Symptom:** messages appear in the ntfy app only when opened; no lock-screen buzz.
- **Cause:** iOS restricts background push for *self-hosted* ntfy servers. "Instant delivery" (persistent connection) is generally only offered for the public ntfy.sh server. Apple's push system favors the hosted service.
- **Status:** accepted for now (check the app periodically). Fixes if it matters later: use ntfy.sh as a relay (less private), or switch to Telegram (no iOS push issues). Fully reversible.

## MagicDNS name has a trailing dot
- **Note:** `tailscale status --json` shows the DNS name as `homelab.tailXXXX.ts.net.` with a trailing dot — drop the dot when using it in URLs/config.
