#!/bin/bash

# Define the cAdvisor image version
CADVISOR_IMAGE="gcr.io/cadvisor/cadvisor:latest"

# Set a custom node label (modify this per node: master, worker1, worker2, etc.)
NODE_LABEL="worker1"  # Change this per node

# Ensure Docker is running
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed or not running. Please install and start Docker."
    exit 1
fi

# Pull the latest cAdvisor image
echo "Pulling cAdvisor image..."
docker pull $CADVISOR_IMAGE

# Run cAdvisor container as a standalone container
echo "Starting cAdvisor container..."

sudo docker run -d \
  --name=cadvisor \
  --restart=always \
  -p 8080:8080 \
  --net=host \
  -v "/:/rootfs:ro" \
  -v "/var/run:/var/run:ro" \
  -v "/sys:/sys:ro" \
  -v "/var/lib/docker/:/var/lib/docker:ro" \
  $CADVISOR_IMAGE

echo "cAdvisor started successfully on port 8080."
echo "Access the web UI at: http://<NODE_IP>:8080"
echo "Remember to configure Prometheus to scrape metrics from this node!"
