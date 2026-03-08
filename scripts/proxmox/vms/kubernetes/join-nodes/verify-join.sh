#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="192.168.178.240"

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@"$MASTER_IP" '
  set +e
  echo "--- nodes ---"
  kubectl get nodes -o wide
  echo
  echo "--- kube-system pods ---"
  kubectl get pods -n kube-system
'