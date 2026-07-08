# Decision Log

Every significant choice in the build, the alternatives, and the reasoning. (Remote-access decision has its own file: `networking-decision.md`.)

## OS: Raspberry Pi OS Lite (64-bit) vs Desktop
- **Chosen:** Lite (headless, command-line only).
- **Why:** 1GB RAM board — no reason to spend memory on a GUI for an always-on server. Forces terminal use (a core skill). A monitor can still be plugged into Lite for local troubleshooting; it just shows a text console.
- **Reversible:** can add a desktop later with `sudo apt install raspberrypi-ui-mods`, or re-flash. Not a permanent choice.

## SSH: key-only auth vs password
- **Chosen:** generate an ed25519 keypair, install the public key, then **disable password auth entirely** + add fail2ban.
- **Why:** passwords are brute-forceable; keys are not. Hardening is done *before* anything is exposed. fail2ban auto-bans repeated failed attempts.
- **Gotcha hit:** a config override file (`/etc/ssh/sshd_config.d/50-cloud-init.conf`) contained `PasswordAuthentication yes` and silently overrode the main config. Modern OpenSSH loads `Include` files that take precedence. Had to edit the override, not just the main file. (See `known-issues.md`.)

## Fixed IP: DHCP reservation (on router) vs static IP (on Pi)
- **Chosen:** DHCP reservation on the router.
- **Why:** router stays the single source of truth for IP assignment → no risk of IP conflicts. Pi-hole *needs* a stable IP (every device points at it for DNS; if it changed, DNS breaks network-wide).

## Upstream DNS: Unbound (recursive) vs public resolver (Cloudflare/Google)
- **Chosen:** Pi-hole forwards to a local **Unbound** recursive resolver instead of a public one.
- **Why:** privacy (no third party sees your lookups) + learning how DNS resolution actually works (root → TLD → authoritative). DNSSEC validation confirmed working (bad-signature domain returns SERVFAIL; good domain returns the `ad` authenticated-data flag).
- **Trade-off:** slightly slower first lookups until Unbound's cache warms (negligible).

## Pi-hole listening mode: `ALL` vs `LOCAL`
- **Chosen:** `dns.listeningMode = ALL`.
- **Why:** Pi-hole in `LOCAL` mode rejects queries it considers non-local — including queries arriving over the Tailscale interface. `ALL` lets it answer over Tailscale (needed for DNS-anywhere).
- **Is `ALL` safe here?** Yes, *for this specific setup*: the Pi is behind double-NAT with **zero port forwarding**, so port 53 is not reachable from the internet. Only the LAN and the Tailscale tailnet can reach it. `ALL`/"permit all origins" is only dangerous on internet-reachable machines (e.g. a cloud VPS, or a home with port 53 forwarded) — neither applies.
- **The principle worth keeping:** never use `ALL` on a publicly-reachable DNS server (open resolvers get abused for DDoS amplification). Safe here purely because of the NAT.

## Storage: two USB drives, main + backup
- **Main:** 16GB USB 3.0, **ext4**, lives in the Pi, served by File Browser. ext4 = robust journaling + proper Linux permissions.
- **Backup:** 32GB USB 2.0, **exFAT**, portable. exFAT = readable natively on any Mac/Windows/Linux machine, so files are recoverable anywhere without special software. The whole point of a backup is recoverability, so portability wins over ext4's marginal robustness edge for the backup role specifically.
- **Backup method:** nightly `rsync -rt --delete` (mirror) via `cron` at 04:30, with a log file. `-rt` (not `-a`) because exFAT can't store Linux ownership/permissions.
- **Note:** the Pi 3 only has USB 2.0 ports, so the USB 3.0 drive runs at 2.0 speed — but still chosen as main for its better controller and future-proofing.

## Notifications: self-hosted ntfy vs Telegram vs Discord vs email
- **Chosen:** self-hosted ntfy.
- **Why:** most private + fully self-hosted, consistent with the project ethos. Tailscale already solves the "reach my phone when away" problem, removing ntfy self-hosting's usual obstacle.
- **Trade-off (real):** iOS background push for *self-hosted* ntfy servers is unreliable (Apple's push system favors the public ntfy.sh server). Messages arrive but may not buzz the lock screen without opening the app. Accepted for now; can switch to Telegram in ~2 min if it becomes annoying (fully reversible — notifications are just an Uptime Kuma setting).

## Dashboard links: Tailscale MagicDNS name vs local IPs
- **Chosen:** point Homepage tiles at the Tailscale MagicDNS name.
- **Why:** one set of links that works both at home and away (with Tailscale on) — "everything in one place, connect and show anyone."
- **Trade-off:** tiles now depend on Tailscale being on, even at home. Accepted deliberately. The Pi-hole *stats widget* still uses the local IP (Homepage → Pi-hole is an internal same-box call).
- **Security note investigated:** routing home traffic through Tailscale adds negligible security *at home* (LAN traffic isn't internet-exposed anyway); the real encryption benefit is away-from-home, which applies regardless. Chosen for convenience, not a security upgrade.

## Ruled out entirely (board/network limits)
- **Jellyfin** — video transcoding is too heavy for a Pi 3; wants a Pi 4/5.
- **Serious always-on IDS (Suricata/Zeek)** — strains 1GB RAM; also only sees traffic reaching the Pi unless it's the gateway. Learning-only at best.
- **Cowrie honeypot** — wants internet exposure to catch real attacks; the same NAT that blocks WireGuard blocks a useful honeypot. Deferred.
- **Hackberry Pi** — a separate handheld device (needs a Pi Zero 2 W or CM5), not compatible with the Pi 3 B. Unrelated to this build.
