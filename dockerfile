# Use CentOS Stream 9 as base image
FROM quay.io/centos/centos:stream9

# Install necessary packages
RUN dnf -y update && \
    dnf -y install \
    openssh-server \
    openssh-clients \
    sudo \
    passwd \
    && dnf clean all

# Configure SSH
RUN mkdir /var/run/sshd && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Create a user with sudo privileges
# Note: In production, you should set these via Railway environment variables
RUN useradd -m -s /bin/bash admin && \
    echo "admin:${SSH_PASSWORD:-adminpass}" | chpasswd && \
    echo "admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Expose SSH port
EXPOSE ${PORT:-22}

# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]