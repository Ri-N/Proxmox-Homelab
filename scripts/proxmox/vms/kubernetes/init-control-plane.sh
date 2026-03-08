#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="192.168.178.240"
NODE_NAME="k3s-server-01"
POD_CIDR="10.244.0.0/16"

echo "====================================="
echo "Initializing Kubernetes Control Plane"
echo "====================================="

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@$MASTER_IP '

set -e

echo
echo "[1/3] Running kubeadm preflight checks..."
sudo kubeadm init phase preflight

echo
echo "[2/3] Initializing control plane..."

sudo kubeadm init \
  --pod-network-cidr='"$POD_CIDR"' \
  --apiserver-advertise-address='"$MASTER_IP"' \
  --node-name='"$NODE_NAME"'

echo
echo "[3/3] Configuring kubectl access..."

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo
echo "kubectl configured for user"
echo
kubectl get nodes

echo
echo "====================================="
echo "Control plane initialization complete"
echo "====================================="
echo
echo "IMPORTANT:"
echo "Save the join command printed above."
echo "You will need it for worker nodes."
'

echo
echo "====================================="
echo "Done"
echo "====================================="