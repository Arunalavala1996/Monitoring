#!/bin/bash

# Install Loki v2.9.1 on Linux

echo "Updating system..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Installing required dependencies..."
sudo apt-get install -y wget tar curl unzip

echo "Creating Loki user and directories..."
sudo useradd --no-create-home --shell /bin/false loki
sudo mkdir -p /opt/loki
sudo mkdir -p /etc/loki
sudo mkdir -p /var/lib/loki
sudo mkdir -p /var/log/loki
sudo chown -R loki:loki /opt/loki
sudo chown -R loki:loki /etc/loki
sudo chown -R loki:loki /var/lib/loki
sudo chown -R loki:loki /var/log/loki

echo "Downloading Loki..."
cd /tmp
wget https://github.com/grafana/loki/releases/download/v2.9.1/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
chmod +x loki-linux-amd64
sudo mv loki-linux-amd64 /opt/loki/loki
sudo chown loki:loki /opt/loki/loki

echo "Creating default Loki config..."
sudo tee /etc/loki/loki-config.yaml > /dev/null <<EOF
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9095

limits_config:
  max_entries_limit_per_query: 50000
  max_line_size: 1048576

compaction:
  retention_enabled: true
  retention_deletes_enabled: true
  retention_period: 720h

storage_config:
  boltdb_shipper:
    active_index_directory: /var/lib/loki/index
    cache_location: /var/lib/loki/cache
    shared_store: filesystem
  filesystem:
    directory: /var/lib/loki/chunks

table_manager:
  retention_deletes_enabled: true
  retention_period: 720h
EOF

sudo chown loki:loki /etc/loki/loki-config.yaml

echo "Creating systemd service..."
sudo tee /etc/systemd/system/loki.service > /dev/null <<EOF
[Unit]
Description=Loki
Documentation=https://grafana.com/docs/loki/latest/
After=network.target

[Service]
User=loki
Group=loki
ExecStart=/opt/loki/loki -config.file=/etc/loki/loki-config.yaml
Restart=on-failure
LimitNOFILE=10000

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling Loki service..."
sudo systemctl daemon-reload
sudo systemctl enable loki
sudo systemctl start loki

echo "Checking Loki status..."
sudo systemctl status loki --no-pager

echo "✅ Loki installed and running at http://<YOUR_SERVER_IP>:3100"
