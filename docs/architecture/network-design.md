# Network Design for Kubernetes Cluster

This document describes the network architecture for the homelab
Kubernetes cluster.

## Network Overview

The Kubernetes cluster operates on a private home network with static IP
assignments for all nodes.

### Network Configuration

- **Network**: 192.168.178.0/24 (private home network)
- **Gateway**: 192.168.178.1 (router / FritzBox)
- **DNS**: 192.168.178.1 (primary)
- **Domain**: home

## Node IP Assignments

### Static IP Addresses

All cluster nodes use static IP addresses configured via cloud-init:

---

Node IP Address Hostname Role Resources

---

Server 1 192.168.178.240 k3s-server-01 Control Plane 2GB RAM, 2 cores,
+20GB disk

Server 2 192.168.178.241 k3s-server-02 Control Plane 2GB RAM, 2 cores,
+20GB disk

Server 3 192.168.178.242 k3s-server-03 Control Plane 2GB RAM, 2 cores,
+20GB disk

Worker 1 192.168.178.243 k3s-worker-01 Worker 3GB RAM, 2 cores,
+40GB disk

Worker 2 192.168.178.244 k3s-worker-02 Worker 3GB RAM, 2 cores,
+40GB disk

Infra 192.168.178.245 infra-core-01 Infrastructure 2GB RAM, 1 core,
+20GB disk

---

### Why Static IPs?

Static IP addresses are essential for Kubernetes because:

1.  **Stable references**: Nodes must reliably reach each other
2.  **DNS independence**: Cluster continues to function if DNS fails
3.  **Certificate stability**: TLS certificates reference node IPs
4.  **Service exposure**: Predictable endpoints simplify routing

## Hostname Resolution

### /etc/hosts Configuration

All nodes have identical `/etc/hosts` entries mapping hostnames to IPs:

    192.168.178.240 k3s-server-01
    192.168.178.241 k3s-server-02
    192.168.178.242 k3s-server-03
    192.168.178.243 k3s-worker-01
    192.168.178.244 k3s-worker-02
    192.168.178.245 infra-core-01

### Cloud-Init Persistence

To prevent cloud-init from overwriting `/etc/hosts` on reboot, the
cloud-init template is modified:

**File**: `/etc/cloud/templates/hosts.debian.tmpl`

This ensures hostname resolution persists across reboots.

## Firewall Configuration

### UFW Rules

Each node runs **UFW (Uncomplicated Firewall)** with the following
configuration.

**Default Policies**

- Incoming: DENY
- Outgoing: ALLOW

**Allowed Connections**

- SSH (port 22)
- All traffic between cluster nodes (192.168.178.240-245)

### Rationale

- **Simple cluster communication**: Kubernetes nodes must communicate
  freely
- **External protection**: Prevents unwanted external connections
- **Administrative access**: SSH remains available for management

### Production Considerations

For production environments firewall rules should be more restrictive.

**Control Plane Nodes**

- 6443: Kubernetes API server
- 2379-2380: etcd server client API
- 10250: Kubelet API
- 10257: kube-controller-manager
- 10259: kube-scheduler

**Worker Nodes**

- 10250: Kubelet API
- 30000-32767: NodePort Services

## Network Verification

### Connectivity Tests

The network must support:

1.  **Ping** between all nodes
2.  **SSH** connectivity
3.  **Hostname resolution**
4.  **Internet access**
5.  **DNS resolution**

### Test Script

Network tests can be automated with:

```bash
./scripts/network/test-network.sh
```

The script verifies:

- ping connectivity
- ssh access
- hostname resolution
- internet connectivity
- dns resolution
- firewall status

## Kubernetes Networking

### Pod Network CIDR

The Kubernetes cluster uses a separate pod network.

- **Pod Network**: 10.42.0.0/16 (k3s default)
- **Service Network**: 10.43.0.0/16 (k3s default)

### CNI Plugin

The cluster uses **Flannel** as its CNI plugin.

Advantages:

- Simple configuration
- Reliable networking
- Suitable for homelab environments
- Default choice for k3s

## Network Topology

    Internet
        |
    [FritzBox Gateway: 192.168.178.1]
        |
    [Home Network: 192.168.178.0/24]
        |
        +-- [Proxmox Cluster]
        |       |
        |       +-- pve1
        |       +-- pve2
        |       +-- pve3
        |       +-- pve4
        |
        +-- Virtual Machines
                |
                +-- k3s-server-01 (192.168.178.240)
                +-- k3s-server-02 (192.168.178.241)
                +-- k3s-server-03 (192.168.178.242)
                +-- k3s-worker-01 (192.168.178.243)
                +-- k3s-worker-02 (192.168.178.244)
                +-- infra-core-01 (192.168.178.245)

## Network Traffic Flow

### Control Plane → Worker Communication

1.  Workers connect to control plane on port **6443**
2.  Control plane connects to kubelets on port **10250**
3.  Pod-to-pod traffic uses the **Flannel overlay network**

### External → Cluster Communication

External access to services can happen via:

1.  **NodePort** services
2.  **Ingress Controller**
3.  **LoadBalancer** (MetalLB planned)

## Troubleshooting

### Common Network Issues

**Cannot ping nodes**

    sudo ufw status
    ip addr show

**Hostname resolution fails**

    cat /etc/hosts
    getent hosts k3s-server-01

**SSH connection refused**

    systemctl status ssh
    sudo ufw status

**No internet access**

    ip route
    nslookup google.com
    ping 192.168.178.1

## Security Considerations

### Current Security

✅ Firewall enabled\
✅ SSH key authentication\
✅ Limited incoming connections\
✅ Trusted internal cluster network

### Future Enhancements

- Kubernetes Network Policies
- WireGuard VPN access
- Service mesh (Istio / Linkerd)
- Network monitoring with Prometheus

## Performance Considerations

### Network Bandwidth

- 1 Gbps network interfaces
- sufficient for homelab workloads

### Latency

- \<1ms between nodes
- suitable for distributed workloads

## References

- Kubernetes Networking Concepts\
- Flannel CNI Documentation\
- UFW Firewall Documentation
