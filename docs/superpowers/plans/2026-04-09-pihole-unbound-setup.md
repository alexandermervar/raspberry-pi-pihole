# Pi-hole + Unbound Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set up Pi-hole with Unbound as a recursive DNS resolver on a Raspberry Pi 4 for network-wide ad blocking.

**Architecture:** Unbound is installed first as a recursive DNS resolver on localhost:5335, then Pi-hole is installed pointing to Unbound as its upstream. Eero is configured to send all DNS traffic to the Pi, with 1.1.1.1 as a fallback.

**Tech Stack:** Raspberry Pi OS, Pi-hole, Unbound, lighttpd (Pi-hole web UI), dnsmasq (Pi-hole DNS)

---

## Task 1: Pre-flight checks

**Files:** None — verification only

- [ ] **Step 1: Verify you are connected via SSH to the Pi**

```bash
hostname && hostname -I
```

Expected output: hostname of your Pi and `192.168.4.22` in the list of IPs.

- [ ] **Step 2: Confirm the network interface name**

```bash
ip addr show | grep -E "^[0-9]+:" | awk '{print $2}'
```

Expected output includes `eth0:` (wired Ethernet). If you see a different name (e.g. `enp3s0`), note it — you'll need it in Task 3.

- [ ] **Step 3: Confirm disk space**

```bash
df -h /
```

Expected: At least 2GB free. A fresh Pi OS on 128GB SSD will have plenty.

- [ ] **Step 4: Check if port 53 is already in use**

```bash
sudo ss -tulpn | grep :53
```

Expected: Either no output, or output showing `systemd-resolved` bound only to `127.0.0.53` (not `0.0.0.0:53`). If something is bound to `0.0.0.0:53`, see the note below.

> **Note:** If `systemd-resolved` is bound to `0.0.0.0:53`, disable it:
> ```bash
> sudo systemctl disable systemd-resolved
> sudo systemctl stop systemd-resolved
> sudo rm /etc/resolv.conf
> echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
> ```

- [ ] **Step 5: Update package lists**

```bash
sudo apt update
```

Expected: Package lists updated, no errors.

---

## Task 2: Install Unbound

**Files:**
- Install: `/usr/sbin/unbound` (installed by apt)

- [ ] **Step 1: Install Unbound**

```bash
sudo apt install unbound -y
```

Expected: Unbound installs successfully. You may see a warning that Unbound failed to start — this is normal because the config doesn't exist yet.

- [ ] **Step 2: Verify Unbound is installed**

```bash
unbound --version
```

Expected output starts with: `Version 1.x.x` (any version is fine)

---

## Task 3: Configure Unbound

**Files:**
- Create: `/etc/unbound/unbound.conf.d/pi-hole.conf`

- [ ] **Step 1: Create the Unbound config file for Pi-hole**

```bash
sudo tee /etc/unbound/unbound.conf.d/pi-hole.conf > /dev/null << 'EOF'
server:
    verbosity: 0

    interface: 127.0.0.1
    port: 5335
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    do-ip6: no
    prefer-ip6: no

    root-hints: "/var/lib/unbound/root.hints"

    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: no
    edns-buffer-size: 1232
    prefetch: yes
    num-threads: 1
    so-rcvbuf: 1m

    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
    private-address: fd00::/8
    private-address: fe80::/16
EOF
```

Expected: No output (silent success from tee).

- [ ] **Step 2: Verify the file was created correctly**

```bash
cat /etc/unbound/unbound.conf.d/pi-hole.conf
```

Expected: The full config block printed to terminal.

---

## Task 4: Download root hints

**Files:**
- Create: `/var/lib/unbound/root.hints`

- [ ] **Step 1: Download the root hints file from IANA**

```bash
sudo wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.cache
```

Expected output ends with something like:
```
'/var/lib/unbound/root.hints' saved [XXXX/XXXX]
```

- [ ] **Step 2: Verify the file exists and has content**

```bash
wc -l /var/lib/unbound/root.hints
```

Expected: A number greater than 100 (the file has many lines of DNS root server records).

---

## Task 5: Start and enable Unbound

- [ ] **Step 1: Restart Unbound to pick up the new config**

```bash
sudo systemctl restart unbound
```

Expected: No output (silent success). If there's an error, run `sudo systemctl status unbound` to see what went wrong.

- [ ] **Step 2: Enable Unbound to start on boot**

```bash
sudo systemctl enable unbound
```

Expected: `Synchronizing state of unbound.service...` or similar confirmation.

- [ ] **Step 3: Verify Unbound is running**

```bash
sudo systemctl status unbound
```

Expected: `Active: active (running)` in the output.

---

## Task 6: Verify Unbound resolves DNS correctly

- [ ] **Step 1: Install dig (DNS lookup tool)**

```bash
sudo apt install dnsutils -y
```

Expected: Installs successfully (or "already installed").

- [ ] **Step 2: Test Unbound resolves a real domain**

```bash
dig pi-hole.net @127.0.0.1 -p 5335
```

Expected: Output includes a `ANSWER SECTION` with an IP address for pi-hole.net and `status: NOERROR`. The first query may take a moment — Unbound is walking the DNS tree. Subsequent queries will be faster.

- [ ] **Step 3: Test DNSSEC validation is working**

```bash
dig sigfail.verteiltesysteme.net @127.0.0.1 -p 5335
```

Expected: `status: SERVFAIL` — this domain intentionally has broken DNSSEC, so Unbound should refuse to resolve it. This confirms DNSSEC validation is active.

- [ ] **Step 4: Test a known-good DNSSEC domain**

```bash
dig sigok.verteiltesysteme.net @127.0.0.1 -p 5335
```

Expected: `status: NOERROR` with an answer — this confirms DNSSEC-valid domains still resolve correctly.

---

## Task 7: Install Pi-hole (unattended)

**Files:**
- Create: `/etc/pihole/setupVars.conf`

- [ ] **Step 1: Create the Pi-hole config directory**

```bash
sudo mkdir -p /etc/pihole
```

Expected: No output.

- [ ] **Step 2: Create the unattended setup configuration**

> **Note:** If your network interface is not `eth0` (check Task 1 Step 2), replace `eth0` below with the correct interface name.

```bash
sudo tee /etc/pihole/setupVars.conf > /dev/null << 'EOF'
PIHOLE_INTERFACE=eth0
IPV4_ADDRESS=192.168.4.22/24
IPV6_ADDRESS=
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=true
CACHE_SIZE=10000
DNS_FQDN_REQUIRED=false
DNS_BOGUS_PRIV=true
DNSMASQ_LISTENING=single
WEBPASSWORD=
BLOCKING_ENABLED=true
DNSSEC=false
PIHOLE_DNS_1=127.0.0.1#5335
PIHOLE_DNS_2=
EOF
```

Expected: No output.

- [ ] **Step 3: Download and run the Pi-hole installer**

```bash
curl -sSL https://install.pi-hole.net | sudo bash /dev/stdin --unattended
```

Expected: Installer runs silently (no interactive prompts), prints progress lines, and ends with:
```
  [✓] FTL Checks

  [i] The install log is located at: /etc/pihole/install.log
```
This takes 2-5 minutes.

- [ ] **Step 4: Verify Pi-hole service is running**

```bash
pihole status
```

Expected:
```
  [✓] FTL is listening on port 53
  [✓] Pi-hole blocking is enabled
```

---

## Task 8: Set Pi-hole admin password

- [ ] **Step 1: Set a password for the web admin UI**

```bash
pihole -a -p
```

Expected: Prompted to enter and confirm a new password. Choose something memorable — you'll use this to log into `http://192.168.4.22/admin`.

- [ ] **Step 2: Verify the web UI is reachable**

From your Mac (not the Pi), open a browser and navigate to:
```
http://192.168.4.22/admin
```

Expected: Pi-hole login page loads. Log in with the password you just set.

---

## Task 9: Verify Pi-hole is using Unbound as upstream

- [ ] **Step 1: Check Pi-hole's configured DNS server**

```bash
cat /etc/pihole/setupVars.conf | grep PIHOLE_DNS
```

Expected:
```
PIHOLE_DNS_1=127.0.0.1#5335
PIHOLE_DNS_2=
```

- [ ] **Step 2: Test Pi-hole resolves via Unbound**

```bash
dig google.com @127.0.0.1
```

Expected: `status: NOERROR` with an answer section containing Google's IP addresses. This query goes through Pi-hole (port 53) → Unbound (port 5335) → root DNS servers.

- [ ] **Step 3: Test Pi-hole blocks an ad domain**

```bash
dig doubleclick.net @127.0.0.1
```

Expected: `status: NOERROR` but the answer returns `0.0.0.0` — Pi-hole blocked the domain.

---

## Task 10: Update blocklists and run gravity

- [ ] **Step 1: Run gravity to download and compile blocklists**

```bash
pihole -g
```

Expected: Progress output downloading and processing blocklists, ending with:
```
  [✓] DNS service is running
  [✓] Pi-hole blocking is enabled
```
This takes 1-3 minutes.

- [ ] **Step 2: Check how many domains are blocked**

```bash
pihole -c -j | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"Blocking {d['domains_being_blocked']:,} domains\")"
```

Expected output: `Blocking XXX,XXX domains` (typically 100,000–200,000 with the default list).

---

## Task 11: Configure Eero DNS

These steps are done in the **Eero app on your phone**, not via SSH.

- [ ] **Step 1: Open the Eero app**

Tap **Network** in the bottom navigation bar.

- [ ] **Step 2: Navigate to DNS settings**

Tap **Network Settings** → **Advanced Settings** → **DNS**.

- [ ] **Step 3: Set custom DNS servers**

- Set **Primary DNS** to: `192.168.4.22`
- Set **Secondary DNS** to: `1.1.1.1`

Save/confirm the change. Eero may briefly disconnect to apply.

- [ ] **Step 4: Verify Eero is using Pi-hole**

From your phone (on WiFi, not cellular), open a browser and navigate to:
```
http://192.168.4.22/admin
```

Expected: Pi-hole admin page loads. This confirms your phone is routing DNS through the Pi.

---

## Task 12: End-to-end verification

- [ ] **Step 1: Verify a normal domain resolves from a client device**

From your Mac terminal (not SSH'd into the Pi):
```bash
dig google.com
```

Expected: `status: NOERROR` with Google's IP in the answer. The `SERVER:` line at the bottom should show `192.168.4.22#53`.

- [ ] **Step 2: Verify ad blocking works from a client device**

```bash
dig doubleclick.net
```

Expected: Returns `0.0.0.0` — blocked by Pi-hole.

- [ ] **Step 3: Check the Pi-hole query log**

In the Pi-hole admin UI at `http://192.168.4.22/admin`, go to **Query Log**. You should see recent DNS queries from your devices appearing in real-time.

- [ ] **Step 4: Verify the Pi-hole dashboard shows client activity**

Go to the Pi-hole admin **Dashboard**. You should see:
- Total queries increasing as devices browse
- Queries blocked percentage (expect 10–30% typically)
- Multiple clients listed

---

## Task 13: Deploy update script and commit reference configs

**Files:**
- The reference configs are already in this repo under `config/`
- The update script is in `scripts/update.sh`

- [ ] **Step 1: Copy the update script to the Pi**

From your Mac (replace `pi@192.168.4.22` with your actual Pi username if different):
```bash
scp scripts/update.sh pi@192.168.4.22:~/update.sh
```

Expected: File copies to the Pi's home directory.

- [ ] **Step 2: Make the script executable on the Pi**

Via SSH on the Pi:
```bash
chmod +x ~/update.sh
```

- [ ] **Step 3: Run the update script once to verify it works**

```bash
~/update.sh
```

Expected: Each section prints its header and completes without errors.

---

## Troubleshooting Reference

| Problem | Command | Fix |
|---------|---------|-----|
| Pi-hole not blocking | `pihole status` | `pihole restartdns` |
| Unbound not running | `sudo systemctl status unbound` | `sudo systemctl restart unbound` |
| Can't reach web UI | `sudo systemctl status lighttpd` | `sudo systemctl restart lighttpd` |
| DNS not resolving | `dig google.com @192.168.4.22` | Check Unbound: `dig google.com @127.0.0.1 -p 5335` |
| Blocked domain you want | `pihole -w <domain>` | Whitelists the domain |
| Want to see top blocked | `pihole -c` | Shows live stats in terminal |
