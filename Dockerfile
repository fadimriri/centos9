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
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo 'ListenAddress 0.0.0.0' >> /etc/ssh/sshd_config

# Create a user with sudo privileges
ENV SSH_PASSWORD=adminpass
RUN useradd -m -s /bin/bash admin && \
    echo "admin:${SSH_PASSWORD}" | chpasswd && \
    echo "admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Dynamic port assignment script
COPY <<EOF /start.sh
#!/bin/bash

# Log startup details
echo "Starting SSH setup..." >> /tmp/startup.log

# Ensure $PORT is set, or use a default
if [ -z "\$PORT" ]; then
    PORT=22  # Fallback to default SSH port if $PORT is not set
    echo "WARN: \$PORT not set, using default port 22" >> /tmp/startup.log
else
    echo "INFO: \$PORT set to \$PORT" >> /tmp/startup.log
fi

# Update SSH config with the assigned port
sed -i "s/^#Port .*/Port \$PORT/" /etc/ssh/sshd_config
echo "INFO: Updated SSHD config to use port \$PORT" >> /tmp/startup.log

# Update the admin users password if specified
if [ -n "\$SSH_PASSWORD" ]; then
    echo "admin:\$SSH_PASSWORD" | chpasswd
fi

# Debug SSH configuration
cat /etc/ssh/sshd_config >> /tmp/startup.log

# Start the SSH daemon
exec /usr/sbin/sshd -D
EOF

RUN chmod +x /start.sh

# Expose a placeholder SSH port
EXPOSE 22

# Start SSH service
CMD ["/start.sh"]

