#!/bin/bash
# Update Pi-hole, Unbound, and OS packages

set -e

echo "=== Updating OS packages ==="
sudo apt update && sudo apt upgrade -y

echo "=== Updating Pi-hole ==="
pihole -up

echo "=== Updating Pi-hole blocklists ==="
pihole -g

echo "=== Updating Unbound ==="
sudo apt install --only-upgrade unbound -y

echo "=== Refreshing root hints ==="
sudo wget -q -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.cache
sudo systemctl restart unbound

echo "=== Done ==="
