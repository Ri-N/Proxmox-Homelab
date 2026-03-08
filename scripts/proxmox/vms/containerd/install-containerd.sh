#!/bin/bash

NODES=(
192.168.178.240
192.168.178.241
192.168.178.242
192.168.178.243
192.168.178.244
)

echo "====================================="
echo "Installing containerd on all k8s nodes"
echo "====================================="

for node in "${NODES[@]}"; do

  echo "---- $node ----"

  ssh ubuntu@$node "

    sudo apt update
    sudo apt install -y containerd

    sudo mkdir -p /etc/containerd

    sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

    sudo systemctl restart containerd
    sudo systemctl enable containerd

    echo 'containerd version:'
    containerd --version

  "

  echo
done

echo "====================================="
echo "Done"
echo "====================================="