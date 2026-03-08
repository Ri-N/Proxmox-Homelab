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
echo "Configuring containerd on all k8s nodes"
echo "====================================="

for node in "${NODES[@]}"; do
  echo "---- $node ----"

  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@"$node" '
    set -e

    echo "[1/5] Creating /etc/containerd ..."
    sudo mkdir -p /etc/containerd

    echo "[2/5] Backing up existing config if present ..."
    if [ -f /etc/containerd/config.toml ]; then
      sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.bak
    fi

    echo "[3/5] Generating default containerd config ..."
    sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null

    echo "[4/5] Enabling SystemdCgroup ..."
    sudo sed -i "s/SystemdCgroup = false/SystemdCgroup = true/" /etc/containerd/config.toml

    echo "[5/5] Restarting and enabling containerd ..."
    sudo systemctl restart containerd
    sudo systemctl enable containerd >/dev/null 2>&1 || true

    echo
    echo "Verification:"
    grep SystemdCgroup /etc/containerd/config.toml || true
    echo
    systemctl is-active containerd
  '

  echo
done

echo "====================================="
echo "Done"
echo "====================================="