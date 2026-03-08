#!/bin/bash
# fix-proxmox-repos-all-nodes.sh
# Disable enterprise repos and ensure no-subscription repo is configured on all Proxmox nodes

set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=accept-new"

NODES=(
  "192.168.178.11"
  "192.168.178.12"
  "192.168.178.13"
  "192.168.178.14"
)

for node in "${NODES[@]}"; do
  echo "=========================================="
  echo "Processing node: $node"
  echo "=========================================="

  ssh $SSH_OPTS root@"$node" 'bash -s' <<'REMOTE_SCRIPT'
set -euo pipefail

CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME:-bookworm}")"

normalize_and_disable_sources_file() {
  local file="$1"
  [ -f "$file" ] || return 0

  awk '
    BEGIN {
      enabled_seen = 0
      stanza_has_content = 0
    }

    /^[[:space:]]*$/ {
      if (stanza_has_content == 1) {
        if (enabled_seen == 0) {
          print "Enabled: no"
        }
        print ""
      }
      enabled_seen = 0
      stanza_has_content = 0
      next
    }

    /^Enabled:/ {
      if (enabled_seen == 0) {
        print "Enabled: no"
        enabled_seen = 1
        stanza_has_content = 1
      }
      next
    }

    {
      print
      stanza_has_content = 1
    }

    END {
      if (stanza_has_content == 1 && enabled_seen == 0) {
        print "Enabled: no"
      }
    }
  ' "$file" > "${file}.tmp"

  mv "${file}.tmp" "$file"
}

echo "[1/6] Detect Debian codename..."
echo "Detected codename: $CODENAME"

echo "[2/6] Disable enterprise repos..."
normalize_and_disable_sources_file /etc/apt/sources.list.d/pve-enterprise.sources
normalize_and_disable_sources_file /etc/apt/sources.list.d/ceph.sources

if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
  sed -i 's/^[[:space:]]*deb/# deb/' /etc/apt/sources.list.d/pve-enterprise.list
fi

if [ -f /etc/apt/sources.list.d/ceph.list ]; then
  sed -i '/enterprise\.proxmox\.com/s/^[[:space:]]*deb/# deb/' /etc/apt/sources.list.d/ceph.list
fi

echo "[3/6] Remove duplicate no-subscription list if proxmox.sources already exists..."
if [ -f /etc/apt/sources.list.d/proxmox.sources ]; then
  rm -f /etc/apt/sources.list.d/pve-no-subscription.list
fi

echo "[4/6] Ensure no-subscription repo exists if proxmox.sources is missing..."
if [ ! -f /etc/apt/sources.list.d/proxmox.sources ]; then
  cat > /etc/apt/sources.list.d/pve-no-subscription.list <<EOF
deb http://download.proxmox.com/debian/pve ${CODENAME} pve-no-subscription
EOF
fi

echo "[5/6] Show relevant repo files..."
for f in \
  /etc/apt/sources.list \
  /etc/apt/sources.list.d/proxmox.sources \
  /etc/apt/sources.list.d/pve-enterprise.sources \
  /etc/apt/sources.list.d/pve-enterprise.list \
  /etc/apt/sources.list.d/pve-no-subscription.list \
  /etc/apt/sources.list.d/ceph.sources \
  /etc/apt/sources.list.d/ceph.list
do
  if [ -f "$f" ]; then
    echo "--- $f ---"
    cat "$f"
    echo
  fi
done

echo "[6/6] Run apt update..."
apt-get update

echo "Done on $(hostname)"
REMOTE_SCRIPT

  echo
done

echo "All nodes processed successfully."