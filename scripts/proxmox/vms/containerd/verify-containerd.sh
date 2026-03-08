#!/usr/bin/env bash
set -euo pipefail

NODES=(
192.168.178.240
192.168.178.241
192.168.178.242
192.168.178.243
192.168.178.244
)

echo "====================================="
echo "Verifying containerd on all nodes"
echo "====================================="

for node in "${NODES[@]}"; do

  echo "---- $node ----"

  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@$node '

    echo
    echo "[1/3] containerd service status"
    systemctl is-active containerd || true

    echo
    echo "[2/3] containerd images"
    sudo ctr images ls || true

    echo
    echo "[3/3] containerd version"
    sudo ctr version || true

  '

  echo
done

echo "====================================="
echo "Verification complete"
echo "====================================="