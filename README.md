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