#!/bin/bash
# add-admin-key-all-nodes.sh
# Add an admin SSH public key to all Proxmox nodes

set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=accept-new"
SCP_OPTS="-o StrictHostKeyChecking=accept-new"

PUBKEY_FILE="${1:?Usage: ./add-admin-key-all-nodes.sh <public-key-file>}"

if [ ! -f "$PUBKEY_FILE" ]; then
  echo "Public key file not found: $PUBKEY_FILE"
  exit 1
fi

NODES=(
  "192.168.178.11"
  "192.168.178.12"
  "192.168.178.13"
  "192.168.178.14"
)

for node in "${NODES[@]}"; do
  echo "=========================================="
  echo "Adding admin key on node: $node"
  echo "=========================================="

  scp $SCP_OPTS "$PUBKEY_FILE" root@"$node":/tmp/admin_key.pub

  ssh $SSH_OPTS root@"$node" 'bash -s' <<'EOF'
set -euo pipefail

mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

if ! grep -Fxq -f /tmp/admin_key.pub /root/.ssh/authorized_keys; then
  cat /tmp/admin_key.pub >> /root/.ssh/authorized_keys
  echo "Key added on $(hostname)"
else
  echo "Key already present on $(hostname)"
fi

rm -f /tmp/admin_key.pub
EOF

  echo
done

echo "Admin key processed on all nodes."