#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="192.168.178.240"

echo "====================================="
echo "Verifying Calico"
echo "====================================="

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@"$MASTER_IP" '
  set +e

  echo "--- nodes ---"
  kubectl get nodes
  echo

  echo "--- kube-system pods ---"
  kubectl get pods -n kube-system
  echo

  echo "--- calico pods ---"
  kubectl get pods -n kube-system | grep calico || true
'

echo
echo "====================================="
echo "Verification complete"
echo "====================================="