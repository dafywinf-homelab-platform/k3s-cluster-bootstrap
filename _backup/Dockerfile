# Use the latest Ubuntu image
FROM ubuntu:latest

# Install OpenSSH server
RUN apt-get update && apt-get install -y openssh-server net-tools

# Ensure SSHD run directory exists
RUN mkdir -p /var/run/sshd

# Create SSH directory for root and set permissions
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Copy public key into authorized_keys
COPY keys/id_ed25519_proxmox_vm.pub /root/.ssh/authorized_keys

# Set correct permissions for the authorized_keys file
RUN chmod 600 /root/.ssh/authorized_keys

# Enable root login via SSH
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Expose SSH port
EXPOSE 22

# Start the SSH daemon in the foreground
ENTRYPOINT ["/usr/sbin/sshd", "-D"]