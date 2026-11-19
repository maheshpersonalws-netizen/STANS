#!/usr/bin/env bash
# ==============================================================================
# STANS Production Server Setup Script (Ubuntu / Debian)
# Usage: sudo bash setup-server.sh
# ==============================================================================

set -euo pipefail

echo "=================================================="
echo " Starting STANS Server Provisioning"
echo "=================================================="

# 1. Update and Upgrade System Packages
echo "--> Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y ca-certificates curl gnupg lsb-release ufw nginx certbot python3-certbot-nginx

# 2. Install Docker Engine and Docker Compose Plugin
echo "--> Installing Docker Engine..."
if ! command -v docker &> /dev/null; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

# 3. Configure UFW Firewall (Allow only ports 22, 80, 443)
echo "--> Configuring UFW Firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable
echo "Firewall rules applied. Allowed ports: 22 (SSH), 80 (HTTP), 443 (HTTPS)."

# 4. Prepare App Directory
APP_DIR="/opt/stans"
mkdir -p "$APP_DIR"
echo "Application directory created at $APP_DIR"

echo "=================================================="
echo " Server Setup Complete!"
echo " Next Steps:"
echo " 1. Configure Host Nginx: copy host-nginx.conf to /etc/nginx/sites-available/stans.conf"
echo " 2. Run Certbot to generate SSL certificates: certbot --nginx -d your-domain.com"
echo " 3. Launch STANS container: docker run -d --name stans-app --restart=always -p 8080:80 <image-name>"
echo "=================================================="
