#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="192.168.178.240"

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@"$MASTER_IP" '
  set +e
  echo "--- cluster-info ---"
  kubectl cluster-info
  echo
  echo "--- get nodes ---"
  kubectl get nodes
  echo
  echo "--- kube-system pods ---"
  kubectl get pods -n kube-system
'
