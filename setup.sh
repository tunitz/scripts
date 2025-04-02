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

# UFW Configuration (Fixed quotes)
echo "Would you like to configure UFW firewall rules? (y/n)"
read -r configure_ufw

if [ "$configure_ufw" = "y" ] || [ "$configure_ufw" = "Y" ]; then
    echo "Available ports:"
    echo "1) HTTP (80/tcp)"
    echo "2) HTTPS (443/tcp)"
    echo "3) 45876/tcp (Beszel)"
    echo "4) 7878/tcp (Radarr)"
    echo "5) 8989/tcp (Sonarr)"
    echo "6) 9696/tcp (Prowlarr)"
    echo "7) 8080/tcp (Sabnzbd)"
    echo "8) 8181/tcp (qBittorrent)"
    echo ""
    echo "Enter numbers to enable (space-separated):"
    read -r selected_ports

    for port in $selected_ports; do
        case "$port" in
            1) ufw allow http ;;
            2) ufw allow https ;;
            3) ufw allow 45876/tcp ;;
            4) ufw allow 7878/tcp ;;
            5) ufw allow 8989/tcp ;;
            6) ufw allow 9696/tcp ;;
            7) ufw allow 8080/tcp ;;
            8) ufw allow 8181/tcp ;;
            *) echo "Skipping invalid option: $port" ;;
        esac
    done

    echo "Enabling UFW..."
    ufw enable
else
    echo "Skipping UFW configuration."
fi

echo "Setup complete!"