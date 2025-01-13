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

This setup will help you quickly verify whether all your infrastructure hosts are reachable via SSH using Ansible. 🚀 Let
me know if you encounter any issues! 😊

## Sample Deployment

```bash
kubectl --kubeconfig=$HOME/.ssh/proxmox_k3s_kubeconfig apply -f ./sample/hello-world.yml
```

## Todo

* Review the errors that exist in Lens at the Node level.

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

