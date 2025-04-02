#!/bin/sh

# Update and install packages
echo "Updating packages and installing Docker..."
apk update
apk add docker docker-compose ufw

# Start and enable Docker
echo "Configuring Docker..."
rc-update add docker default
/etc/init.d/docker start

# Check for /stacks directory and docker-compose.yaml
echo "Checking for /stacks directory..."
if [ ! -d "/stacks" ]; then
    echo "Error: /stacks directory does not exist!"
    exit 1
fi

echo "Checking for docker-compose.yaml in /stacks..."
if [ ! -f "/stacks/docker-compose.yaml" ] && [ ! -f "/stacks/docker-compose.yml" ]; then
    echo "Error: No docker-compose.yaml or docker-compose.yml found in /stacks!"
    exit 1
fi

# Start Docker containers
echo "Starting Docker containers in /stacks..."
cd /stacks
docker compose up -d

# Function to check if a port is already allowed in UFW
is_port_allowed() {
    port_rule="$1"
    if ufw status | grep -q "$port_rule"; then
        return 0  # Port is allowed
    else
        return 1  # Port is not allowed
    fi
}

# Optional UFW configuration
echo "Would you like to configure UFW firewall rules? (y/n)"
read -r configure_ufw

if [ "$configure_ufw" = "y" ] || [ "$configure_ufw" = "Y" ]; then
    echo "The following ports are available for enabling:"
    echo "1) HTTP (80/tcp) $(is_port_allowed '80/tcp' && echo '✅')"
    echo "2) HTTPS (443/tcp) $(is_port_allowed '443/tcp' && echo '✅')"
    echo "3) Beszel Agent (45876/tcp) $(is_port_allowed '45876/tcp' && echo '✅')"
    echo "4) Radarr (7878/tcp) $(is_port_allowed '7878/tcp' && echo '✅')"
    echo "5) Sonarr (8989/tcp) $(is_port_allowed '8989/tcp' && echo '✅')"
    echo "6) Prowlarr (9696/tcp) $(is_port_allowed '9696/tcp' && echo '✅')"
    echo "7) Sabnzbd (8080/tcp) $(is_port_allowed '8080/tcp' && echo '✅')"
    echo "8) qBittorrent (8181/tcp) $(is_port_allowed '8181/tcp' && echo '✅')"
    echo ""
    echo "Enter the numbers of the ports you want to enable, separated by spaces (e.g., 1 2 3):"
    read -r selected_ports
    
    # Process selected ports
    for port in $selected_ports; do
        case $port in
            1) 
                if ! is_port_allowed '80/tcp'; then
                    ufw allow http
                else
                    echo "HTTP (80/tcp) is already allowed."
                fi
                ;;
            2) 
                if ! is_port_allowed '443/tcp'; then
                    ufw allow https
                else
                    echo "HTTPS (443/tcp) is already allowed."
                fi
                ;;
            3) 
                if ! is_port_allowed '45876/tcp'; then
                    ufw allow 45876/tcp
                else
                    echo "45876/tcp (Beszel Agent) is already allowed."
                fi
                ;;
            4) 
                if ! is_port_allowed '7878/tcp'; then
                    ufw allow 7878/tcp
                else
                    echo "7878/tcp (Radarr) is already allowed."
                fi
                ;;
            5) 
                if ! is_port_allowed '8989/tcp'; then
                    ufw allow 8989/tcp
                else
                    echo "8989/tcp (Sonarr) is already allowed."
                fi
                ;;
            6) 
                if ! is_port_allowed '9696/tcp'; then
                    ufw allow 9696/tcp
                else
                    echo "9696/tcp (Prowlarr) is already allowed."
                fi
                ;;
            7) 
                if ! is_port_allowed '8080/tcp'; then
                    ufw allow 8080/tcp
                else
                    echo "8080/tcp (Sabnzbd) is already allowed."
                fi
                ;;
            8) 
                if ! is_port_allowed '8181/tcp'; then
                    ufw allow 8181/tcp
                else
                    echo "8181/tcp (qBittorrent) is already allowed."
                fi
                ;;
            *) echo "Invalid option: $port - skipping" ;;
        esac
    done
    
    # Enable UFW (if not already enabled)
    if ufw status | grep -q "Status: inactive"; then
        echo "Enabling UFW..."
        ufw enable
    else
        echo "UFW is already enabled."
    fi
else
    echo "Skipping UFW configuration."
fi

echo "Setup completed!"