#!/usr/bin/env bash
set -euo pipefail

NODES=(
  192.168.178.240
  192.168.178.241
  192.168.178.242
  192.168.178.243
  192.168.178.244
)

K8S_VERSION="1.29.15-1.1"
K8S_REPO="deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /"

echo "====================================="
echo "Installing Kubernetes packages"
echo "====================================="

for node in "${NODES[@]}"; do
  echo "---- $node ----"

  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ubuntu@"$node" '
    set -euo pipefail

    K8S_VERSION="'"$K8S_VERSION"'"
    K8S_REPO='"'"$K8S_REPO"'"'

    echo "[1/7] Installing required packages..."
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl gpg

    echo "[2/7] Creating keyrings directory..."
    sudo mkdir -p -m 755 /etc/apt/keyrings

    echo "[3/7] Downloading Kubernetes GPG key..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
      | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    echo "[4/7] Adding Kubernetes repository..."
    echo "$K8S_REPO" | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

    echo "[5/7] Updating package index..."
    sudo apt update

    echo "[6/7] Installing kubelet, kubeadm, kubectl..."
    sudo apt install -y \
      kubelet="$K8S_VERSION" \
      kubeadm="$K8S_VERSION" \
      kubectl="$K8S_VERSION"

    echo "[7/7] Holding package versions..."
    sudo apt-mark hold kubelet kubeadm kubectl >/dev/null

    echo
    echo "Installed versions:"
    kubelet --version || true
    kubeadm version -o short || true
    kubectl version --client=true --output=yaml 2>/dev/null | grep gitVersion || true
    echo
    echo "Held packages:"
    apt-mark showhold | grep -E "kubelet|kubeadm|kubectl" || true
  '

  echo
done

echo "====================================="
echo "Done"
echo "====================================="