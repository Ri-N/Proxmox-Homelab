#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="192.168.178.240"
CALICO_VERSION="v3.27.0"
POD_CIDR="10.244.0.0/16"

echo "====================================="
echo "Deploying Calico CNI"
echo "====================================="

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@"$MASTER_IP" '
  set -euo pipefail

  CALICO_VERSION="'"$CALICO_VERSION"'"
  POD_CIDR="'"$POD_CIDR"'"

  echo "[1/5] Downloading Calico manifest..."
  curl -fsSL -o calico.yaml "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml"

  echo "[2/5] Checking CALICO_IPV4POOL_CIDR..."
  if grep -q "name: CALICO_IPV4POOL_CIDR" calico.yaml; then
    echo "CALICO_IPV4POOL_CIDR entry found"
  else
    echo "ERROR: CALICO_IPV4POOL_CIDR entry not found in calico.yaml"
    exit 1
  fi

  echo "[3/5] Ensuring CALICO_IPV4POOL_CIDR matches ${POD_CIDR}..."
  awk -v cidr="${POD_CIDR}" "
    /name: CALICO_IPV4POOL_CIDR/ {
      print
      getline
      sub(/value: .*/, \"value: \\\"\" cidr \"\\\"\")
      print
      next
    }
    { print }
  " calico.yaml > calico.yaml.tmp

  mv calico.yaml.tmp calico.yaml

  echo
  echo "Resulting CIDR section:"
  grep -A 1 "CALICO_IPV4POOL_CIDR" calico.yaml || true

  echo
  echo "[4/5] Applying Calico manifest..."
  kubectl apply -f calico.yaml

  echo
  echo "[5/5] Checking rollout status..."
  echo "--- kube-system pods ---"
  kubectl get pods -n kube-system
  echo
  echo "--- calico resources ---"
  kubectl get pods -n kube-system | grep calico || true
  echo
  echo "--- nodes ---"
  kubectl get nodes
'

echo
echo "====================================="
echo "Done"
echo "====================================="