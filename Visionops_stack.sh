#!/bin/bash

# Update package lists
sudo apt-get update -y

# Install necessary packages
sudo apt-get install -y ca-certificates curl git

# Install Docker
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify Docker installation
sudo docker run hello-world

# Install Docker Compose
DOCKER_COMPOSE_PATH="/usr/local/bin/docker-compose"
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o $DOCKER_COMPOSE_PATH
sudo chmod +x $DOCKER_COMPOSE_PATH
docker-compose --version

# Clone or update the Visionops repository
REPO_URL="https://github.com/Kamal-Raj123/Visionops.git"
CLONE_DIR="Visionops"

if [ -d "$CLONE_DIR" ]; then
  echo "📁 Directory $CLONE_DIR already exists. Pulling latest changes..."
  cd "$CLONE_DIR" && git pull || { echo "❌ Git pull failed!"; exit 1; }
else
  echo "🛠️ Cloning repository $REPO_URL..."
  git clone "$REPO_URL" || { echo "❌ Git clone failed!"; exit 1; }
  cd "$CLONE_DIR"
fi

# Get the machine's IP address
HOST_IP=$(hostname -I | awk '{print $1}')
echo "🌐 Host IP detected: $HOST_IP"

# Set the correct path for Prometheus config
PROMETHEUS_CONFIG="/Visionops/prometheus/prometheus.yml"
if [ -f "$PROMETHEUS_CONFIG" ]; then
  echo "⚙️ Updating Prometheus configuration with host IP: $HOST_IP..."
  sed -i "s/localhost/$HOST_IP/g" "$PROMETHEUS_CONFIG"
else
  echo "⚠️ Warning: Prometheus configuration file not found!"
fi

# Set the correct path for docker-compose.yml
COMPOSE_DIR="Docker-compose"
DOCKER_COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"
if [ -f "$DOCKER_COMPOSE_FILE" ]; then
  echo "⚙️ Updating docker-compose.yml with host IP: $HOST_IP..."
  sed -i "s/localhost/$HOST_IP/g" "$DOCKER_COMPOSE_FILE"
else
  echo "⚠️ Warning: docker-compose.yml not found!"
fi

# Start Docker Compose services
echo "🚀 Starting Docker Compose services..."
cd "$COMPOSE_DIR"
docker-compose up -d || { echo "❌ Docker Compose failed to start services!"; exit 1; }

# Verify running Docker containers
echo "✅ Checking running Docker containers..."
docker ps
