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
echo "Configuring kernel modules and sysctl"
echo "====================================="

for node in "${NODES[@]}"; do
  echo "---- $node ----"

  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@"$node" '
    set -e

    echo "[1/4] Writing modules config..."
    cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf >/dev/null
overlay
br_netfilter
EOF

    echo "[2/4] Loading kernel modules..."
    sudo modprobe overlay
    sudo modprobe br_netfilter

    echo "[3/4] Writing sysctl config..."
    cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes.conf >/dev/null
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

    echo "[4/4] Applying sysctl settings..."
    sudo sysctl --system >/dev/null

    echo
    echo "Loaded modules:"
    lsmod | grep -E "overlay|br_netfilter" || true

    echo
    echo "Kernel parameters:"
    sysctl net.ipv4.ip_forward net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables
  '

  echo
done

echo "====================================="
echo "Done"
echo "====================================="