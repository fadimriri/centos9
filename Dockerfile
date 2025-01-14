# Use CentOS Stream 9 as the base image
FROM quay.io/centos/centos:stream9

# Set a working directory
WORKDIR /app

# Install necessary packages and configure SSH
RUN dnf -y update && \
    dnf -y install \
        openssh-server \
        openssh-clients \
        sudo \
        passwd && \
    dnf clean all && \
    mkdir /var/run/sshd && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo 'ListenAddress 0.0.0.0' >> /etc/ssh/sshd_config

# Environment variable for SSH password, passed securely at runtime
ARG SSH_PASSWORD
RUN useradd -m -s /bin/bash admin && \
    echo "admin:${SSH_PASSWORD}" | chpasswd && \
    echo "admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Copy startup script
COPY start.sh /start.sh

# Make the startup script executable
RUN chmod +x /start.sh

# Expose dynamic port (default to 22 for development)
EXPOSE 22

# Start SSH service using the startup script
CMD ["/start.sh"]
