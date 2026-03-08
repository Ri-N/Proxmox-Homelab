#!/bin/bash
# test-vms.sh
# Verify that all homelab VMs are reachable and correctly configured

set -u

SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new"

VMS=(
  "192.168.178.240:k3s-server-01"
  "192.168.178.241:k3s-server-02"
  "192.168.178.242:k3s-server-03"
  "192.168.178.243:k3s-worker-01"
  "192.168.178.244:k3s-worker-02"
  "192.168.178.245:infra-core-01"
)

PASSED=0
FAILED=0

print_header() {
  echo "========================================"
  echo " Homelab VM Validation"
  echo "========================================"
  echo
}

test_ping() {
  local ip="$1"

  if ping -c 2 -W 2 "$ip" >/dev/null 2>&1; then
    echo "  [OK]   Ping to $ip"
    return 0
  else
    echo "  [FAIL] Ping to $ip"
    return 1
  fi
}

test_ssh_and_hostname() {
  local ip="$1"
  local expected_hostname="$2"

  local actual_hostname
  actual_hostname=$(ssh $SSH_OPTS ubuntu@"$ip" "hostname" 2>/dev/null)

  if [ -z "$actual_hostname" ]; then
    echo "  [FAIL] SSH to $ip"
    return 1
  fi

  echo "  [OK]   SSH to $ip"

  if [ "$actual_hostname" = "$expected_hostname" ]; then
    echo "  [OK]   Hostname is $actual_hostname"
    return 0
  else
    echo "  [FAIL] Hostname mismatch on $ip (expected: $expected_hostname, got: $actual_hostname)"
    return 1
  fi
}

run_tests() {
  for vm in "${VMS[@]}"; do
    IFS=":" read -r ip hostname <<< "$vm"

    echo "Testing $hostname ($ip)"
    echo "----------------------------------------"

    local_failed=0

    test_ping "$ip" || local_failed=1
    test_ssh_and_hostname "$ip" "$hostname" || local_failed=1

    if [ "$local_failed" -eq 0 ]; then
      echo "  Result: PASS"
      PASSED=$((PASSED + 1))
    else
      echo "  Result: FAIL"
      FAILED=$((FAILED + 1))
    fi

    echo
  done
}

print_summary() {
  echo "========================================"
  echo " Summary"
  echo "========================================"
  echo " Passed: $PASSED"
  echo " Failed: $FAILED"
  echo

  if [ "$FAILED" -eq 0 ]; then
    echo "All VM checks passed."
    exit 0
  else
    echo "Some VM checks failed."
    exit 1
  fi
}

print_header
run_tests
print_summary