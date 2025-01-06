## Pre-conditions

Copy the public key of the server to keys directory:

```bash
 cp ~/.ssh/id_ed25519_proxmox_vm.pub keys
```

## Build Ubuntu Docker Image

Build the base Docker image that has ssh running and public keys loaded

```bash
docker build -t ubuntu-ansible-node .
```

## Run the Ubuntu Servers

Servers are setup using Docker Compose.

```bash
docker compose up -d
```

# Run the Ansible Playbook

```bash
ansible-playbook -i inventory.yaml ping_playbook.yaml
```

## Stop the Ubuntu Servers

```bash
docker compose down
```