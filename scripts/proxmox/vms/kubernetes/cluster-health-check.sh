#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="192.168.178.240"

echo "====================================="
echo "Kubernetes Cluster Health Check"
echo "====================================="

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@"$MASTER_IP" '
  set +e

  echo
  echo "=============================="
  echo "[1/6] Cluster info"
  echo "=============================="
  kubectl cluster-info
  echo

  echo "=============================="
  echo "[2/6] Nodes"
  echo "=============================="
  kubectl get nodes -o wide
  echo

  echo "=============================="
  echo "[3/6] All pods"
  echo "=============================="
  kubectl get pods -A
  echo

  echo "=============================="
  echo "[4/6] Control plane and CoreDNS"
  echo "=============================="
  kubectl get pods -n kube-system -o wide | grep -E "etcd-|kube-apiserver-|kube-controller-manager-|kube-scheduler-|coredns|kube-proxy|calico" || true
  echo

  echo "=============================="
  echo "[5/6] DNS test"
  echo "=============================="
  kubectl run test-dns \
    --image=busybox:1.36 \
    --rm -i --restart=Never \
    -- nslookup kubernetes.default.svc.cluster.local
  echo

  echo "=============================="
  echo "[6/6] Calico status"
  echo "=============================="
  kubectl get pods -n kube-system -l k8s-app=calico-node -o wide
  echo

  echo "=============================="
  echo "Summary"
  echo "=============================="

  NODE_COUNT=$(kubectl get nodes --no-headers | wc -l | tr -d " ")
  READY_NODES=$(kubectl get nodes --no-headers | grep -c " Ready " || true)
  BAD_PODS=$(kubectl get pods -A --no-headers | awk '"'"'$4 != "Running" && $4 != "Completed" {print}'"'"')

  echo "Nodes total : $NODE_COUNT"
  echo "Nodes ready : $READY_NODES"

  if [ "$NODE_COUNT" = "$READY_NODES" ]; then
    echo "Nodes       : OK"
  else
    echo "Nodes       : WARNING"
  fi

  if [ -z "$BAD_PODS" ]; then
    echo "Pods        : OK"
  else
    echo "Pods        : WARNING"
    echo "$BAD_PODS"
  fi
'

echo
echo "====================================="
echo "Health check complete"
echo "====================================="