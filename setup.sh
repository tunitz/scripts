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

# UFW Configuration with improved input handling
echo "Would you like to configure UFW firewall rules? (y/n)"
read -r configure_ufw

# Convert to lowercase
configure_ufw=$(echo "$configure_ufw" | tr '[:upper:]' '[:lower:]')

if [ "$configure_ufw" = "y" ]; then
    # Display menu
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
    
    # Input validation loop
    while true; do
        printf "Enter port numbers to enable (space-separated): "
        read -r selected_ports
        
        # Check if input is empty
        if [ -z "$selected_ports" ]; then
            echo "No ports selected. Skipping UFW configuration."
            break
        fi
        
        # Process each port
        invalid=0
        for port in $selected_ports; do
            case "$port" in
                1) 
                    ufw allow http
                    echo "Enabled HTTP (80/tcp)"
                    ;;
                2) 
                    ufw allow https
                    echo "Enabled HTTPS (443/tcp)"
                    ;;
                3) 
                    ufw allow 45876/tcp
                    echo "Enabled 45876/tcp (Beszel Agent)"
                    ;;
                4) 
                    ufw allow 7878/tcp
                    echo "Enabled 7878/tcp (Radarr)"
                    ;;
                5) 
                    ufw allow 8989/tcp
                    echo "Enabled 8989/tcp (Sonarr)"
                    ;;
                6) 
                    ufw allow 9696/tcp
                    echo "Enabled 9696/tcp (Prowlarr)"
                    ;;
                7) 
                    ufw allow 8080/tcp
                    echo "Enabled 8080/tcp (Sabnzbd)"
                    ;;
                8) 
                    ufw allow 8181/tcp
                    echo "Enabled 8181/tcp (qBittorrent)"
                    ;;
                *) 
                    echo "Invalid option: $port"
                    invalid=1
                    ;;
            esac
        done
        
        # Exit loop if all ports were valid
        [ "$invalid" -eq 0 ] && break
        
        echo "Please try again with valid port numbers (1-8)"
    done
    
    # Only enable UFW if rules were added
    if [ -n "$selected_ports" ]; then
        echo "Enabling UFW..."
        ufw --force enable
    fi
else
    echo "Skipping UFW configuration."
fi

echo "Setup complete!"