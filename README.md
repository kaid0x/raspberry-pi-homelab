# Raspberry Pi Security Homelab

A self-hosted, security-focused homelab built from scratch on a **Raspberry Pi 3 Model B (v1.2, 1GB RAM)**, running headless on Raspberry Pi OS Lite (64-bit).

This repo documents not just *what* was built, but **every major decision, what alternatives were considered, what failed, and why the final approach was chosen.** The reasoning is the point — the configs are secondary.

---

## What this homelab does

| Service | Purpose | Port |
|---|---|---|
| **Pi-hole** | Network-wide ad/tracker blocking (DNS sinkhole) | 80 `/admin` |
| **Unbound** | Local recursive DNS resolver with DNSSEC (no third-party resolver) | 5335 |
| **Tailscale** | Secure remote access + DNS-anywhere (WireGuard-based mesh VPN) | — |
| **Docker** | Container runtime for the services below | — |
| **File Browser** | Personal file server on a dedicated USB drive | 8080 |
| **Uptime Kuma** | Service monitoring / uptime dashboard | 3001 |
| **ntfy** | Self-hosted push notifications for alerts | 8181 |
| **Homepage** | Unified dashboard with live service stats | 3000 |

Plus: SSH hardening (key-only auth + fail2ban), a fixed IP via DHCP reservation, and an automated nightly file backup to a second USB drive via `rsync` + `cron`.

---

## Architecture

```
Devices (Mac, iPhone)
      |
      v
  Pi-hole  ---(blocks ads/trackers, then forwards)--->  Unbound  ---(recursive resolution + DNSSEC)--->  Root DNS servers
      |
  Raspberry Pi 3B (Docker host)
      |-- File Browser  -> /mnt/filedrive (16GB USB 3.0, ext4)
      |-- Uptime Kuma
      |-- ntfy
      |-- Homepage
      |
  Nightly rsync backup -> /mnt/backupdrive (32GB USB 2.0, exFAT, portable)
      |
  Tailscale ---(NAT-traversal mesh VPN)---> reachable from anywhere, no port forwarding
```

DNS chain: **your devices → Pi-hole (filter) → Unbound (resolve from root, validate DNSSEC) → internet.** No third-party resolver ever sees your lookups.

---

## Build order (and why this order)

Security-first sequencing was deliberate. Each step assumes the previous one is done.

1. **Flash Raspberry Pi OS Lite** — headless, SSH pre-enabled, own credentials set at flash time.
2. **SSH hardening** — key-based auth, then disable password auth entirely, add fail2ban. *Done before exposing anything.*
3. **DHCP reservation** — fix the Pi's IP so nothing that depends on it breaks.
4. **Pi-hole** — network filtering + a real intro to how DNS works.
5. **Unbound** — replace the third-party upstream resolver with your own recursive one.
6. **Tailscale** — remote access (see the big decision writeup in `docs/networking-decision.md`).
7. **Docker** — container runtime.
8. **File Browser + automated backups** — file server with `rsync`/`cron` redundancy.
9. **Uptime Kuma + ntfy** — monitoring and self-hosted alerts.
10. **Homepage** — tie it all together into one dashboard.

See `docs/` for the detailed decision writeups.

---

## Key decisions & what was rejected

Short version below — full reasoning in `docs/decisions.md` and `docs/networking-decision.md`.

- **Remote access: Tailscale, not WireGuard/DynDNS/DD-WRT.** The apartment sits behind **double-NAT** with an ISP/building-managed ONT we have no password for. Every approach that needs inbound port forwarding is blocked at that upstream device. Tailscale uses outbound NAT-traversal, so it needs nothing from the ONT. **This is the single most important decision in the project** — full writeup in `docs/networking-decision.md`.
- **DNS: Pi-hole + Unbound, not just Pi-hole → Cloudflare.** Unbound removes the third-party resolver dependency and teaches DNS resolution end-to-end.
- **OS: Lite, not Desktop.** 1GB RAM — every MB counts; a headless server has no use for a GUI.
- **Main drive: ext4; backup drive: exFAT.** Main lives in the Pi (ext4 = robust, correct permissions). Backup is portable (exFAT = readable on any Mac/Windows/Linux machine for recovery).
- **Notifications: self-hosted ntfy, not Telegram.** More private and self-hosted, consistent with the project's ethos. Trade-off: iOS background push for self-hosted servers is unreliable (documented in `docs/known-issues.md`).
- **Pi-hole `listeningMode = ALL`** — required for Pi-hole to answer DNS over the Tailscale interface. Safe *here specifically* because the Pi is behind double-NAT with zero port forwarding, so port 53 is not internet-reachable. Would be dangerous on a public VPS. See `docs/decisions.md`.

---

## What I'd improve next (honest gaps)

- **Back up the SD card / configs**, not just files. If the OS SD card dies, the whole setup is currently lost. Highest-priority improvement.
- **Migrate `docker run` commands to a single `docker-compose.yml`** for reproducibility.
- **A rebuild runbook** so recovery is an hour, not a lost weekend.
- **Security blocklists** for Pi-hole (malware/phishing/ransomware) — a quick passive-security win.
- **Off-Pi / offsite copy** of important files (current two-USB setup protects against a drive dying, not against the Pi being lost/stolen/fried).

---

## Skills demonstrated

Linux administration, SSH & public-key cryptography, DNS internals (recursion, DNSSEC, sinkholing), VPN / NAT-traversal concepts, Docker & containers, Linux filesystems (ext4 vs exFAT, `fstab`, mounting), `rsync`, `cron` scheduling, self-hosting, and REST API integration — plus real debugging (SSH key-generation mistake, DNS override outage, exFAT permissions, iOS push limits).

## Repo contents

- `docs/decisions.md` — every significant decision and the reasoning
- `docs/networking-decision.md` — the deep-dive on why Tailscale (and why WireGuard/DynDNS/DD-WRT all failed)
- `docs/setup-guide.md` — step-by-step build notes (secrets redacted)
- `docs/known-issues.md` — problems hit and how they were solved
- `config/` — sanitized config examples (no secrets)
- `scripts/` — the backup script

> ⚠️ All secrets (passwords, API keys, public IP, Tailscale names) have been redacted or replaced with placeholders. See `docs/security-notes.md`.
