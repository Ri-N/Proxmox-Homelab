#!/bin/bash
# backup-all-vms.sh
# Create vzdump backups for all homelab VMs

set -euo pipefail

STORAGE="${1:-local}"
MODE="${2:-snapshot}"
COMPRESS="${3:-lz4}"

VMIDS=(240 241 242 243 244 245)

echo "====================================="
echo "Creating Proxmox VM Backups"
echo "====================================="
echo "Storage   : $STORAGE"
echo "Mode      : $MODE"
echo "Compress  : $COMPRESS"
echo "VMs       : ${VMIDS[*]}"
echo "Started   : $(date)"
echo

vzdump "${VMIDS[@]}" \
  --compress "$COMPRESS" \
  --mode "$MODE" \
  --storage "$STORAGE"

echo
echo "====================================="
echo "✓ All VM backups completed"
echo "====================================="
echo "Finished: $(date)"