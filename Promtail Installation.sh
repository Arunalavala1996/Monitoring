#!/bin/bash

# Define the Promtail image version
PROMTAIL_IMAGE="grafana/promtail:latest"

# Define the Promtail configuration path
PROMTAIL_CONFIG_PATH="/etc/promtail/promtail.yaml"

# Set a custom node label (modify this per node: master, worker1, worker2, etc.)
NODE_LABEL="worker1"  # Change this per node

# Ensure the /etc/promtail directory exists
if [ ! -d "/etc/promtail" ]; then
  echo "Creating /etc/promtail directory..."
  mkdir -p /etc/promtail
fi

# Pull the latest Promtail image
echo "Pulling Promtail image..."
docker pull $PROMTAIL_IMAGE

# Create the Promtail configuration file
echo "Creating Promtail configuration file at $PROMTAIL_CONFIG_PATH..."

cat > etc/promtail/promtail.yaml <<EOF
server:
  http_listen_port: 3101
  grpc_listen_port: 9095

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://<LOKI_IP>:3100/loki/api/v1/push  # Replace <LOKI_IP> with actual Loki IP

scrape_configs:
  - job_name: 'syslog'
    static_configs:
      - targets:
          - localhost
        labels:
          job: 'syslog'
          node: '$NODE_LABEL'
          __path__: /var/log/*.log

  - job_name: 'docker-containers'
    static_configs:
      - targets:
          - localhost
        labels:
          job: 'docker-containers'
          node: '$NODE_LABEL'
          __path__: /var/lib/docker/containers/*/*.log
EOF

echo "Promtail configuration file created successfully."

# Run the Promtail container as a standalone container
echo "Starting Promtail container..."

sudo docker run -d \
  --name=promtail \
  --restart=always \
  -v /var/log:/var/log \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /tmp:/tmp \
  -v /etc/promtail/promtail.yaml:/etc/promtail/promtail.yaml \
  $PROMTAIL_IMAGE \
  -config.file=/etc/promtail/promtail.yaml

echo "Promtail container started successfully."
echo "Remember to update the Loki IP in the config file!"
