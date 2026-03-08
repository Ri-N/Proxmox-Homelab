#!/bin/bash
# create-k8s-vms.sh
# Create homelab Kubernetes VMs from Proxmox template

set -e

TEMPLATE_ID=9000
GATEWAY="192.168.178.1"
NAMESERVER="192.168.178.1"
SEARCH_DOMAIN="home"
SSH_KEY_FILE="/root/.ssh/id_ed25519.pub"

create_vm() {
    local vmid=$1
    local name=$2
    local ip=$3
    local memory=$4
    local cores=$5
    local disk_increase=$6

    echo "Creating VM $vmid: $name with IP $ip..."

    qm clone "$TEMPLATE_ID" "$vmid" --name "$name" --full

    qm set "$vmid" \
        --memory "$memory" \
        --cores "$cores" \
        --ipconfig0 "ip=${ip}/24,gw=$GATEWAY" \
        --nameserver "$NAMESERVER" \
        --searchdomain "$SEARCH_DOMAIN" \
        --sshkeys "$SSH_KEY_FILE"

    qm resize "$vmid" scsi0 "$disk_increase"

    echo "VM $vmid created successfully!"
    echo
}

# Control plane
create_vm 240 "k3s-server-01" "192.168.178.240" 2048 2 "+20G"
create_vm 241 "k3s-server-02" "192.168.178.241" 2048 2 "+20G"
create_vm 242 "k3s-server-03" "192.168.178.242" 2048 2 "+20G"

# Workers
create_vm 243 "k3s-worker-01" "192.168.178.243" 3072 2 "+40G"
create_vm 244 "k3s-worker-02" "192.168.178.244" 3072 2 "+40G"

# Infra
create_vm 245 "infra-core-01" "192.168.178.245" 2048 1 "+20G"

echo "All VMs created successfully!"
echo
echo "Start all VMs with:"
echo 'for vmid in 240 241 242 243 244 245; do qm start $vmid; done'