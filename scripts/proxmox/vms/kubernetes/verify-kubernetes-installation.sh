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
echo "Verifying Kubernetes installation"
echo "====================================="

for node in "${NODES[@]}"; do
  echo "---- $node ----"

  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@"$node" '
    set +e

    echo "[1/5] kubeadm version"
    kubeadm version
    echo

    echo "[2/5] kubelet version"
    kubelet --version
    echo

    echo "[3/5] kubectl client version"
    kubectl version --client
    echo

    echo "[4/5] held packages"
    apt-mark showhold | grep kube || true
    echo

    echo "[5/5] kubelet status"
    sudo systemctl status kubelet --no-pager -l || true
    echo

    echo "Quick state summary:"
    echo -n "kubelet active state: "
    systemctl is-active kubelet || true
    echo -n "kubelet enabled state: "
    systemctl is-enabled kubelet || true
  '

  echo
done

echo "====================================="
echo "Verification complete"
echo "====================================="