# Raspberry Pi 4 Homelab
## Pi-hole + Docker — Setup Guide for Eero + Mac
*An educational walkthrough with links to go deeper on every concept*

---

## This is a Fully Headless Project

**You will never connect a monitor, keyboard, or mouse to the Pi.** Not during setup, not ever. Every single step — from first boot through ongoing maintenance — happens either from your Mac's Terminal over SSH, from your browser, or from the Eero app on your phone.

The only physical interaction with the Pi in this entire guide is:
1. Inserting the flashed SD card
2. Plugging in the ethernet cable
3. Plugging in power

That's it. The Pi sits wherever you want to stash it and you never touch it again.

The thing that makes this possible is **Raspberry Pi Imager's pre-configuration** — you bake SSH access, your username, password, and hostname into the SD card *before* first boot. The Pi comes up already configured and immediately reachable over the network.

---

## Before You Start — What You'll Need

- Raspberry Pi 4 (any RAM tier works; 4GB+ preferred)
- A quality microSD card (32GB+ recommended, Samsung or SanDisk)
- An ethernet cable — **wired is strongly preferred over Wi-Fi for a DNS server.** A dropped wireless connection means your whole network loses internet until it reconnects.
- Your Mac (SSH is built in — no extra software needed)
- The **Eero app** on your phone (all Eero config lives in the app, not a web browser)
- **Raspberry Pi Imager** installed on your Mac → [raspberrypi.com/software](https://www.raspberrypi.com/software/)

> ⚠️ **Eero Secure users:** If you subscribe to Eero Secure or Eero Plus, it includes its own DNS filtering and content blocking. Pi-hole and Eero's DNS filtering will work simultaneously, but they filter independently — not a problem, just worth knowing. Pi-hole handles *your* custom blocklists; Eero Secure handles its own.

---

## Part 1 — Concept Check

Before touching a terminal, here's the mental model for what we're building and why we're building it this way.

### Why Containers Instead of VMs?

There are two ways to run isolated software on a computer: **Virtual Machines** and **Containers**.

A **Virtual Machine (VM)** emulates an entire computer in software. It has its own virtual CPU, RAM, and storage, and it boots a completely separate operating system. The software that manages this is called a **hypervisor** (VMware, VirtualBox, Proxmox, etc.). VMs offer strong isolation but are expensive — a Pi 4 with 4–8GB RAM would burn most of its resources just keeping 1–2 VMs alive before you run anything useful in them.

A **Container** takes a lighter approach. It shares the host machine's OS kernel (the core of Linux) but isolates everything above it — the filesystem, processes, network interfaces, and environment. Containers start in seconds, use a fraction of the memory, and a Pi 4 can run 10–15 of them comfortably.

> 📖 [Virtual Machine — Wikipedia](https://en.wikipedia.org/wiki/Virtual_machine) | [OS-level virtualization — Wikipedia](https://en.wikipedia.org/wiki/OS-level_virtualization) | [Linux namespaces (isolation mechanism) — Wikipedia](https://en.wikipedia.org/wiki/Linux_namespaces)

**Docker** is the engine that builds and runs containers on your Pi. **Docker Compose** is a companion tool that lets you define containers in a plain-text YAML file (`docker-compose.yml`) so you can start, stop, and update them with simple one-line commands instead of memorizing lengthy `docker run` flags.

> 📖 [Docker — Wikipedia](https://en.wikipedia.org/wiki/Docker_(software)) | [YAML format — Wikipedia](https://en.wikipedia.org/wiki/YAML) | [Docker Compose docs](https://docs.docker.com/compose/)

### Why Does Pi-hole Need Port 53?

**Port 53** is the universal, standardized port for DNS (Domain Name System) traffic — it's been that way since 1983. Every device on your network is hardcoded to send DNS queries to port 53. When your phone wants to load `instagram.com`, it sends a packet to port 53 on whatever DNS server your Eero's DHCP has told it to use.

If Pi-hole isn't listening on port 53, those queries go nowhere. That's the whole job: intercept DNS queries, check the domain against blocklists, and either respond with "blocked" or forward the query upstream to a real DNS provider like Cloudflare (1.1.1.1) or Google (8.8.8.8).

> 📖 [DNS — Wikipedia](https://en.wikipedia.org/wiki/Domain_Name_System) | [Port 53 — Wikipedia](https://en.wikipedia.org/wiki/Port_(computer_networking))

---

## Part 2 — Initial Pi Setup

Work through these in order. Each step is a dependency for the next.

---

### Step 1 — Flash the SD Card on Your Mac

> 🖥️ **Done on your Mac. Pi not involved yet.**

This step happens entirely on your Mac before the Pi is powered on. Getting this right is what makes the whole project headless — skip any part of it and you'll need a monitor to recover.

Open **Raspberry Pi Imager** and make these selections:

1. **OS:** Raspberry Pi OS Lite (64-bit) — found under *Raspberry Pi OS (other)*. "Lite" means no desktop environment. Since you're running this headless, a desktop wastes RAM and CPU for nothing.

2. **64-bit matters** because Docker images are compiled for specific CPU architectures. The Pi 4 uses an **ARM64** processor. Most modern Docker images support ARM64. Using 32-bit OS would silently limit your container options.

3. **Click the gear icon (⚙️) before writing.** This is the step that makes headless operation possible. Do not skip it.

   Configure all of the following:
   - **Hostname:** `homelab` (or whatever you want — becomes `homelab.local` on your network)
   - **Username and password:** Pick something you'll remember
   - **Enable SSH:** ✓ — this is what lets your Mac talk to the Pi
   - **Configure Wi-Fi:** Leave this blank — you're using ethernet. A DNS server on Wi-Fi is asking for trouble.
   - **Locale/timezone:** Set to your timezone

4. Write the card, eject it, insert it into the Pi, connect ethernet, connect power.

**That's the last time you physically interact with the Pi.** Everything from here is remote.

> 📖 [ARM64 architecture — Wikipedia](https://en.wikipedia.org/wiki/AArch64) | [Headless computer — Wikipedia](https://en.wikipedia.org/wiki/Headless_computer)

---

### Step 2 — SSH into the Pi from Your Mac

> 🖥️ **Done on your Mac. This is your primary interface for everything that follows.**

Give the Pi about 60–90 seconds after powering on to fully boot. Then open **Terminal** on your Mac (`Cmd + Space` → type `Terminal` → Enter) and run:

```bash
ssh amervar@homelab.local
```

Replace `alex` with the username you set in Imager, and `homelab` with the hostname you chose. The `.local` suffix works because your Mac uses **Bonjour** — Apple's implementation of a protocol called mDNS — to find devices on your local network by name, without needing to know their IP address first.

The first time you connect, you'll see:

```
The authenticity of host 'homelab.local' can't be established.
Are you sure you want to continue connecting (yes/no)?
```

Type `yes`. This is SSH verifying the Pi's identity fingerprint — it stores it and won't ask again. If it ever asks again for the same host unexpectedly, that would be a red flag worth investigating.

You're now in a terminal session running on the Pi. Every command you type from here happens on the Pi's Linux OS, not your Mac.

> 💡 **Shortcut for future sessions:** Add this to `~/.ssh/config` on your Mac (create the file if it doesn't exist — `nano ~/.ssh/config`):
> ```
> Host homelab
>     HostName homelab.local
>     User amervar
> ```
> After that, `ssh homelab` is all you need to type.

> 📖 [SSH — Wikipedia](https://en.wikipedia.org/wiki/Secure_Shell) | [mDNS/Bonjour — Wikipedia](https://en.wikipedia.org/wiki/Multicast_DNS)

---

### Step 3 — Lock In a Static IP via Eero DHCP Reservation

> 📱 **Done in the Eero app on your phone.**

A DNS server *must* have a stable IP address. If the Pi's IP changes, every device on your network silently loses internet access until you track down what happened and fix it.

**DHCP** (Dynamic Host Configuration Protocol) is the system your Eero uses to automatically hand out IP addresses to devices when they join your network. By default those assignments can change. A **DHCP reservation** tells your Eero: "whenever this specific device asks for an IP, always give it the same one."

**To set it in the Eero app:**

1. Open the **Eero app** → tap **Devices** (bottom nav)
2. Find your Pi in the list (it'll appear as `homelab` or similar)
3. Tap it → tap **Reserve IP**
4. Eero assigns it the IP it currently has, permanently

Write down that IP — you'll need it throughout the rest of this guide. It'll look like `192.168.x.x` (the exact range depends on your Eero network setup).

> 📖 [DHCP — Wikipedia](https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol) | [MAC address (how Eero identifies the device) — Wikipedia](https://en.wikipedia.org/wiki/MAC_address)

---

### Step 4 — Find Your Network's Values

> 🔒 **Done over SSH from your Mac Terminal.**

Before configuring Docker networking, you need three pieces of info from the Pi. Run these over SSH:

```bash
ip route
```

Look for the line starting with `default via` — that IP is your **gateway** (your Eero's IP, typically `192.168.x.1` or `192.168.4.1`).

The `src` IP on that same line (or on the `proto kernel` line) is your **Pi's IP** — the one Eero just reserved.

Your **subnet** is the Pi's IP with the last number replaced by `0/24`. For example, if your Pi is `192.168.4.100`, your subnet is `192.168.4.0/24`.

```bash
ip a
```

Look for your network interface name — it'll be `eth0` (wired) or `wlan0` (wireless) on most Pi OS builds. Newer builds may use `end0`. You need this for the Docker network command in Step 7.

> 📖 [IP address — Wikipedia](https://en.wikipedia.org/wiki/IP_address) | [Subnetwork — Wikipedia](https://en.wikipedia.org/wiki/Subnetwork) | [Default gateway — Wikipedia](https://en.wikipedia.org/wiki/Default_gateway)

---

### Step 5 — Disable `systemd-resolved`

> 🔒 **Done over SSH from your Mac Terminal.**

This is the step that breaks most people's Pi-hole installs if skipped.

Modern Linux includes a background service called **systemd-resolved** that handles DNS lookups for the OS itself. It binds to **port 53**. Two services cannot own the same port — it's like two people trying to pick up the same phone call. If systemd-resolved is running, Pi-hole can't start, and often fails silently.

Run these commands over SSH:

```bash
# Stop it right now
sudo systemctl stop systemd-resolved

# Prevent it from restarting on reboot
sudo systemctl disable systemd-resolved

# It created a symlink at /etc/resolv.conf — remove it
sudo rm /etc/resolv.conf

# Create a real file in its place pointing at Cloudflare's DNS temporarily
# (the Pi needs to resolve hostnames to install Docker in the next step)
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
```

> 📖 [systemd — Wikipedia](https://en.wikipedia.org/wiki/Systemd) | [/etc/resolv.conf explained — Wikipedia](https://en.wikipedia.org/wiki/Resolv.conf)

---

### Step 6 — Install Docker

> 🔒 **Done over SSH from your Mac Terminal.**

Docker provides an official install script that auto-detects your OS and CPU architecture:

```bash
curl -fsSL https://get.docker.com | sh
```

> 💡 **What's happening here?** `curl` downloads a file from a URL. The flags `-fsSL` mean: fail silently on errors (`-f`), suppress progress output (`-s`), still show errors (`-S`), and follow redirects (`-L`). The `|` character is a **pipe** — it takes the output of `curl` (the installer script) and feeds it directly into `sh` (the shell) to execute. This pattern is common for software installers. You're running code from the internet with elevated privileges, so it's always worth using official URLs only.

Then add your user to the `docker` group so you don't need `sudo` before every Docker command:

```bash
sudo usermod -aG docker $USER
```

**Log out and back in** for the group change to take effect:

```bash
exit
# Then SSH back in from your Mac
ssh amervar@homelab.local
```

> 📖 [curl — Wikipedia](https://en.wikipedia.org/wiki/CURL) | [Unix pipe — Wikipedia](https://en.wikipedia.org/wiki/Pipeline_(Unix)) | [Unix user groups — Wikipedia](https://en.wikipedia.org/wiki/Group_identifier)

---

### Step 7 — Install Docker Compose

> 🔒 **Done over SSH from your Mac Terminal.**

Docker Compose v2 is now a plugin that installs alongside Docker:

```bash
sudo apt install docker-compose-plugin
```

Verify everything is working:

```bash
docker --version
docker compose version
```

---

## Part 3 — Docker Networking for Pi-hole

This section is the most conceptually dense part. Take your time here — once it clicks, everything else makes sense.

### The Default Docker Network Problem

When Docker installs, it creates a virtual network called `docker0`. Containers on this network get private IP addresses in the `172.17.x.x` range — IPs that only exist inside the Pi, not on your real LAN.

To let traffic in from outside, you use **port mapping**: `9000:9000` means "forward traffic arriving at the Pi on port 9000 into the container's port 9000." That's fine for web UIs.

But DNS has a problem with this. Docker uses **NAT** (Network Address Translation) to route traffic between your LAN and the container network. NAT rewrites the source IP of each packet — so from Pi-hole's perspective, every DNS query looks like it came from the Pi itself, not from your phone or laptop. Pi-hole's per-device tracking becomes useless.

> 📖 [Network bridge — Wikipedia](https://en.wikipedia.org/wiki/Network_bridge) | [NAT — Wikipedia](https://en.wikipedia.org/wiki/Network_address_translation)

### The Solution: macvlan Networking

**macvlan** is a Linux kernel feature that creates virtual network interfaces, each with their own MAC address, that appear to your LAN as independent physical devices. Docker uses this to give Pi-hole its own real IP address on your network — completely separate from the Pi's IP.

The result: from your Eero's perspective, there appear to be two devices plugged in — your Pi at `192.168.4.100` and Pi-hole at `192.168.4.2`. DNS queries arrive at Pi-hole's IP with real source addresses preserved. Device-level tracking works correctly.

> ⚠️ **One macvlan quirk:** Due to a kernel limitation, the Pi itself cannot communicate directly with the macvlan IP. In practice this means you'd open Pi-hole's web UI from your Mac, not from the Pi. On a headless server, this is never a real issue.

> 📖 [macvlan — Linux kernel networking](https://www.kernel.org/doc/html/latest/networking/macvlan.html) | [MAC address — Wikipedia](https://en.wikipedia.org/wiki/MAC_address)

### Create the macvlan Network

> 🔒 **Done over SSH from your Mac Terminal.**

Run this on the Pi, substituting your actual values from Step 4:

```bash
docker network create -d macvlan \
  --subnet=192.168.4.0/24 \
  --gateway=192.168.4.1 \
  -o parent=eth0 \
  lan_macvlan
```

Verify it was created: `docker network ls`

---

## Part 4 — Deploy Pi-hole

> 🔒 **Done over SSH from your Mac Terminal. Pi-hole's web UI is then accessed from your Mac's browser.**

Create your project directory structure first:

```bash
mkdir -p ~/homelab/pihole/etc-pihole
mkdir -p ~/homelab/pihole/etc-dnsmasq.d
```

Then create the Compose file:

```bash
nano ~/homelab/pihole/docker-compose.yml
```

> 💡 **nano** is a simple terminal text editor built into Linux. Arrow keys to move, type normally, `Ctrl+O` to save, `Ctrl+X` to exit.

Paste this in, substituting your values:

```yaml
version: "3.9"

services:
  pihole:
    image: pihole/pihole:latest
    # Docker pulls this image from hub.docker.com if it's not cached locally.
    # "latest" always gets the newest release. For a production server you'd
    # pin to a specific version (e.g., "2024.07.0") for predictability.

    container_name: pihole
    hostname: pihole

    networks:
      lan_macvlan:
        ipv4_address: 192.168.4.2
        # Pick an IP in your subnet that Eero won't hand to another device.
        # Low numbers (like .2) are safe since Eero's DHCP pool typically
        # starts at .100 or higher. Verify in the Eero app under Network Settings.

    environment:
      # Environment variables are the standard way to configure Docker containers.
      # They're injected at container start and read by the app inside.
      TZ: "America/Chicago"            # Your timezone — affects log timestamps
      WEBPASSWORD: "changeme"          # Pi-hole admin UI password — change this
      PIHOLE_DNS_: "1.1.1.1;8.8.8.8"  # Upstream DNS: queries that aren't blocked
                                       # get forwarded here. Cloudflare + Google.
      DNSMASQ_LISTENING: "all"         # Accept queries on all network interfaces

    volumes:
      - ./etc-pihole:/etc/pihole
      - ./etc-dnsmasq.d:/etc/dnsmasq.d
      # Left side is a path on the Pi's real disk (relative to this compose file).
      # Right side is the path inside the container.
      # Pi-hole writes all its config and blocklists to /etc/pihole — by mapping
      # that to the Pi's disk, the data survives container deletion and updates.

    restart: unless-stopped
    # Restart behavior:
    #   "no"             → never restart automatically
    #   "always"         → always restart, even after manual stop
    #   "unless-stopped" → restart on crash or reboot, but not if you stopped it manually ← use this
    #   "on-failure"     → only restart on non-zero exit code

    cap_add:
      - NET_ADMIN
      # Linux "capabilities" are fine-grained permission sets — a middle ground
      # between running as a normal user and running as full root. NET_ADMIN
      # grants network admin rights (needed for Pi-hole to manage DNS/DHCP)
      # without giving it unrestricted system access.
      # 📖 https://man7.org/linux/man-pages/man7/capabilities.7.html

networks:
  lan_macvlan:
    external: true
    # "external: true" means this network was created outside this compose file
    # (we created it manually above). Compose won't try to create or delete it.
```

Start it:

```bash
cd ~/homelab/pihole
docker compose up -d
```

Verify it's running: `docker ps`

You should see Pi-hole listed with status `Up`.

---

## Part 5 — Point Your Eero at Pi-hole

> 📱 **Done in the Eero app on your phone.**

This is the final step that makes Pi-hole active for every device on your network.

**In the Eero app:**
1. Tap **Settings** (bottom nav) → **Network Settings** → **DNS**
2. Select **Custom DNS**
3. Enter Pi-hole's IP as the primary DNS server (e.g., `192.168.4.2`)
4. Leave secondary DNS blank, OR enter `1.1.1.1` as a fallback

> 💡 **Why leave secondary blank?** If you add a secondary DNS like `8.8.8.8`, some devices will use it as a fallback and bypass Pi-hole when it's slow. Leaving it blank means all DNS goes through Pi-hole or fails — which you'll notice immediately if Pi-hole goes down. Personal preference call.

After saving, verify it's working by opening Pi-hole's admin UI in your Mac's browser:

```
http://192.168.4.2/admin
```

You should see the dashboard. After a few minutes, the query counter will start ticking up as devices on your network make DNS requests.

**Force your Mac to use the new DNS immediately** (instead of waiting for DHCP renewal):

```bash
# Flush the DNS cache
sudo killall -HUP mDNSResponder

# Turn Wi-Fi off and back on in System Settings, or:
# System Settings → Network → Wi-Fi → Advanced → DNS
# (The Eero change propagates automatically on reconnection)
```

> 📖 [DHCP lease — Wikipedia](https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Operation) | [mDNSResponder — Apple Developer](https://developer.apple.com/bonjour/)

---

## Part 6 — Deploy Portainer (Container Management UI)

> 🔒 **Setup done over SSH. Portainer itself is then managed entirely from your Mac's browser — no more SSH needed for routine tasks.**

Once you have more than 2–3 containers running, SSHing into the Pi just to check logs gets tedious. **Portainer** is a web UI that wraps the Docker API — manage containers, view logs, browse volumes, and deploy Compose stacks from your browser.

```bash
mkdir -p ~/homelab/portainer
nano ~/homelab/portainer/docker-compose.yml
```

```yaml
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    ports:
      - "9000:9000"
      # Standard port mapping — traffic hitting the Pi on 9000
      # gets forwarded into the container's port 9000.
      # This uses the Pi's regular IP (not the macvlan IP).
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      # /var/run/docker.sock is a Unix socket — a special file the Docker
      # daemon uses to receive commands. Mounting it into Portainer lets
      # Portainer send commands to Docker as if it were running on the host.
      # This is how it sees and controls all your other containers.
      #
      # ⚠️ Security note: anything with access to this socket has
      # effective root access to the Pi. Portainer is well-audited,
      # but don't mount this socket into containers you don't trust.
      - portainer_data:/data

    restart: unless-stopped

volumes:
  portainer_data:
  # A "named volume" is managed entirely by Docker (stored in /var/lib/docker/volumes/).
  # Unlike bind mounts, you don't pick the path — Docker does.
  # Use named volumes for app state you don't need to inspect or edit directly.
  # Use bind mounts (like Pi-hole's config) for things you want to back up or edit.
```

```bash
cd ~/homelab/portainer
docker compose up -d
```

Access it from your Mac at: `http://192.168.4.100:9000` (use the Pi's actual IP, not Pi-hole's macvlan IP)

> 📖 [Unix domain socket — Wikipedia](https://en.wikipedia.org/wiki/Unix_domain_socket) | [Portainer docs](https://docs.portainer.io/)

---

## Part 7 — Day-to-Day Operations (All Remote, All Headless)

### SSH from Your Mac

```bash
# Connect to the Pi
ssh amervar@homelab.local

# Or by IP if mDNS isn't resolving
ssh amervar@192.168.4.100
```

> 💡 **Save yourself typing:** Add this to your Mac's `~/.ssh/config` file (create it if it doesn't exist):
> ```
> Host homelab
>     HostName homelab.local
>     User amervar
> ```
> After that, you can just type `ssh homelab`.

### Essential Docker Commands

```bash
# Start containers defined in the current folder's compose file (background)
docker compose up -d

# Stop and remove containers (your data in volumes/bind mounts is safe)
docker compose down

# Update a service to the latest image
docker compose pull && docker compose up -d

# Watch live logs from Pi-hole (Ctrl+C to stop)
docker logs pihole -f

# See all running containers
docker ps

# Get a shell inside a running container (like SSH'ing into it)
docker exec -it pihole bash

# See disk usage by Docker (images, containers, volumes)
docker system df
```

### Updating Pi-hole

```bash
cd ~/homelab/pihole
docker compose pull        # Downloads the latest image
docker compose up -d       # Recreates the container with the new image
```

Your config and blocklists are in the bind-mounted folders (`etc-pihole/`, `etc-dnsmasq.d/`) and are untouched by this process.

### Backing Up

Your entire Pi-hole state lives in two folders:
```
~/homelab/pihole/etc-pihole/
~/homelab/pihole/etc-dnsmasq.d/
```

From your **Mac terminal**, you can pull a copy any time:

```bash
scp -r amervar@homelab.local:~/homelab/pihole/etc-pihole ~/Desktop/pihole-backup
```

> 📖 [scp (secure copy) — Wikipedia](https://en.wikipedia.org/wiki/Secure_copy_protocol)

---

## Part 8 — Directory Structure to Grow Into

Keep this structure as you add more services:

```
~/homelab/
├── pihole/
│   ├── docker-compose.yml
│   ├── etc-pihole/          ← Pi-hole config & blocklists (back this up)
│   └── etc-dnsmasq.d/       ← dnsmasq config
├── portainer/
│   └── docker-compose.yml
├── monitoring/
│   └── docker-compose.yml   ← Grafana + Prometheus later
├── vpn/
│   └── docker-compose.yml   ← WireGuard later
└── ...
```

Each service gets its own folder. You `cd` into that folder and run compose commands. Services are independently managed — restarting Pi-hole won't touch Portainer. Every compose file can be version-controlled with Git, and your data lives right next to the service that owns it.

> 📖 [Git — Wikipedia](https://en.wikipedia.org/wiki/Git)

---

## Part 9 — Troubleshooting

**Pi-hole container won't start**
→ Run `docker logs pihole` and read the error. Most common cause: port 53 is still occupied. Double-check that systemd-resolved is truly off: `sudo systemctl status systemd-resolved`

**Can't reach Pi-hole admin UI**
→ Remember: you can't access the macvlan IP from the Pi itself. Open `http://192.168.4.2/admin` from your Mac's browser, not from within an SSH session.

**Devices still showing old DNS after Eero change**
→ Devices hold their DHCP lease (which includes DNS info) until it expires — up to 24 hours. Force it:
- **Mac:** Turn Wi-Fi off/on, or `sudo killall -HUP mDNSResponder`
- **iPhone:** Toggle Airplane Mode
- **Windows:** `ipconfig /renew` in Command Prompt

**SSH can't find `homelab.local`**
→ mDNS occasionally fails. Use the IP directly: `ssh amervar@192.168.4.100`. You can always find the Pi's IP in the Eero app under Devices.

**Pi-hole is blocking something it shouldn't**
→ In the Pi-hole admin UI, go to **Query Log** to find the blocked domain, then **Whitelist** it. This is normal — popular blocklists occasionally catch legitimate domains.

**Pi is completely unreachable over SSH**
→ This is the one headless gotcha. If the Pi's network config gets corrupted or SSH breaks, you'll need to reflash the SD card — there's no other way in without a monitor. Prevention: don't edit `/etc/ssh/` config files directly, and keep a known-good SD card backup. If this ever happens, reflashing takes 10 minutes and your service data is safe in the `~/homelab/` bind-mount folders (assuming they're on the same card — a separate USB drive for data is a good future upgrade).

---
---

# Homelab Project Ideas

All of these are Docker-ready. Most have a `docker-compose.yml` example in their official docs.

## Networking & Security

| Project | What it does | Learn More |
|---|---|---|
| **[Traefik](https://traefik.io/)** | Reverse proxy with automatic HTTPS. Instead of remembering `192.168.4.100:8096` for Jellyfin, you type `jellyfin.home`. Essential once you have 3+ services. | [Reverse proxy — Wikipedia](https://en.wikipedia.org/wiki/Reverse_proxy) / [TLS/HTTPS — Wikipedia](https://en.wikipedia.org/wiki/HTTPS) |
| **[WireGuard](https://www.wireguard.com/) / [wg-easy](https://github.com/wg-easy/wg-easy)** | Self-hosted VPN. Access your entire home network remotely as if you were on the LAN. `wg-easy` adds a clean web UI. | [WireGuard — Wikipedia](https://en.wikipedia.org/wiki/WireGuard) / [VPN — Wikipedia](https://en.wikipedia.org/wiki/Virtual_private_network) |
| **[Nginx Proxy Manager](https://nginxproxymanager.com/)** | Traefik alternative with a GUI. Manages reverse proxy rules and SSL certificates without config files. Better starting point if you dislike YAML. | [Nginx — Wikipedia](https://en.wikipedia.org/wiki/Nginx) |
| **[Crowdsec](https://www.crowdsec.net/)** | Collaborative IDS/IPS. Detects and bans attack patterns, shares threat intelligence with a global community. Integrates with Traefik. | [Intrusion detection — Wikipedia](https://en.wikipedia.org/wiki/Intrusion_detection_system) |

## Monitoring & Observability

| Project | What it does | Learn More |
|---|---|---|
| **[Grafana](https://grafana.com/) + [Prometheus](https://prometheus.io/)** | The industry standard. Prometheus scrapes metrics from your Pi, Docker containers, and network gear. Grafana turns them into live dashboards. | [Prometheus — Wikipedia](https://en.wikipedia.org/wiki/Prometheus_(software)) / [Time series database — Wikipedia](https://en.wikipedia.org/wiki/Time_series_database) |
| **[Uptime Kuma](https://uptime.kuma.pet/)** | Self-hosted uptime monitor. Pings your services and sends alerts (email, push notification, Slack) when something goes down. | [Uptime monitoring — Wikipedia](https://en.wikipedia.org/wiki/Application_performance_management) |
| **[Glances](https://nicolargo.github.io/glances/)** | Lightweight real-time system dashboard in a browser. CPU, RAM, disk, network — quick alternative to `htop` without SSHing in. | [System monitor — Wikipedia](https://en.wikipedia.org/wiki/System_monitor) |
| **[ntopng](https://www.ntop.org/)** | Deep LAN traffic analysis. Shows exactly which devices are talking to which external IPs and how much bandwidth they're consuming. | [Network traffic analysis — Wikipedia](https://en.wikipedia.org/wiki/Network_traffic_analysis) |

## Media & Files

| Project | What it does | Learn More |
|---|---|---|
| **[Jellyfin](https://jellyfin.org/)** | Fully self-hosted media server — no account, no subscription. Pi 4 handles 1080p direct play and transcoding. 4K needs hardware acceleration config. | [Media server — Wikipedia](https://en.wikipedia.org/wiki/Media_server) |
| **[Nextcloud](https://nextcloud.com/)** | Self-hosted Google Drive + Docs + Calendar. Sync files and contacts across all your devices with no third party involved. | [Nextcloud — Wikipedia](https://en.wikipedia.org/wiki/Nextcloud) |
| **[Immich](https://immich.app/)** | Google Photos replacement. Auto-backup from your iPhone, AI face/object tagging, shared albums. One of the fastest-moving self-hosted projects right now. | [Digital asset management — Wikipedia](https://en.wikipedia.org/wiki/Digital_asset_management) |
| **[Paperless-ngx](https://docs.paperless-ngx.com/)** | Scan documents in → OCR them → full-text searchable archive. Eliminates paper filing forever. | [OCR — Wikipedia](https://en.wikipedia.org/wiki/Optical_character_recognition) |

## Productivity & Dev Tools

| Project | What it does | Learn More |
|---|---|---|
| **[Gitea](https://about.gitea.com/)** | Lightweight self-hosted GitHub. Full Git server, issues, and CI/CD via Gitea Actions. Good for learning Git internals. | [Git — Wikipedia](https://en.wikipedia.org/wiki/Git) / [CI/CD — Wikipedia](https://en.wikipedia.org/wiki/CI/CD) |
| **[Vaultwarden](https://github.com/dani-garcia/vaultwarden)** | Bitwarden-compatible password manager backend. Use official Bitwarden apps (browser extension, iPhone app) pointed at your own server. | [Password manager — Wikipedia](https://en.wikipedia.org/wiki/Password_manager) |
| **[n8n](https://n8n.io/)** | Self-hosted Zapier. Visual node editor to connect APIs, webhooks, email, and services into automated workflows. | [Workflow automation — Wikipedia](https://en.wikipedia.org/wiki/Robotic_process_automation) |
| **[Home Assistant](https://www.home-assistant.io/)** | Home automation platform. Integrates with thousands of devices. Massive community. Excellent Pi documentation and native Apple Home support. | [Home Assistant — Wikipedia](https://en.wikipedia.org/wiki/Home_Assistant) |
| **[Actual Budget](https://actualbudget.org/)** | Self-hosted personal finance app. Zero-based budgeting, local-first — your financial data never leaves your network. | [Zero-based budgeting — Wikipedia](https://en.wikipedia.org/wiki/Zero-based_budgeting) |

## Learning Projects (Great for Skills-Building)

| Project | What it does | Learn More |
|---|---|---|
| **[k3s](https://k3s.io/)** | Lightweight Kubernetes for low-resource hardware. The natural next step after you've outgrown Docker Compose and want to learn real container orchestration. | [Kubernetes — Wikipedia](https://en.wikipedia.org/wiki/Kubernetes) |
| **[Ansible](https://www.ansible.com/)** | Agentless config management. Write YAML "playbooks" that automate setup tasks across multiple machines. Use the Pi as your control node. | [Ansible — Wikipedia](https://en.wikipedia.org/wiki/Ansible_(software)) |
| **[Semaphore](https://semaphoreui.com/)** | Web UI for Ansible. Run and schedule playbooks from a browser without touching the CLI. | [Configuration management — Wikipedia](https://en.wikipedia.org/wiki/Configuration_management) |
| **[Netdata](https://www.netdata.cloud/)** | Deep real-time system monitoring with built-in anomaly detection. Good for building intuition about what "normal" looks like before something breaks. | [Anomaly detection — Wikipedia](https://en.wikipedia.org/wiki/Anomaly_detection) |

---

## Suggested Rollout Order

1. **Pi-hole + Portainer** — Get DNS filtering working and a management UI in place. This is your foundation.
2. **Traefik or Nginx Proxy Manager** — Once you have 2+ services, replace port numbers with clean hostnames.
3. **Uptime Kuma** — Know the moment something goes down.
4. **Grafana + Prometheus** — Understand *why* things went down, and trend capacity over time.
5. **WireGuard** — Access the whole homelab securely from anywhere.
6. **Everything else** — Follow your curiosity from here.

---

## Essential References

| Resource | What it's for |
|---|---|
| [awesome-selfhosted](https://github.com/awesome-selfhosted/awesome-selfhosted) | Comprehensive catalog of self-hostable software — good for discovering what's possible |
| [r/selfhosted](https://www.reddit.com/r/selfhosted/) | Active community for "how does X compare to Y" questions and troubleshooting |
| [LinuxServer.io](https://www.linuxserver.io/) | Maintains high-quality Docker images for many homelab apps — often better documented than official images |
| [Docker Hub](https://hub.docker.com/) | Where Docker pulls images from by default — search here to find any app's official image |
| [Pi-hole docs](https://docs.pi-hole.net/) | Official Pi-hole documentation |
| [Eero community](https://community.eero.com/) | Eero-specific help, including Pi-hole + Eero threads |
