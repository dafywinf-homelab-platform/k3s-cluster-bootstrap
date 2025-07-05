# Ansible Host Accessibility Verification

## Overview

This setup ensures all hosts defined in the inventory are accessible via SSH using the `community.general.ping` module.

## Prerequisites

- Ansible installed (`ansible --version`)
- SSH keys set up for the remote hosts
- Valid inventory file

## Usage

1. Install the required collection:
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```   

1. Install the required collection:
   ```bash
   ansible-playbook site.yml
   ```

## 🧠 **Key Takeaways**

1. **Inventory File (`hosts.yml`)** defines your infrastructure.
2. **Collection (`community.general`)** provides the `ping` module.
3. **Playbook (`verify_access.yml`)** ensures SSH connectivity to all hosts.
4. **Configuration (`ansible.cfg`)** sets global Ansible behavior.
5. **Group Vars (`all.yml`)** handle shared SSH settings.

---

This setup will help you quickly verify whether all your infrastructure hosts are reachable via SSH using Ansible.

## Accessing the Cluster

```bash
k9s --kubeconfig=$HOME/.ssh/proxmox_k3s_kubeconfig
```

## Sample Deployment

This deployment creates a single replica of a web server serving a basic "Hello from NGINX" page, exposed via a
Kubernetes Service. By default, the application is configured to deploy into the hello-world namespace, ensuring its
resources are logically grouped and isolated within the cluster.


```bash
kubectl --kubeconfig=$HOME/.ssh/proxmox_k3s_kubeconfig create namespace hello-world
kubectl --kubeconfig=$HOME/.ssh/proxmox_k3s_kubeconfig apply -f ./sample/hello-world.yml

# Optional - If you want to deploy a second instance of the service in a different namespace
kubectl --kubeconfig=$HOME/.ssh/proxmox_k3s_kubeconfig create namespace hello-world-again
kubectl --kubeconfig=$HOME/.ssh/proxmox_k3s_kubeconfig apply -f ./sample/hello-world-again.yml

# Optional - If you want to deploy a third instance with Ingress
kubectl --kubeconfig=$HOME/.ssh/proxmox_k3s_kubeconfig create namespace hello-world-ingress
kubectl --kubeconfig=$HOME/.ssh/proxmox_k3s_kubeconfig apply -f ./sample/hello-world-ingress.yml

```
**Note::** The hello-world-ingress.yml will need to updated with the IP address that MetalLB load balancer has assigned 
to the Traefik service. You can find this IP address by running the command below:

```bash
 kubectl get svc -n kube-system traefik
```

### Accessing the Services

Since this deployment utilizes a LoadBalancer type Service and your cluster is configured with MetalLB, the service will automatically be assigned an external IP address from your MetalLB address pool. This allows you to access the application from outside the Kubernetes cluster without needing kubectl port-forward.

To find the external IP address assigned by MetalLB, use the following command:

```bash
kubectl --kubeconfig=$HOME/.ssh/proxmox_k3s_kubeconfig get service hello-world-service -n hello-world

# Optional - If you deployed the second instance
kubectl --kubeconfig=$HOME/.ssh/proxmox_k3s_kubeconfig get service hello-world-service -n hello-world-again

# Optional - If you deployed the third instance with Ingress - Accessed via Ingress - Traefik 
wget http://hello.192.168.86.10.nip.io 
```

### Delete the Service

```bash
kubectl --kubeconfig=$HOME/.ssh/proxmox_k3s_kubeconfig delete namespace hello-world

# Optional - If you want to deploy a second instance of the service in a different namespace
kubectl --kubeconfig=$HOME/.ssh/proxmox_k3s_kubeconfig delete namespace hello-world-again

# Optional - If you want to deploy a third instance with Ingress
kubectl --kubeconfig=$HOME/.ssh/proxmox_k3s_kubeconfig delete namespace hello-world-ingress
```

## Todo
* Deploy Traefik - DONE
* Review the errors that exist in Lens at the Node level.
* Deploy ArgoCD
* Extract the KubeVIP and MetalLB IP addresses and use them in later work e.g. ArgoCD deployment
* Note: Currently have simple added

## **Research and Documentation**

As part of the implementation work, extensive research has been conducted into all the underlying technologies to ensure
a robust and well-informed deployment. Detailed summaries of each technology, their use cases, and best practices have
been compiled into dedicated README files for ease of reference. These summaries provide a comprehensive understanding
of the components used in the project.

### **Available Documentation**

- [Address Resolution Protocol (ARP)](documentation/research/04-ARP.md)
- [MetalLB](documentation/research/02-MetalLB.md)
- [Kube-VIP](documentation/research/03-KubeVIP.md)
- [DNS Resolution](documentation/research/01-DNS.md)

Each README contains an in-depth exploration of the respective technology, including its purpose, operation, and any
relevant considerations for its integration into the project.

These documents serve as a foundational resource for anyone involved in implementing, maintaining, or extending the
current setup.

### Additional References:

- [K3s Cluster Example with Cilium, Let's Encrypt, Renovate, Prometheus](https://github.com/axivo/k3s-cluster)

