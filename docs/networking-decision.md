# Remote Access: Why Tailscale (and why everything else failed)

This is the most important decision in the whole project, so it gets its own document. The goal was simple: **reach the Pi and its services from outside the home network** (and get Pi-hole ad-blocking on mobile anywhere). Getting there required ruling out several "obvious" approaches — each of which failed for the *same underlying reason*.

## The network reality

The apartment is in a building with shared, centrally-managed internet:

```
Internet (fiber)
      |
      v
ISP-managed GPON ONT (fiber terminal, in a shared utility area)
   - This is where the public IP (87.x.x.x) actually lives
   - ISP / building managed
   - We do NOT have the admin password
      |
      v
Our own consumer router
   - WAN (internet-side) IP = a PRIVATE 192.168.x.x address
   - We DO have admin access to this one
      |
      v
Raspberry Pi (separate private subnet)
```

**The critical fact:** our router's WAN IP is a *private* address, not the public IP. That proves our router is **not** the network edge — it sits behind the building's ONT. This is a **double-NAT** setup. The device that actually faces the internet (the ONT) is one we cannot log into.

Verified two ways:
- `whatismyipaddress.com` showed public IP `87.x.x.x`
- our router's WAN status showed a private 192.168.x.x address
- They don't match → we're behind carrier/building NAT.

## The core problem

Any remote-access method that relies on **inbound connections** (something on the internet initiating a connection *to* our Pi) requires **port forwarding all the way through every device in the chain**. The chain has a device we can't configure (the ONT). Therefore inbound connections cannot be made to work. Full stop.

NAT only blocks *unsolicited inbound* traffic. *Outbound* connections (our devices reaching out) always work. That distinction is the key to the solution.

---

## Approaches considered and rejected

### ❌ Pure WireGuard (self-hosted VPN on the Pi)
- **Idea:** run a WireGuard server on the Pi, connect to it from outside.
- **Why it fails:** requires forwarding the WireGuard UDP port from the internet → through the ONT → to the Pi. The ONT won't forward (no access). Inbound dies at the ONT.
- Verdict: impossible without ONT access.

### ❌ DynDNS (Dynamic DNS)
- **Idea (suggested by a CS grad):** use a service like DuckDNS to map a hostname to our changing public IP.
- **Why it fails:** DynDNS only solves the *"public IP changes over time"* problem. It gives you a hostname pointing at the public IP — but the traffic still has to get *through the ONT* to reach the Pi, which still requires port forwarding on the ONT. **DynDNS is a hostname to a locked door.** It solves a different layer than the one that's blocking us.
- Verdict: doesn't address the actual blocker (the un-forwardable ONT).

### ❌ DD-WRT (custom router firmware on our router)
- **Idea:** flash open-source firmware to the router for a WireGuard server + advanced forwarding/DDNS on the router itself.
- **Why it fails:** DD-WRT makes *our router* more capable, but our router still has a private WAN IP behind the ONT. No firmware on a downstream device can force an upstream device it doesn't control to forward ports. Same wall, one layer up. Plus real bricking risk on the old router, and it'd be a slow VPN endpoint anyway.
- Verdict: upgrades the wrong layer. Blocker is upstream.

### ❌ Get the ONT bridged / port-forwarded
- **Idea:** ask for the ONT to be put in bridge mode so our router gets the public IP directly — then WireGuard/DynDNS/DD-WRT would all work.
- **Why it fails:** **we don't have the ONT password.** It's building/ISP-managed shared infrastructure. Not ours to reconfigure, and no access even if it were appropriate.
- Verdict: this was the linchpin for *all* the above approaches — and it's closed.

---

## ✅ The solution: Tailscale (WireGuard-based mesh VPN)

**Why it works where everything else failed:** Tailscale doesn't need *any* inbound port forwarding. Each device (Pi, Mac, phone) makes an **outbound** connection to Tailscale's coordination servers, which help the devices find each other and then establish a direct, encrypted WireGuard tunnel between them (NAT hole-punching). Because it's all outbound-initiated, the building's ONT NAT is irrelevant — outbound traffic was never blocked.

**Bonus properties (why it's arguably *better* than the rejected options, not just a fallback):**
- **More secure by design:** services are never exposed to the open internet. Only your own authenticated devices can reach the Pi. Port-forwarding + DynDNS would have exposed services to the entire internet (bigger attack surface).
- **Encrypted end to end** (WireGuard under the hood — so the same core tech we'd have learned with pure WireGuard).
- **DNS-anywhere:** combined with a Pi-hole nameserver + "override local DNS", the phone gets Pi-hole filtering on any network (with Tailscale on).
- Free for personal use, ~10 min setup.

**The one honest trade-off:** Tailscale's *coordination servers* are a third-party dependency. They can't see your traffic (that's peer-to-peer encrypted), only help devices find each other. To eliminate even that, the future upgrade is **Headscale** (self-hosted coordination server) — but that needs a public VPS, which brings back a version of the "needs a public IP" problem, just solved by renting one. Noted as a future project.

## Conclusion

Tailscale is not a compromise here — given an un-accessible upstream ONT, it is the **only** approach that works, and it happens to also be the **most secure** of the options considered. The alternatives (WireGuard / DynDNS / DD-WRT) all fail for the identical reason: they need inbound access through a device we don't control. This was validated by working through each option explicitly (including input from a CS grad) rather than assumed.
