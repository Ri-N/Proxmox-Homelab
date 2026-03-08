#!/bin/bash
# rollback-vm.sh
# Roll back a VM to a given snapshot on the correct Proxmox node

set -euo pipefail

VMID="${1:?Usage: ./rollback-vm.sh <vmid> <snapshot-name> <node>}"
SNAPSHOT_NAME="${2:?Usage: ./rollback-vm.sh <vmid> <snapshot-name> <node>}"
NODE="${3:?Usage: ./rollback-vm.sh <vmid> <snapshot-name> <node>}"

SSH_OPTS="-o StrictHostKeyChecking=accept-new"

# Proxmox node IPs
PVE2_IP="192.168.178.12"
PVE3_IP="192.168.178.13"
PVE4_IP="192.168.178.14"

rollback_local() {
    echo "Stopping VM $VMID on local node..."
    qm stop "$VMID" || true

    echo "Rolling back VM $VMID to snapshot '$SNAPSHOT_NAME'..."
    qm rollback "$VMID" "$SNAPSHOT_NAME"

    echo "Starting VM $VMID..."
    qm start "$VMID"
}

rollback_remote() {
    local target_ip="$1"

    echo "Stopping VM $VMID on remote node $target_ip..."
    ssh $SSH_OPTS root@"$target_ip" "qm stop $VMID || true"

    echo "Rolling back VM $VMID to snapshot '$SNAPSHOT_NAME' on $target_ip..."
    ssh $SSH_OPTS root@"$target_ip" "qm rollback $VMID $SNAPSHOT_NAME"

    echo "Starting VM $VMID on $target_ip..."
    ssh $SSH_OPTS root@"$target_ip" "qm start $VMID"
}

case "$NODE" in
    pve1)
        rollback_local
        ;;
    pve2)
        rollback_remote "$PVE2_IP"
        ;;
    pve3)
        rollback_remote "$PVE3_IP"
        ;;
    pve4)
        rollback_remote "$PVE4_IP"
        ;;
    *)
        echo "Unknown node: $NODE"
        echo "Valid nodes: pve1, pve2, pve3, pve4"
        exit 1
        ;;
esac

echo
echo "Rollback completed for VM $VMID."