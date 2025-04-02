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

# Check for compose files (all common variants)
echo "Checking for compose files in /stacks..."
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
    echo "Supported filenames: docker-compose.yaml, docker-compose.yml, compose.yaml, compose.yml"
    exit 1
fi

# Start Docker containers
echo "Starting Docker containers in /stacks..."
cd /stacks || exit 1
docker compose up -d

# UFW Configuration
echo "Would you like to configure UFW firewall rules? (y/n)"
read -r configure_ufw

if [ "$configure_ufw" = "y" ] || [ "$configure_ufw" = "Y" ]; then
    echo "Available ports to enable:"
    echo "1) HTTP (80/tcp)"
    echo "2) HTTPS (443/tcp)"
    echo "3) Beszel Agent (45876/tcp)"
    echo "4) Radarr (7878/tcp)"
    echo "5) Sonarr (8989/tcp)"
    echo "6) Prowlarr (9696/tcp)"
    echo "7) Sabnzbd (8080/tcp)"
    echo "8) qBittorrent (8181/tcp)"
    echo ""
    echo "Enter port numbers to enable (space-separated, e.g., 1 2 3):"
    read -r selected_ports
    
    for port in $selected_ports; do
        case $port in
            1) ufw allow http ;;
            2) ufw allow https ;;
            3) ufw allow 45876/tcp ;;
            4) ufw allow 7878/tcp ;;
            5) ufw allow 8989/tcp ;;
            6) ufw allow 9696/tcp ;;
            7) ufw allow 8080/tcp ;;
            8) ufw allow 8181/tcp ;;
            *) echo "Invalid option: $port - skipping" ;;
        esac
    done
    
    echo "Enabling UFW..."
    ufw enable
else
    echo "Skipping UFW configuration."
fi

echo "Setup completed successfully!"