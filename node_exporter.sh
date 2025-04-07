#!/bin/bash

# Define the Node Exporter image version
NODE_EXPORTER_IMAGE="prom/node-exporter:latest"

# Set a custom node label (modify this per node: master, worker1, worker2, etc.)
NODE_LABEL="worker1"  # Change this per node

# Ensure Docker is running
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed or not running. Please install and start Docker."
    exit 1
fi

# Pull the latest Node Exporter image
echo "Pulling Node Exporter image..."
docker pull $NODE_EXPORTER_IMAGE

# Run Node Exporter container as a standalone container
echo "Starting Node Exporter container..."

sudo docker run -d \
  --name=node-exporter \
  --restart=always \
  -p 9100:9100 \
  --net=host \
  -v "/proc:/host/proc:ro" \
  -v "/sys:/host/sys:ro" \
  -v "/:/rootfs:ro" \
  $NODE_EXPORTER_IMAGE \
  --path.procfs=/host/proc \
  --path.sysfs=/host/sys \
  --path.rootfs=/rootfs \
  --collector.filesystem.ignored-mount-points "^/(sys|proc|dev|host|etc)($|/)" \
  --collector.textfile.directory=/var/lib/node_exporter/textfile_collector

echo "Node Exporter started successfully on port 9100."
echo "Remember to configure Prometheus to scrape metrics from this node!"
