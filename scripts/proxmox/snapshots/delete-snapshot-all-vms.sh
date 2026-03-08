#!/bin/bash
# delete-snapshot-all-vms.sh

set -euo pipefail

SNAPSHOT_NAME="${1:?Usage: ./delete-snapshot-all-vms.sh <snapshot-name>}"
SSH_OPTS="-o StrictHostKeyChecking=accept-new"

PVE2_IP="192.168.178.12"
PVE3_IP="192.168.178.13"
PVE4_IP="192.168.178.14"

qm delsnapshot 240 "$SNAPSHOT_NAME" || true
qm delsnapshot 244 "$SNAPSHOT_NAME" || true

ssh $SSH_OPTS root@"$PVE2_IP" "qm delsnapshot 241 $SNAPSHOT_NAME || true"
ssh $SSH_OPTS root@"$PVE2_IP" "qm delsnapshot 245 $SNAPSHOT_NAME || true"
ssh $SSH_OPTS root@"$PVE3_IP" "qm delsnapshot 242 $SNAPSHOT_NAME || true"
ssh $SSH_OPTS root@"$PVE4_IP" "qm delsnapshot 243 $SNAPSHOT_NAME || true"

echo "Snapshot '$SNAPSHOT_NAME' deleted on all VMs."