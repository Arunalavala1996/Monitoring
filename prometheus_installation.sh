#!/bin/bash

# Define Prometheus version (change if you need a different version)
PROMETHEUS_VERSION="3.2.1"

# Define Prometheus user and directories
PROMETHEUS_USER="prometheus"
PROMETHEUS_DIR="/opt/prometheus"
PROMETHEUS_CONFIG_DIR="/etc/prometheus"
PROMETHEUS_DATA_DIR="/var/lib/prometheus"

# Ensure the system is up-to-date
echo "Updating system..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Install required dependencies
echo "Installing required dependencies..."
sudo apt-get install -y wget tar curl

# Create Prometheus user and directories
echo "Creating Prometheus user and directories..."
sudo useradd --no-create-home --shell /bin/false $PROMETHEUS_USER
sudo mkdir -p $PROMETHEUS_DIR
sudo mkdir -p $PROMETHEUS_CONFIG_DIR
sudo mkdir -p $PROMETHEUS_DATA_DIR
sudo chown -R $PROMETHEUS_USER:$PROMETHEUS_USER $PROMETHEUS_DIR
sudo chown -R $PROMETHEUS_USER:$PROMETHEUS_USER $PROMETHEUS_CONFIG_DIR
sudo chown -R $PROMETHEUS_USER:$PROMETHEUS_USER $PROMETHEUS_DATA_DIR

# Download and extract Prometheus
echo "Downloading Prometheus version $PROMETHEUS_VERSION..."
cd /tmp
wget "https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz"
tar xvf "prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz"

# Move Prometheus binaries to the installation directory
echo "Moving Prometheus binaries..."
sudo mv "prometheus-$PROMETHEUS_VERSION.linux-amd64/prometheus" $PROMETHEUS_DIR/
sudo mv "prometheus-$PROMETHEUS_VERSION.linux-amd64/promtool" $PROMETHEUS_DIR/

# Copy the Prometheus configuration
echo "Copying Prometheus configuration..."
sudo cp "prometheus-$PROMETHEUS_VERSION.linux-amd64/prometheus.yml" $PROMETHEUS_CONFIG_DIR/

# Create systemd service file for Prometheus
echo "Creating Prometheus systemd service..."
sudo bash -c 'cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
After=network.target

[Service]
User=prometheus
Group=prometheus
ExecStart=/opt/prometheus/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus/

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd to recognize the new service
echo "Reloading systemd..."
sudo systemctl daemon-reload

# Enable and start Prometheus service
echo "Starting Prometheus service..."
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Check if Prometheus is running
echo "Checking Prometheus status..."
sudo systemctl status prometheus

echo "Prometheus installation complete. You can access it at http://<YOUR_SERVER_IP>:9090"
