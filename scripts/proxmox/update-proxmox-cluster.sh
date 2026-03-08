#!/bin/bash
# update-proxmox-cluster.sh
# Update all Proxmox nodes sequentially, validate UEFI boot setup, and reboot safely

set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=accept-new"

# Remote nodes first, local node last
NODES=(
  "192.168.178.12"
  "192.168.178.13"
  "192.168.178.14"
  "192.168.178.11"
)

LOCAL_NODE_IP="192.168.178.11"

wait_for_node() {
  local node="$1"

  echo "Waiting for $node to come back online..."

  while ! ping -c 1 -W 1 "$node" >/dev/null 2>&1; do
    sleep 2
  done

  until ssh $SSH_OPTS -o BatchMode=yes -o ConnectTimeout=5 root@"$node" "echo ok" >/dev/null 2>&1; do
    sleep 2
  done

  echo "$node is reachable again"
}

remote_update() {
  local node="$1"

  echo "====================================="
  echo "Updating node: $node"
  echo "====================================="

  ssh $SSH_OPTS root@"$node" <<'EOF'
set -euo pipefail

find_esp() {
  lsblk -rno PATH,FSTYPE,PARTTYPE | awk '
    tolower($2) == "vfat" && tolower($3) == "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" {
      print $1
      exit
    }
  '
}

echo "[1/6] apt update"
apt update

echo "[2/6] dist-upgrade"
DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y

echo "[3/6] check UEFI boot setup"
if [ -d /sys/firmware/efi ]; then
  echo "UEFI mode detected"

  ESP_DEV="$(find_esp || true)"

  if [ -z "${ESP_DEV:-}" ]; then
    echo "WARNING: No EFI System Partition found via lsblk"
  else
    echo "Detected ESP: $ESP_DEV"

    if ! dpkg -s grub-efi-amd64 >/dev/null 2>&1; then
      echo "Installing grub-efi-amd64"
      DEBIAN_FRONTEND=noninteractive apt install -y grub-efi-amd64
    else
      echo "grub-efi-amd64 already installed"
    fi

    if [ ! -f /etc/kernel/proxmox-boot-uuids ] || ! blkid "$ESP_DEV" | grep -q "$(cat /etc/kernel/proxmox-boot-uuids 2>/dev/null || true)"; then
      echo "Initializing ESP with proxmox-boot-tool"
      proxmox-boot-tool init "$ESP_DEV" grub
    else
      echo "ESP already registered in proxmox-boot-tool"
    fi
  fi
else
  echo "System not booted in UEFI mode"
fi

echo "[4/6] refresh boot entries"
if command -v proxmox-boot-tool >/dev/null 2>&1; then
  proxmox-boot-tool refresh || true
fi

echo "[5/6] boot status"
if command -v proxmox-boot-tool >/dev/null 2>&1; then
  proxmox-boot-tool status || true
fi

echo "[6/6] rebooting node"
nohup bash -c 'sleep 2; reboot' >/dev/null 2>&1 &
EOF

  echo "Node $node rebooting..."
  sleep 10
  wait_for_node "$node"
  echo "Node $node update completed"
  echo
}

local_update_no_reboot() {
  local node="$1"

  echo "====================================="
  echo "Updating LOCAL node: $node"
  echo "====================================="

  find_esp() {
    lsblk -rno PATH,FSTYPE,PARTTYPE | awk '
      tolower($2) == "vfat" && tolower($3) == "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" {
        print $1
        exit
      }
    '
  }

  echo "[1/6] apt update"
  apt update

  echo "[2/6] dist-upgrade"
  DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y

  echo "[3/6] check UEFI boot setup"
  if [ -d /sys/firmware/efi ]; then
    echo "UEFI mode detected"

    ESP_DEV="$(find_esp || true)"

    if [ -z "${ESP_DEV:-}" ]; then
      echo "WARNING: No EFI System Partition found via lsblk"
    else
      echo "Detected ESP: $ESP_DEV"

      if ! dpkg -s grub-efi-amd64 >/dev/null 2>&1; then
        echo "Installing grub-efi-amd64"
        DEBIAN_FRONTEND=noninteractive apt install -y grub-efi-amd64
      else
        echo "grub-efi-amd64 already installed"
      fi

      if [ ! -f /etc/kernel/proxmox-boot-uuids ] || ! blkid "$ESP_DEV" | grep -q "$(cat /etc/kernel/proxmox-boot-uuids 2>/dev/null || true)"; then
        echo "Initializing ESP with proxmox-boot-tool"
        proxmox-boot-tool init "$ESP_DEV" grub
      else
        echo "ESP already registered in proxmox-boot-tool"
      fi
    fi
  else
    echo "System not booted in UEFI mode"
  fi

  echo "[4/6] refresh boot entries"
  if command -v proxmox-boot-tool >/dev/null 2>&1; then
    proxmox-boot-tool refresh || true
  fi

  echo "[5/6] boot status"
  if command -v proxmox-boot-tool >/dev/null 2>&1; then
    proxmox-boot-tool status || true
  fi

  echo "[6/6] local node updated"
  echo
  echo "Local node was updated but not rebooted automatically."
  echo "Reboot it manually when you are ready:"
  echo "  reboot"
  echo
}

for node in "${NODES[@]}"; do
  if [ "$node" = "$LOCAL_NODE_IP" ]; then
    local_update_no_reboot "$node"
  else
    remote_update "$node"
  fi
done

echo "====================================="
echo "Cluster update finished"
echo "====================================="
echo "Remote nodes were updated and rebooted."
echo "The local node was updated but must be rebooted manually."