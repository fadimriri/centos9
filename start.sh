#!/bin/bash

# Check if the PORT environment variable is set, default to 22 if not
PORT=${PORT:-22}

# Update SSH configuration to use the assigned port
sed -i "s/^#Port .*/Port $PORT/" /etc/ssh/sshd_config
echo "INFO: SSHD configured to use port $PORT"

# Debugging information for startup
echo "INFO: Starting SSHD on port $PORT"
cat /etc/ssh/sshd_config | grep "Port" > /tmp/startup.log

# Start the SSH daemon in the foreground
exec /usr/sbin/sshd -D
