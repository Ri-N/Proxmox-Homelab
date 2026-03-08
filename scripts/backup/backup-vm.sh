#!/bin/bash
# backup-vm.sh
# Backup a single VM with vzdump

set -euo pipefail

VMID="${1:?Usage: ./backup-vm.sh <vmid> [storage] [mode] [compress]}"
STORAGE="${2:-local}"
MODE="${3:-snapshot}"
COMPRESS="${4:-lz4}"

echo "====================================="
echo "Creating backup for VM $VMID"
echo "====================================="
echo "Storage   : $STORAGE"
echo "Mode      : $MODE"
echo "Compress  : $COMPRESS"
echo "Started   : $(date)"
echo

vzdump "$VMID" \
  --compress "$COMPRESS" \
  --mode "$MODE" \
  --storage "$STORAGE"

echo
echo "✓ Backup completed for VM $VMID"
echo "Finished: $(date)"