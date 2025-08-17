# K3s Cluster Bootstrap — Design Specification

This document captures the key design, tooling, and automation decisions for the **K3s Cluster Bootstrap** repository.
It summarises the current setup so that future discussions can build upon a shared reference point.

## 1. Context & Problem Statement

You have Proxmox-provisioned Ubuntu VMs (created elsewhere) and require an idempotent, repeatable way to:

* Prepare hosts for Kubernetes.
* Install and configure K3s (single or small HA control plane).
* Provide day-1 networking and ingress (Kube-VIP, MetalLB, Traefik).
* Validate the cluster with a simple, reachable sample workload.
* Keep everything expressed as code using Ansible inventories, roles, and plays.

Assumptions:

* Passwordless SSH access from an admin workstation.
* Private LAN addressing with a reserved range for MetalLB; internet egress from nodes.
* Proxmox networking already in place.

## 2. Goals & Non-Goals

**Goals**

* One-command bootstrap of K3s via Ansible with clear, declarative configuration.
* Floating API endpoint via Kube-VIP; service load-balancing via MetalLB.
* Ingress via Traefik with straightforward host routing (e.g. `nip.io` examples).
* Idempotent re-runs to converge drifted hosts.

**Non-Goals**

* Full GitOps application lifecycle (left for a future Argo CD phase).
* Enterprise multi-tenant hardening beyond a sensible home-lab baseline.
* VM lifecycle management (handled in the Proxmox VM bootstrap repository).

## 3. High-Level Architecture

* **Control plane:** 1–3 nodes (embedded etcd if HA), fronted by Kube-VIP in ARP mode.
* **Workers:** 0+ nodes joined after control-plane availability.
* **CNI/runtime:** K3s defaults (flannel + containerd), overridable later.
* **Load balancing:** MetalLB L2 with a reserved IP pool on the LAN.
* **Ingress:** Traefik as the default K3s ingress controller.
* **DNS:** `nip.io` for examples; optional later integration with local DNS.

## 4. Repository Structure (overview)

* Root: `ansible.cfg`, `requirements.yml`, `site.yml`
* `inventory/`: `hosts.yml` and `group_vars/` for cluster-wide defaults (VIP, pools, CIDRs, versions)
* `roles/`: `common`, `k3s`, `kubevip`, `metallb`, `traefik`, `smoke`
* `playbooks/`: phase-oriented plays (verify access, OS prep, K3s install, add-ons, smoke)
* `docs/`: design spec (this file), research notes, and runbooks
* `sample/`: minimal validation manifests (kept intentionally small)

## 5. Execution Model

1. **Verify access** to all hosts (SSH and privilege escalation).
2. **OS preparation** (swap off, time sync, kernel params, core packages).
3. **K3s install** (initial control plane → additional control planes → workers).
4. **Networking & ingress** (Kube-VIP VIP; MetalLB pool and L2 advert; Traefik accessible).
5. **Smoke tests** (tiny HTTP app; confirm LoadBalancer IP and HTTP 200 via ingress).

## 6. Configuration Strategy

* Cluster-wide values in `group_vars` (K3s version, cluster/service CIDRs, Kube-VIP address/interface, MetalLB pools,
  domain suffix).
* Minimal `host_vars` for per-node specifics only.
* Kubeconfig generated as a runtime artefact and ignored by version control.
* Use Ansible Vault sparingly; avoid storing long-lived secrets in the repo.

## 7. Day-1 Verification (Definition of Done)

* Nodes report **Ready**; `kubectl` access via the API VIP succeeds.
* A `LoadBalancer` service is allocated an address from the MetalLB pool.
* An ingress hostname resolves and returns HTTP 200 (via `nip.io` or local DNS).
* Re-running the play results in clean convergence with no unexpected changes.

## 8. Security Posture (baseline)

* SSH key-only; password authentication disabled.
* Minimal host package footprint.
* Kubeconfig generated locally and not committed to the repository.
* Hardening (Pod Security, NetworkPolicy) can be layered without redesign.

## 9. CI/Linting

* **Pre-commit** for YAML formatting, whitespace, and shell linting.
* **GitHub Actions** for `ansible-lint` and `yamllint`, with an optional dry-run where feasible.
* Optional encrypted artefact handling for kubeconfig in follow-on jobs (not required for MVP).

## 10. Operations & Lifecycle

* **Scale out:** add host to inventory → re-run plays.
* **Replace node:** drain → rebuild → re-add → re-run.
* **Upgrade:** bump K3s version and re-run during a maintenance window.
* **Backups:** if using embedded etcd HA, schedule snapshots and document restore steps.

## 11. Risks & Mitigations

* **IP conflicts (MetalLB pool):** reserve pool in DHCP/router; document ownership.
* **VIP announcements (ARP):** validate L2 adjacency; keep Kube-VIP in ARP mode for simplicity.
* **Kubeconfig leakage:** generate locally; `.gitignore` enforced.
* **Ingress/LB drift:** maintain smoke tests to detect functional regressions.

## 12. Documentation Plan

* **README:** quick start, prerequisites, bootstrap, basic troubleshooting.
* **docs/research:** ARP/L2, Kube-VIP, MetalLB, DNS considerations.
* **docs/runbooks:** node replacement, upgrades, backup/restore.
* **docs/adrs:** key decisions (Kube-VIP vs external LB; Traefik vs NGINX; Cilium vs flannel).

## 13. Roadmap

* **v1.0 (MVP):** single/HA control plane, Kube-VIP, MetalLB, Traefik, smoke tests, basic CI/linting.
* **v1.x:** optional TLS on ingress, local DNS integration, improved diagnostics.
* **v2.0:** GitOps bootstrap (Argo CD), automated upgrades/backups, richer policies as needed.

## 14. Open Questions

* Keep flannel or adopt **Cilium** for richer policy/observability?
* Default TLS approach (self-signed, local CA, or ACME with DNS-01)?
* Default to single control plane for simplicity, or make three control planes the baseline?

## 15. To-Dos & Improvements

* Replace any committed kubeconfig with a generated artefact; confirm `.gitignore` coverage.
* Finalise roles for Kube-VIP, MetalLB, and Traefik with clear variables and defaults.
* Add deterministic smoke tests that assert LoadBalancer allocation and ingress reachability.
* Introduce `ansible-lint`, `yamllint`, and pre-commit hooks; wire into GitHub Actions.
* Add a lightweight diagnostics play (node/service health, logs, common failure hints).
* Provide a templated inventory and example `group_vars` to accelerate first-run setup.
