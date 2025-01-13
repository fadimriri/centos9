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
ENV SSH_PASSWORD=adminpass
RUN useradd -m -s /bin/bash admin && \
    echo "admin:${SSH_PASSWORD}" | chpasswd && \
    echo "admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Configure dynamic port for Railway
RUN echo 'Port 22' >> /etc/ssh/sshd_config && \
    echo 'ListenAddress 0.0.0.0' >> /etc/ssh/sshd_config

# Dynamic port assignment script
COPY <<EOF /start.sh
#!/bin/bash

# Log the provided port for debugging
echo "Starting SSH on PORT: $PORT" >> /tmp/startup.log

if [ -n "$PORT" ]; then
    sed -i "s/^Port .*/Port $PORT/" /etc/ssh/sshd_config
    echo "ListenAddress 0.0.0.0" >> /etc/ssh/sshd_config
fi
if [ -n "$SSH_PASSWORD" ]; then
    echo "admin:$SSH_PASSWORD" | chpasswd
fi
exec /usr/sbin/sshd -D
EOF

RUN chmod +x /start.sh

# Expose SSH port
EXPOSE 22

# Start SSH service
CMD ["/start.sh"]