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
echo "Starting containerd service on nodes"
echo "====================================="

for node in "${NODES[@]}"; do

  echo "---- $node ----"

  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@$node '

    set -e

    echo "[1/3] Restarting containerd..."
    sudo systemctl restart containerd

    echo "[2/3] Enabling containerd at boot..."
    sudo systemctl enable containerd

    echo "[3/3] Checking status..."
    sudo systemctl status containerd --no-pager

  '

  echo
done

echo "====================================="
echo "Done"
echo "====================================="