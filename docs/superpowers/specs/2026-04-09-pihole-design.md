# Pi-hole + Unbound Headless DNS Server — Design Spec

**Date:** 2026-04-09
**Status:** Approved

---

## Overview

Set up a Raspberry Pi 4 as a headless, network-wide DNS ad blocker using Pi-hole and Unbound. All devices on the home network will have ads, trackers, and malware domains blocked automatically — no per-device configuration required.

---

## Hardware

- Raspberry Pi 4 (Argon case, 128GB SSD)
- OS already installed and updated
- SSH access confirmed

---

## Architecture

```
[ All devices on home network ]
        |
        v
[ Eero Router ] — DHCP tells all devices to use Pi as DNS
        |
        v
[ Raspberry Pi 4 — 192.168.4.22 ]
  ├── Pi-hole (port 53) — blocklist filtering
  └── Unbound (port 5335) — recursive DNS resolver
        |
        v
[ Root DNS servers ] — no third-party DNS provider
```

**DNS query flow:**
1. Device makes a DNS request
2. Eero forwards it to Pi-hole at `192.168.4.22:53`
3. Pi-hole checks against blocklists — blocked queries return `NXDOMAIN`
4. Allowed queries forwarded to Unbound at `127.0.0.1:5335`
5. Unbound resolves recursively from root DNS servers

---

## Static IP

- **Method:** Eero IP reservation (set in Eero app per device MAC address)
- **IP:** `192.168.4.22`
- Pi continues using DHCP but always receives this address from Eero

---

## Pi-hole Configuration

- **Install method:** Official installer script (`curl -sSL https://install.pi-hole.net | bash`)
- **Listen address:** `192.168.4.22`, port 53
- **Upstream DNS:** `127.0.0.1#5335` (Unbound on localhost)
- **Default blocklist:** StevenBlack unified hosts (ads + trackers + malware)
- **Web admin UI:** `http://192.168.4.22/admin` — accessible from any device on the local network
- **Blocklist auto-update:** Weekly via cron (default Pi-hole behavior)

---

## Unbound Configuration

- **Install method:** `sudo apt install unbound`
- **Listen address:** `127.0.0.1`, port 5335 (localhost only — not exposed to network)
- **DNSSEC:** Enabled
- **Root hints:** Downloaded from IANA, kept current
- **Role:** Recursive resolver — queries root DNS servers directly, no upstream provider

---

## Eero Configuration

- **Primary DNS:** `192.168.4.22` (Pi-hole)
- **Fallback DNS:** `1.1.1.1` (Cloudflare — used only if Pi is unreachable)
- **Set via:** Eero app → Network Settings → DNS

The fallback ensures network connectivity is preserved if the Pi goes down. During fallback, blocked domains may resolve — this is acceptable.

---

## Management

| Task | Method |
|------|--------|
| View query logs / stats | `http://192.168.4.22/admin` |
| Update Pi-hole | `pihole -up` (via SSH) |
| Update Unbound | `sudo apt upgrade unbound` (via SSH) |
| Update OS | `sudo apt update && sudo apt upgrade` (via SSH) |
| Refresh blocklists manually | `pihole -g` (via SSH) |
| Whitelist a domain | Web UI or `pihole -w <domain>` |
| Blacklist a domain | Web UI or `pihole --blacklist <domain>` |

---

## Out of Scope

- Pi-hole as DHCP server (Eero handles DHCP)
- Docker-based deployment
- VPN or remote access setup
- High availability / redundant Pi setup
