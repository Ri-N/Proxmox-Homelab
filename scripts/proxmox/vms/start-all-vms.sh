#!/bin/bash
# start-all-vms.sh
# Start all homelab VMs across the Proxmox cluster

set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=accept-new"

echo "====================================="
echo "Starting all homelab VMs"
echo "====================================="

start_local_vm() {
  local vmid=$1
  local name=$2

  echo "Starting $name (VMID $vmid) on local node..."

  if qm status "$vmid" | grep -q running; then
    echo "Already running"
  else
    qm start "$vmid"
  fi

  echo
}

start_remote_vm() {
  local node=$1
  local vmid=$2
  local name=$3

  echo "Starting $name (VMID $vmid) on node $node..."

  ssh $SSH_OPTS root@"$node" "
    if qm status $vmid | grep -q running; then
      echo 'Already running'
    else
      qm start $vmid
    fi
  "

  echo
}

# ---------------------------
# Local node (pve1)
# ---------------------------

start_local_vm 240 "k3s-server-01"
start_local_vm 244 "k3s-worker-02"

# ---------------------------
# pve2
# ---------------------------

start_remote_vm "192.168.178.12" 241 "k3s-server-02"
start_remote_vm "192.168.178.12" 245 "infra-core-01"

# ---------------------------
# pve3
# ---------------------------

start_remote_vm "192.168.178.13" 242 "k3s-server-03"

# ---------------------------
# pve4
# ---------------------------

start_remote_vm "192.168.178.14" 243 "k3s-worker-01"

echo "====================================="
echo "All VMs processed"
echo "====================================="