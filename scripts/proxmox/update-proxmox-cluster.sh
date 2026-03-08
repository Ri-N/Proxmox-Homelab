#!/bin/bash
# update-proxmox-cluster.sh
# Update all Proxmox nodes sequentially

set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=accept-new"

NODES=(
  "192.168.178.11"
  "192.168.178.12"
  "192.168.178.13"
  "192.168.178.14"
)

wait_for_node() {
  local node="$1"

  echo "Waiting for $node to come back online..."

  while ! ping -c 1 -W 1 "$node" >/dev/null 2>&1; do
    sleep 2
  done

  echo "$node is reachable again"
}

for node in "${NODES[@]}"; do

  echo "====================================="
  echo "Updating node: $node"
  echo "====================================="

  ssh $SSH_OPTS root@"$node" <<'EOF'
set -e

echo "[1/4] apt update"
apt update

echo "[2/4] dist-upgrade"
DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y

echo "[3/4] refresh EFI boot entries"
if command -v pve-efiboot-tool >/dev/null 2>&1; then
  pve-efiboot-tool refresh || true
fi

echo "[4/4] rebooting node"
reboot
EOF

  echo "Node $node rebooting..."
  sleep 10

  wait_for_node "$node"

  echo "Node $node update completed"
  echo

done

echo "====================================="
echo "All Proxmox nodes updated"
echo "====================================="