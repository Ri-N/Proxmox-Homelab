#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="192.168.178.240"

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@"$MASTER_IP" '
  set -e
  mkdir -p "$HOME/.kube"
  sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
  sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"
  chmod 600 "$HOME/.kube/config"
'