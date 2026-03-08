#!/bin/bash

NODES=(
192.168.178.101
192.168.178.102
192.168.178.103
192.168.178.104
192.168.178.105
)

for node in "${NODES[@]}"; do
  echo "Configuring $node"

  ssh ubuntu@$node "
    sudo swapoff -a
    sudo sed -i '/ swap / s/^/#/' /etc/fstab
    free -h | grep Swap
  "

done