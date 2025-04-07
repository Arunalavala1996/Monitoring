#!/bin/bash

# Alertmanager version
echo "Installing Alertmanager v0.25.0..."

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y wget tar curl

# Create user and directories
sudo useradd --no-create-home --shell /bin/false alertmanager
sudo mkdir -p /opt/alertmanager
sudo mkdir -p /etc/alertmanager
sudo mkdir -p /var/lib/alertmanager
sudo chown -R alertmanager:alertmanager /opt/alertmanager
sudo chown -R alertmanager:alertmanager /etc/alertmanager
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager

# Download and extract Alertmanager
cd /tmp
wget https://github.com/prometheus/alertmanager/releases/download/v0.25.0/alertmanager-0.25.0.linux-amd64.tar.gz
tar xvf alertmanager-0.25.0.linux-amd64.tar.gz

# Move binaries
sudo mv alertmanager-0.25.0.linux-amd64/alertmanager /opt/alertmanager/
sudo mv alertmanager-0.25.0.linux-amd64/amtool /opt/alertmanager/
sudo chown alertmanager:alertmanager /opt/alertmanager/alertmanager
sudo chown alertmanager:alertmanager /opt/alertmanager/amtool

# Create default config file
sudo tee /etc/alertmanager/alertmanager.yml > /dev/null <<EOF
global:
  resolve_timeout: 5m

route:
  receiver: 'default-receiver'

receivers:
  - name: 'default-receiver'
    email_configs:
      - to: 'youremail@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.example.com:587'
        auth_username: 'smtp_user'
        auth_password: 'smtp_password'
        require_tls: true
EOF

sudo chown alertmanager:alertmanager /etc/alertmanager/alertmanager.yml

# Create systemd service file
sudo tee /etc/systemd/system/alertmanager.service > /dev/null <<EOF
[Unit]
Description=Alertmanager
Documentation=https://prometheus.io/docs/alerting/latest/alertmanager/
After=network.target

[Service]
User=alertmanager
Group=alertmanager
ExecStart=/opt/alertmanager/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/var/lib/alertmanager
Restart=on-failure
LimitNOFILE=10000

[Install]
WantedBy=multi-user.target
EOF

# Start and enable service
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager

# Final status check
sudo systemctl status alertmanager --no-pager

echo "✅ Alertmanager installed and running at http://<YOUR_SERVER_IP>:9093"
