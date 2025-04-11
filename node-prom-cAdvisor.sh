#!/bin/bash

# --- Node Exporter ---
echo "Starting Node Exporter container..."
sudo docker run -d \
  --name=node-exporter \
  --restart=always \
  -p 9100:9100 \
  --net=host \
  -v "/proc:/host/proc:ro" \
  -v "/sys:/host/sys:ro" \
  -v "/:/rootfs:ro" \
  prom/node-exporter:latest \
  --path.procfs=/host/proc \
  --path.sysfs=/host/sys \
  --path.rootfs=/rootfs \
  --collector.filesystem.ignored-mount-points "^/(sys|proc|dev|host|etc)($|/)" \
  --collector.textfile.directory=/var/lib/node_exporter/textfile_collector

echo "Node Exporter started on port 9100."

# --- cAdvisor ---
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
  gcr.io/cadvisor/cadvisor:latest

echo "cAdvisor started on port 8080."

# --- Promtail ---
echo "Creating Promtail config..."
mkdir -p /etc/promtail

cat > /etc/promtail/promtail.yaml <<EOF
server:
  http_listen_port: 3101
  grpc_listen_port: 9095

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://10.61.142.66:3100/loki/api/v1/push

scrape_configs:
  - job_name: 'syslog'
    static_configs:
      - targets:
          - localhost
        labels:
          job: 'syslog'
          node: '$(hostname)'
          __path__: /var/log/*.log

  - job_name: 'docker-containers'
    static_configs:
      - targets:
          - localhost
        labels:
          job: 'docker-containers'
          node: '$(hostname)'
          __path__: /var/lib/docker/containers/*/*.log
EOF

echo "Starting Promtail container..."
sudo docker run -d \
  --name=promtail \
  --restart=always \
  -v /var/log:/var/log \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /tmp:/tmp \
  -v /etc/promtail/promtail.yaml:/etc/promtail/promtail.yaml \
  grafana/promtail:latest \
  -config.file=/etc/promtail/promtail.yaml

echo "Promtail container started."
echo "All containers started successfully."
echo "Node Exporter, cAdvisor, and Promtail are now running."