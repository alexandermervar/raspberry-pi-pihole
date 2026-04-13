# Hal — Raspberry Pi 4 Homelab

A fully headless Raspberry Pi 4 homelab running Docker. This repo documents the setup and serves as a reference for ongoing configuration and expansion.

## What's Running

| Service | Purpose | Access |
|---------|---------|--------|
| **Pi-hole** | Network-wide DNS ad blocking (macvlan, static IP) | `http://<pi-hole-ip>/admin` |
| **Portainer** | Docker container management UI | `http://<pi-ip>:9000` |

## Repo Contents

- [`pi-homelab-setup.md`](pi-homelab-setup.md) — Full headless setup guide: SD card flashing, SSH, static IP via Eero DHCP reservation, Docker + Docker Compose, Pi-hole with macvlan networking, Portainer, and a project idea catalog
- [`hal-verification.html`](hal-verification.html) — Local verification page for testing the homelab UI layer
- [`docs/superpowers/`](docs/superpowers/) — Design specs and implementation plans for homelab features

## Hardware

- Raspberry Pi 4 (4GB+ RAM recommended)
- MicroSD card (32GB+, Samsung or SanDisk)
- Ethernet — wired only, no Wi-Fi for a DNS server
- Eero router (DHCP reservation configured for the Pi)

## Key Concepts

- All management is **headless** — SSH from Mac, browser UIs, Eero app
- Services run in **Docker containers** managed with Docker Compose
- Pi-hole uses **macvlan networking** so it gets its own LAN IP and can track per-device DNS queries
- Each service lives in its own folder under `~/homelab/` on the Pi with bind-mounted volumes for data persistence

## Planned Additions

See the project ideas table in [`pi-homelab-setup.md`](pi-homelab-setup.md) — includes Traefik/NPM, WireGuard, Grafana+Prometheus, Uptime Kuma, Immich, and more.

For public-facing hosting (blog, podcast), see the companion guide: *Running Your Podcast and Blog on Hal* (available in Readwise).
