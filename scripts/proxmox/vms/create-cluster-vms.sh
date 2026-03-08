#!/bin/bash
# create-and-distribute-k3s-vms.sh
# Create VMs from template on pve1, migrate them to target nodes, then start them

set -euo pipefail

TEMPLATE_ID=9000
GATEWAY="192.168.178.1"
NAMESERVER="192.168.178.1"
SEARCH_DOMAIN="home"
SSH_KEY_FILE="/root/.ssh/id_ed25519.pub"

# Proxmox node management IPs
PVE1_IP="192.168.178.11"
PVE2_IP="192.168.178.12"
PVE3_IP="192.168.178.13"
PVE4_IP="192.168.178.14"

# SSH options for first-time connections in homelab
SSH_OPTS="-o StrictHostKeyChecking=accept-new"

create_vm() {
    local vmid="$1"
    local name="$2"
    local ip="$3"
    local memory="$4"
    local cores="$5"
    local disk_increase="$6"

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

    echo "VM $vmid created successfully."
    echo
}

migrate_vm() {
    local vmid="$1"
    local target_node="$2"

    echo "Migrating VM $vmid to $target_node..."
    qm migrate "$vmid" "$target_node" --with-local-disks
    echo "Migration of VM $vmid to $target_node completed."
    echo
}

start_vm_local() {
    local vmid="$1"
    echo "Starting VM $vmid on local node..."
    qm start "$vmid"
}

start_vm_remote() {
    local vmid="$1"
    local target_ip="$2"

    echo "Starting VM $vmid on remote node $target_ip..."
    ssh $SSH_OPTS root@"$target_ip" "qm start $vmid"
}

echo "=== Phase 1: Create all VMs on pve1 ==="
create_vm 240 "k3s-server-01" "192.168.178.240" 2048 2 "+20G"
create_vm 241 "k3s-server-02" "192.168.178.241" 2048 2 "+20G"
create_vm 242 "k3s-server-03" "192.168.178.242" 2048 2 "+20G"
create_vm 243 "k3s-worker-01" "192.168.178.243" 3072 2 "+40G"
create_vm 244 "k3s-worker-02" "192.168.178.244" 3072 2 "+40G"
create_vm 245 "infra-core-01" "192.168.178.245" 2048 1 "+20G"

echo "=== Phase 2: Migrate VMs to target nodes ==="
# stays on pve1: 240, 244
migrate_vm 241 "pve2"
migrate_vm 242 "pve3"
migrate_vm 243 "pve4"
migrate_vm 245 "pve2"

echo "=== Phase 3: Start VMs on their target nodes ==="
# Local VMs on pve1
start_vm_local 240
start_vm_local 244

# Remote VMs
start_vm_remote 241 "$PVE2_IP"
start_vm_remote 245 "$PVE2_IP"
start_vm_remote 242 "$PVE3_IP"
start_vm_remote 243 "$PVE4_IP"

echo
echo "All VMs created, migrated, and started successfully."
echo
echo "Suggested checks:"
echo "  pvesh get /cluster/resources --type vm"
echo "  ping 192.168.178.240"
echo "  ssh ubuntu@192.168.178.240"