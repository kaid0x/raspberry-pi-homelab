# Setup Guide

Condensed build steps. Replace `USER`, `PI_LOCAL_IP`, etc. with your own values. Secrets redacted.

## 1. Flash the OS
- Raspberry Pi Imager → Raspberry Pi OS **Lite (64-bit)**.
- In "Edit settings": set hostname, username/password, **enable SSH (password auth)** under Services, set locale. (Password auth is temporary — hardened in step 3.)

## 2. First boot + connect (headless)
- Boot on ethernet, find the IP (router device list), then:
  `ssh USER@PI_LOCAL_IP`
- Update: `sudo apt update && sudo apt full-upgrade -y`

## 3. SSH hardening
- On your **Mac**: `ssh-keygen -t ed25519` then `ssh-copy-id USER@PI_LOCAL_IP`
  (Confirm the prompt is your Mac's, not the Pi's — see known-issues.)
- On the Pi: set `PasswordAuthentication no` in `/etc/ssh/sshd_config`
  **and** in any override under `/etc/ssh/sshd_config.d/*.conf`.
- `sudo systemctl restart ssh`, then verify key login works in a NEW window before closing the old one.
- `sudo apt install fail2ban -y`, add a `[sshd]` jail in `/etc/fail2ban/jail.local`, restart.

## 4. Fixed IP
- Router admin → DHCP Reservation → bind the Pi's MAC to its current IP.

## 5. Pi-hole
- `curl -sSL https://install.pi-hole.net | bash`
- Interface eth0, upstream = (temporary, replaced by Unbound), enable web UI + query logging.
- Set admin password: `sudo pihole setpassword`
- Point devices' DNS at the Pi (per-device or router-wide).

## 6. Unbound
- `sudo apt install unbound -y`
- Add `config/unbound-pi-hole.conf` to `/etc/unbound/unbound.conf.d/`
- `sudo systemctl restart unbound`
- Test: `dig dnssec-failed.org @127.0.0.1 -p 5335` → SERVFAIL (good);
  `dig cloudflare.com @127.0.0.1 -p 5335` → NOERROR with `ad` flag.
- In Pi-hole → Settings → DNS → set custom upstream `127.0.0.1#5335`, uncheck the rest.

## 7. Tailscale
- `curl -fsSL https://tailscale.com/install.sh | sh`
- `sudo tailscale up` → authenticate via the URL.
- Install Tailscale on Mac + phone (same account).
- (DNS-anywhere) Admin console → add the Pi's Tailscale IP as a nameserver, enable "Override local DNS".
- Set Pi-hole `listeningMode = ALL` so it answers over Tailscale:
  `sudo pihole-FTL --config dns.listeningMode ALL && sudo systemctl restart pihole-FTL`

## 8. Docker
- `curl -fsSL https://get.docker.com | sh`
- `sudo usermod -aG docker USER` then log out/in.

## 9. Storage + File Browser
- Format main drive ext4, backup drive exFAT; add both to `/etc/fstab` with `nofail`
  (exFAT line needs `uid=1000,gid=1000`).
- Run File Browser container, `-v /mnt/filedrive:/srv`, port 8080.
- Add `scripts/backup.sh`, `chmod +x`, schedule in `crontab -e`: `30 4 * * * /home/USER/backup.sh`

## 10. Monitoring + dashboard
- Uptime Kuma container (port 3001) → add HTTP/Ping monitors.
- ntfy container (port 8181, `serve --base-url=http://PI_LOCAL_IP:8181`) → subscribe phone via Tailscale address.
- Wire ntfy into Uptime Kuma notifications, apply to all monitors.
- Homepage container (port 3000) → use `config/homepage-services.yaml`, `config/homepage-settings.yaml`.
