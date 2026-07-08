# Security Notes (what's redacted and why)

This repo is safe to make public. Everything sensitive has been removed or replaced with placeholders.

## Redacted / never committed
- **Passwords** (Pi login, Pi-hole admin, File Browser, Uptime Kuma) — never in the repo. Keep in a password manager.
- **Pi-hole API app password** — replaced with `PIHOLE_APP_PASSWORD` placeholder.
- **Public IP address** — referred to only as `87.x.x.x`.
- **Tailscale MagicDNS name / tailnet ID** — replaced with `PI_MAGICDNS_NAME`. (These only work for authenticated devices anyway, but no reason to publish them.)
- **ntfy topic name** — a topic name acts like a shared secret on a default ntfy setup; replaced with a placeholder. Use a long, unguessable topic.
- **Device MAC addresses, serial numbers** — not included.
- **SSH private key** — obviously never leaves the machine it was generated on.

## Placeholders used
| Placeholder | Meaning |
|---|---|
| `USER` | your Linux username on the Pi |
| `PI_LOCAL_IP` | the Pi's LAN IP (e.g. 192.168.x.x) |
| `PI_MAGICDNS_NAME` | your Tailscale MagicDNS name (e.g. host.tailXXXX.ts.net) |
| `PIHOLE_APP_PASSWORD` | Pi-hole API app password |

## Good habits reflected here
- App password for the Pi-hole API instead of the main admin password (revocable, scoped).
- Key-only SSH, password auth disabled, fail2ban.
- Services reachable only via LAN or Tailscale — never exposed to the open internet.
- Pi-hole `listeningMode = ALL` is safe *only because* of the NAT (see `decisions.md`); this would be unsafe on a public host.

> If a secret ever *does* get committed by accident: rotate it immediately (change the password / regenerate the key), because git history keeps it even after deletion.
