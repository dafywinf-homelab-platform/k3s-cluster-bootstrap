# K3s Cluster Bootstrap

[![CI - Validate](https://github.com/dafywinf-homelab-platform/k3s-cluster-bootstrap/actions/workflows/ci-validate.yaml/badge.svg)](https://github.com/dafywinf-homelab-platform/k3s-cluster-bootstrap/actions/workflows/ci-validate.yaml)

Automated day-0/day-1 provisioning of a **K3s** cluster on Proxmox-hosted Ubuntu VMs using **Ansible**. This repo applies opinionated homelab defaults (Kube-VIP, MetalLB, Traefik) and includes a minimal smoke-test to verify networking and ingress.

For the core design and decisions, see **[docs/01-design-specification.md](docs/01-design-specification.md)**.

---

## Features

* Ansible playbooks for:

   * Host reachability checks
   * OS preparation (swap, time sync, base packages)
   * K3s control plane + workers install/join
   * **Kube-VIP** API virtual IP (ARP mode)
   * **MetalLB** L2 address pool
   * **Traefik** ingress
   * Smoke tests (Service/Ingress reachability)
* Declarative configuration via inventories and `group_vars`
* CI linting hooks (recommended) and optional Dependabot

---

## Pre-conditions

* Proxmox VMs already created (see **Related Repository** below)
* Admin workstation with:

   * Ansible ≥ 2.15 (`ansible --version`)
   * Python 3.x
   * SSH key-based access to target hosts
* Inventory populated: `inventory/hosts.yml`
* Basic `group_vars` set (VIP, MetalLB pool, K3s version, CIDRs)
* Nodes have outbound internet access

---

## Quick Start

1. Install required Ansible collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

2. Verify host accessibility:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/01_verify_access.yml
```

3. Bootstrap the cluster (full run):

```bash
ansible-playbook -i inventory/hosts.yml site.yml
```

---

## Ansible Host Accessibility Verification

This step confirms all hosts in the inventory are reachable via SSH using the `community.general.ping` module.

**Key bits**

1. **Inventory** (`inventory/hosts.yml`) defines the target machines.
2. **Collection** (`community.general`) provides the `ping` module.
3. **Playbook** (`playbooks/01_verify_access.yml`) executes the connectivity check.
4. **Configuration** (`ansible.cfg`) sets global Ansible behaviour.
5. **Group Vars** (`inventory/group_vars/all.yml`) hold shared SSH and cluster settings.

---

## Accessing the Cluster

The playbooks generate a kubeconfig named **`proxmox_k3s_kubeconfig`** in the **current working directory** when you run them. Point your tools at this file:

```bash
export KUBECONFIG="$(pwd)/proxmox_k3s_kubeconfig"
kubectl get nodes
# or
k9s
```

> The kubeconfig is generated locally at runtime and **must not be committed** to version control.

---

## Sample Deployment (Hello World)

Deploy minimal HTTP services to validate LoadBalancer allocation and Ingress:

```bash
# 1) Basic service
kubectl --kubeconfig="$(pwd)/proxmox_k3s_kubeconfig" create namespace hello-world
kubectl --kubeconfig="$(pwd)/proxmox_k3s_kubeconfig" apply -f ./sample/hello-world.yml -n hello-world

# 2) Optional: second instance
kubectl --kubeconfig="$(pwd)/proxmox_k3s_kubeconfig" create namespace hello-world-again
kubectl --kubeconfig="$(pwd)/proxmox_k3s_kubeconfig" apply -f ./sample/hello-world-again.yml -n hello-world-again

# 3) Optional: ingress-backed instance
kubectl --kubeconfig="$(pwd)/proxmox_k3s_kubeconfig" create namespace hello-world-ingress
kubectl --kubeconfig="$(pwd)/proxmox_k3s_kubeconfig" apply -f ./sample/hello-world-ingress.yml -n hello-world-ingress
```

### Find External IPs (MetalLB)

```bash
kubectl --kubeconfig="$(pwd)/proxmox_k3s_kubeconfig" get svc -n hello-world hello-world-service
kubectl --kubeconfig="$(pwd)/proxmox_k3s_kubeconfig" get svc -n hello-world-again hello-world-service
```

### Ingress via Traefik (`nip.io`)

Update `sample/hello-world-ingress.yml` to use the **Traefik** EXTERNAL-IP (assigned by MetalLB):

```bash
kubectl --kubeconfig="$(pwd)/proxmox_k3s_kubeconfig" -n kube-system get svc traefik
# Suppose EXTERNAL-IP is 192.168.86.10, then:
wget -qO- http://hello.192.168.86.10.nip.io
```

### Clean up

```bash
kubectl --kubeconfig="$(pwd)/proxmox_k3s_kubeconfig" delete namespace hello-world
kubectl --kubeconfig="$(pwd)/proxmox_k3s_kubeconfig" delete namespace hello-world-again
kubectl --kubeconfig="$(pwd)/proxmox_k3s_kubeconfig" delete namespace hello-world-ingress
```

---

## Configuration

Cluster-wide settings live under `inventory/group_vars/`:

* `kube_vip_address`, `kube_vip_interface`
* `metallb_pools` (L2 ranges reserved on your LAN)
* `k3s_version`, `cluster_cidr`, `service_cidr`
* Optional `ingress_domain_suffix` (defaults nicely to `nip.io` for homelab)

> Reserve your MetalLB pool in DHCP/router to avoid IP conflicts.

---

## Repository Layout (overview)

```
ansible.cfg
requirements.yml
site.yml
inventory/
  hosts.yml
  group_vars/
playbooks/
  01_verify_access.yml
  10_os_prep.yml
  20_k3s_install.yml
  30_kubevip.yml
  40_metallb.yml
  50_traefik.yml
  90_smoke.yml
roles/
docs/
  01-design-specification.md
  research/
sample/
```

---

## CI / Maintenance

* **CI**: `ci-validate.yaml` workflow for `ansible-lint`, `yamllint`, and basic structure checks.
* **Dependabot**: optional updates for GitHub Actions and collections.
* **Renovate**: not enabled by default.

---

## Version Control Hygiene

Ensure the generated kubeconfig is ignored:

```
# kubeconfig generated by playbooks
proxmox_k3s_kubeconfig
```

---

## Research & Background

* [DNS Resolution](docs/research/01-DNS.md)
* [MetalLB](docs/research/02-MetalLB.md)
* [Kube-VIP](docs/research/03-KubeVIP.md)
* [ARP](docs/research/04-ARP.md)

---

## Related Repository

This project assumes the Kubernetes target VMs already exist. See the VM pipeline and conventions in:

* **Proxmox VM Bootstrap:** [https://github.com/dafywinf-homelab-platform/proxmox-vm-bootstrap](https://github.com/dafywinf-homelab-platform/proxmox-vm-bootstrap)

---

## Status & Roadmap

Live backlog and improvements are tracked in **[docs/01-design-specification.md](docs/01-design-specification.md)** under *To-Dos & Improvements*. The README is intentionally focused on usage and setup to stay concise and consistent with the *proxmox-vm-bootstrap* repository.
