#!/bin/bash
# snapshot-all-vms.sh
# Create snapshots for all homelab VMs on their respective Proxmox nodes

set -euo pipefail

SNAPSHOT_NAME="${1:-manual-snapshot-$(date +%Y%m%d-%H%M)}"
DESCRIPTION="${2:-Manual snapshot taken on $(date)}"

SSH_OPTS="-o StrictHostKeyChecking=accept-new"

# Proxmox node IPs
PVE2_IP="192.168.178.12"
PVE3_IP="192.168.178.13"
PVE4_IP="192.168.178.14"

echo "====================================="
echo "Creating Snapshots for All Homelab VMs"
echo "====================================="
echo "Snapshot Name: $SNAPSHOT_NAME"
echo "Description  : $DESCRIPTION"
echo

snapshot_local() {
    local vmid="$1"
    echo "Creating snapshot '$SNAPSHOT_NAME' for VM $vmid on local node..."
    qm snapshot "$vmid" "$SNAPSHOT_NAME" --description "$DESCRIPTION"
    echo "✓ Snapshot created for VM $vmid"
    echo
}

snapshot_remote() {
    local vmid="$1"
    local target_ip="$2"
    echo "Creating snapshot '$SNAPSHOT_NAME' for VM $vmid on remote node $target_ip..."
    ssh $SSH_OPTS root@"$target_ip" \
        "qm snapshot $vmid \"$SNAPSHOT_NAME\" --description \"$DESCRIPTION\""
    echo "✓ Snapshot created for VM $vmid"
    echo
}

# Local on pve1
snapshot_local 240
snapshot_local 244

# Remote on pve2
snapshot_remote 241 "$PVE2_IP"
snapshot_remote 245 "$PVE2_IP"

# Remote on pve3
snapshot_remote 242 "$PVE3_IP"

# Remote on pve4
snapshot_remote 243 "$PVE4_IP"

echo "====================================="
echo "✓ All snapshots created successfully!"
echo "====================================="
echo
echo "List snapshots:"
echo "  qm listsnapshot 240"
echo "  ssh root@$PVE2_IP \"qm listsnapshot 241\""
echo "  ssh root@$PVE3_IP \"qm listsnapshot 242\""
echo "  ssh root@$PVE4_IP \"qm listsnapshot 243\""
echo "  qm listsnapshot 244"
echo "  ssh root@$PVE2_IP \"qm listsnapshot 245\""
echo
echo "Rollback example:"
echo "  qm stop 240"
echo "  qm rollback 240 $SNAPSHOT_NAME"
echo "  qm start 240"