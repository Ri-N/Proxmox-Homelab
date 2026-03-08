#!/usr/bin/env bash
set -euo pipefail

API_SERVER="192.168.178.240:6443"
WORKERS=(
  192.168.178.243
  192.168.178.244
)

usage() {
  echo "Usage:"
  echo "  $0 <token> <discovery-token-ca-cert-hash>"
  echo
  echo "Example:"
  echo "  $0 abcdef.0123456789abcdef sha256:1234567890abcdef..."
  exit 1
}

if [[ $# -ne 2 ]]; then
  usage
fi

TOKEN="$1"
CA_HASH="$2"

echo "====================================="
echo "Joining Kubernetes worker nodes"
echo "====================================="
echo "API server: $API_SERVER"
echo

for node in "${WORKERS[@]}"; do
  echo "---- $node ----"

  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@"$node" "
    set -e

    echo '[1/2] Resetting old kubeadm state if present...'
    sudo kubeadm reset -f >/dev/null 2>&1 || true

    echo '[2/2] Joining cluster...'
    sudo kubeadm join $API_SERVER \
      --token $TOKEN \
      --discovery-token-ca-cert-hash $CA_HASH
  "

  echo
done

echo "====================================="
echo "Worker join complete"
echo "====================================="
echo
echo "Now verify on the control plane:"
echo "  ssh ubuntu@192.168.178.240 'kubectl get nodes -o wide'"