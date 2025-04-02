#!/bin/sh

# Update and install packages
echo "Updating packages and installing Docker..."
apk update
apk add docker docker-compose ufw

# Start and enable Docker
echo "Configuring Docker..."
rc-update add docker default
service docker start

# Check for /stacks directory
echo "Checking for /stacks directory..."
if [ ! -d "/stacks" ]; then
    echo "Error: /stacks directory does not exist!"
    exit 1
fi

# Check for compose files
echo "Checking for compose files..."
COMPOSE_FILES="
/stacks/docker-compose.yaml
/stacks/docker-compose.yml
/stacks/compose.yaml
/stacks/compose.yml
"

found=0
for file in $COMPOSE_FILES; do
    if [ -f "$file" ]; then
        echo "Found compose file: $file"
        found=1
        break
    fi
done

if [ "$found" -eq 0 ]; then
    echo "Error: No compose file found in /stacks!"
    exit 1
fi

# Start containers
echo "Starting containers..."
cd /stacks || exit 1
docker compose up -d

# UFW Configuration with reliable input handling
echo "Setting allowed ports in UFW"
ufw allow http
echo "Port 80/tcp allowed"
ufw allow 45876/tcp
echo "Port 45876/tcp allowed"

echo "Starting ufw..."
ufw enable

echo "Setup complete!"
