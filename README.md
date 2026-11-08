# Proxmox Homelab

Shell scripts that build and run my homelab: a four-node Proxmox VE cluster that hosts a
Kubernetes cluster as a cloud-native test environment.

The goal is to manage everything through scripts instead of clicking through the web UI,
so the whole setup can be rebuilt, updated and backed up in a repeatable way.

## Architecture

```
Home network 192.168.178.0/24
│
├── Proxmox VE cluster: pve1 – pve4
│
└── Ubuntu 22.04 VMs (cloned from a cloud-init template)
    ├── k3s-server-01   .240   control plane (kubeadm)
    ├── k3s-server-02   .241   reserved for HA control plane
    ├── k3s-server-03   .242   reserved for HA control plane
    ├── k3s-worker-01   .243   worker
    ├── k3s-worker-02   .244   worker
    └── infra-core-01   .245   infrastructure services
```

| Layer | Technology |
|---|---|
| Virtualisation | Proxmox VE (4 nodes) with a Synology NAS |
| VM provisioning | Ubuntu 22.04 cloud image, cloud-init, `qm` |
| Container runtime | containerd |
| Kubernetes | kubeadm, kubelet and kubectl v1.29 |
| Networking | Calico v3.27, pod CIDR `10.244.0.0/16` |

The node names still carry a `k3s-` prefix from the first version of the cluster,
which used k3s. The cluster now runs upstream Kubernetes set up with kubeadm.

## Scripts

### Proxmox nodes – [`scripts/proxmox/`](scripts/proxmox/)

| Script | What it does |
|---|---|
| `update-proxmox-cluster.sh` | Updates all nodes one after another, checks the UEFI boot setup and reboots safely (remote nodes first, local node last) |
| `replace-proxmox-enterprise-repos-all-nodes.sh` | Switches all nodes from the enterprise to the no-subscription repository |
| `add-admin-key-all-nodes.sh` | Distributes an admin SSH public key to all nodes |
| `secure-ssh-proxmox-nodes.sh` | Hardens SSH on all nodes (key-only login, no root password login) |

### VMs – [`scripts/proxmox/vms/`](scripts/proxmox/vms/)

| Script | What it does |
|---|---|
| `create-template.sh` | Builds the Ubuntu 22.04 cloud-init VM template |
| `create-cluster-vms.sh` | Clones the cluster VMs, assigns static IPs, migrates them to their target nodes and starts them |
| `start-all-vms.sh` | Starts all VMs across the cluster |
| `disabling-swap-k8s-nodes.sh` | Disables swap on all Kubernetes nodes |
| `snapshots/` | Snapshots all VMs, rolls a VM back, deletes snapshots |

### Kubernetes – [`scripts/proxmox/vms/kubernetes/`](scripts/proxmox/vms/kubernetes/) and [`containerd/`](scripts/proxmox/vms/containerd/)

Installs and configures containerd and the kernel settings Kubernetes needs, installs the
Kubernetes packages, initialises the control plane, deploys Calico, joins and labels the
worker nodes and sets up `kubectl`. Each step has a matching `verify-*.sh` script, and
`cluster-health-check.sh` checks the cluster as a whole.

### Backups and tests

| Script | What it does |
|---|---|
| `scripts/backup/backup-all-vms.sh` | Creates vzdump backups of all homelab VMs |
| `scripts/backup/backup-vm.sh` | Backs up a single VM |
| `scripts/tests/test-vms.sh` | Checks every VM: ping, SSH login and hostname |

## Setup order

1. Prepare the Proxmox nodes: repositories, SSH keys, SSH hardening, updates
2. `create-template.sh`, then `create-cluster-vms.sh`
3. `tests/test-vms.sh` to check that all VMs are reachable
4. `disabling-swap-k8s-nodes.sh` and the `containerd/` scripts
5. `install-kubernetes-packages.sh`, `init-control-plane.sh`, `calico/deploy-calico.sh`
6. `join-nodes/join-worker-nodes.sh <token> <ca-cert-hash>`, `label-worker-nodes.sh`
7. `kubectl/setup-kubectl.sh` and `cluster-health-check.sh`

More details on the network are in [`docs/architecture/network-design.md`](docs/architecture/network-design.md).

## Roadmap

- Highly available control plane with all three server nodes
- MetalLB and an ingress controller for exposing services
- Monitoring with Prometheus and Grafana
- Kubernetes network policies

> The scripts are written for my own network (IP addresses, node names, storage).
> Adjust the variables at the top of each script before using them elsewhere.
