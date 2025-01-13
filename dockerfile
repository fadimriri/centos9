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

# Create startup script
RUN echo '#!/bin/bash\n\
if [ -n "$PORT" ]; then\n\
    sed -i "s/#Port 22/Port $PORT/" /etc/ssh/sshd_config\n\
fi\n\
if [ -n "$SSH_PASSWORD" ]; then\n\
    echo "admin:$SSH_PASSWORD" | chpasswd\n\
fi\n\
exec /usr/sbin/sshd -D\n\
' > /start.sh && chmod +x /start.sh

# Expose default SSH port (Railway will override this with $PORT)
EXPOSE 22

# Start SSH service using the startup script
CMD ["/start.sh"]