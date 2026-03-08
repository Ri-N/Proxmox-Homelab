#!/bin/bash
# secure-ssh-proxmox-nodes.sh
# Harden SSH configuration on all Proxmox nodes

set -euo pipefail

SSH_OPTS="-o StrictHostKeyChecking=accept-new"

NODES=(
  "192.168.178.11"
  "192.168.178.12"
  "192.168.178.13"
  "192.168.178.14"
)

for node in "${NODES[@]}"; do

  echo "====================================="
  echo "Configuring SSH on node: $node"
  echo "====================================="

  ssh $SSH_OPTS root@"$node" <<'EOF'
set -e

CONFIG="/etc/ssh/sshd_config"

echo "[1/4] Backup sshd_config"
cp $CONFIG ${CONFIG}.bak.$(date +%Y%m%d-%H%M)

echo "[2/4] Apply secure SSH settings"

sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' $CONFIG
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' $CONFIG
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' $CONFIG

echo "[3/4] Validate SSH config"
sshd -t

echo "[4/4] Restart SSH"
systemctl restart ssh

echo "SSH hardened on $(hostname)"

EOF

  echo

done

echo "====================================="
echo "SSH hardening applied to all nodes"
echo "====================================="