#!/bin/bash
set -e  # Exit on any error

# Step 1: Install dependencies
echo "[1/8] Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y wget tar adduser libfontconfig1

# Step 2: Create user and directories
echo "[2/8] Creating Grafana user and directories..."
sudo groupadd -r grafana 2>/dev/null || true
sudo useradd -r -m -s /bin/false -g grafana grafana 2>/dev/null || true
sudo mkdir -p /opt/grafana /var/lib/grafana /var/log/grafana /var/lib/grafana/plugins

# Step 3: Download Grafana
echo "[3/8] Downloading Grafana 11.0.0..."
cd /tmp
wget -q https://dl.grafana.com/oss/release/grafana-11.0.0.linux-amd64.tar.gz

# Step 4: Extract Grafana
echo "[4/8] Extracting Grafana..."
tar -zxf grafana-11.0.0.linux-amd64.tar.gz

# Step 5: Move files to /opt/grafana
echo "[5/8] Moving Grafana files to /opt/grafana..."
sudo cp -r grafana-v11.0.0/* /opt/grafana/

# Step 6: Set permissions
echo "[6/8] Setting permissions..."
sudo chown -R grafana:grafana /opt/grafana /var/lib/grafana /var/log/grafana /var/lib/grafana/plugins

# Step 7: Create systemd service
echo "[7/8] Creating systemd service..."
sudo bash -c "cat > /etc/systemd/system/grafana-server.service <<EOF
[Unit]
Description=Grafana Server
Documentation=https://grafana.com/docs/grafana/latest/
After=network.target

[Service]
Type=simple
User=grafana
Group=grafana
WorkingDirectory=/opt/grafana
ExecStart=/opt/grafana/bin/grafana server --config=/opt/grafana/conf/defaults.ini --homepath=/opt/grafana
Restart=on-failure
LimitNOFILE=10000
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
EOF"

# Step 8: Start Grafana
echo "[8/8] Enabling and starting Grafana..."
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Check status
echo "Checking Grafana service status..."
sudo systemctl status grafana-server --no-pager

echo "✅ Grafana 11.0.0 installed successfully!"
echo "👉 Access it at: http://localhost:3000 or http://<your_server_ip>:3000"
echo "🧑‍💻 Default login: admin / admin"