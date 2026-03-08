#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="192.168.178.240"

echo "====================================="
echo "Labeling Kubernetes worker nodes"
echo "====================================="

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@"$MASTER_IP" '
  set -e

  for node in k3s-worker-01 k3s-worker-02; do
    echo "Labeling $node"
    kubectl label node "$node" node-role.kubernetes.io/worker=worker --overwrite
  done

  echo
  echo "Current node status:"
  kubectl get nodes
'

echo
echo "====================================="
echo "Done"
echo "====================================="