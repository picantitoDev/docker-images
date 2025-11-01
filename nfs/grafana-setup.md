# Instalar Docker

~~~
# Add Docker's official GPG key:
apt-get update
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
~~~
# Montaje de NFS en Productores y Colector

# NFS Server (Log Producers):

~~~
apt-get update && apt-get install nfs-kernel-server -y
chmod 755 /var/lib/docker
chmod -R o+rx /var/lib/docker/containers
echo "/var/lib/docker/containers 10.10.0.3(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
exportfs -rav
systemctl restart nfs-kernel-server
~~~

# NFS Client (Log Collector) at 10.10.0.3:

~~~
apt update && apt install -y nfs-common
mkdir -p /mnt/proxy-logs/docker
mkdir -p /mnt/app-logs/docker
mkdir -p /mnt/db-logs/docker

mount 10.10.0.1:/var/lib/docker/containers /mnt/proxy-logs/docker
mount 10.20.0.1:/var/lib/docker/containers /mnt/app-logs/docker
mount 10.30.0.1:/var/lib/docker/containers /mnt/db-logs/docker
~~~
## to make it persistent we could do (at the bottom of /etc/fstab):

~~~
10.10.0.1:/var/lib/docker/containers /mnt/proxy-logs/docker nfs defaults 0 0
10.20.0.1:/var/lib/docker/containers /mnt/app-logs/docker nfs defaults 0 0
10.30.0.1:/var/lib/docker/containers /mnt/db-logs/docker nfs defaults 0 0
~~~
# Grafana + Loki

~~~
mkdir grafana
cd grafana
~~~
# Create the following files:
# docker-compose.yml
~~~
name: grafana
services:
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
     - "3000:3000"
    environment:
      - GF_LOG_LEVEL=error
      - GF_AUTH_ANONYMOUS_ENABLED=true
      - GF_SECURITY_ALLOW_EMBEDDING=true
      - GF_SECURITY_ADMIN_PASSWORD=admin # This should be an environment variable later on..
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - loki

  loki:
    image: grafana/loki:3.3.2
    container_name: loki
    restart: unless-stopped
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - loki_data:/loki
      - /root/grafana/loki-config.yaml:/etc/loki/local-config.yaml:ro

volumes:
  grafana_data:
  loki_data:
~~~
# loki-config.yaml

~~~
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9095
  log_level: error

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: loki_index_
        period: 24h

storage_config:
  tsdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/index_cache
    cache_ttl: 24h

limits_config:
  retention_period: 336h  # 14 days
  max_query_lookback: 336h  # 14 days

table_manager:
  retention_deletes_enabled: true
  retention_period: 336h  # 14 days
~~~

# Promtail (docker-compose.yml)

~~~
mkdir /root/promtail
cd /root/promtail
~~~
# Create the following files:

# docker-compose.yml:

~~~
name: promtail

services:
  promtail:
    image: grafana/promtail:3.3.2
    container_name: promtail
    restart: unless-stopped
    command: -config.file=/etc/promtail/config.yaml
    volumes:
      - /root/promtail/promtail-config.yaml:/etc/promtail/config.yaml:ro
      - /root/promtail/positions:/tmp
      - /mnt/proxy-logs/docker:/mnt/proxy-logs/docker:ro
      - /mnt/app-logs/docker:/mnt/app-logs/docker:ro
      - /mnt/db-logs/docker:/mnt/db-logs/docker:ro
    ports:
      - "9080:9080"
~~~

# promtail-config.yaml  

~~~
server:
  http_listen_port: 9080
  grpc_listen_port: 0
positions:
  filename: /tmp/positions.yaml
clients:
  - url: http://10.10.0.2:3100/loki/api/v1/push
scrape_configs:
  - job_name: proxy_docker
    static_configs:
      - targets: ['localhost']
        labels:
          job: proxy_docker
          __path__: /mnt/proxy-logs/docker/*/*-json.log

  - job_name: app_docker
    static_configs:
      - targets: ['localhost']
        labels:
          job: app_docker
          __path__: /mnt/app-logs/docker/*/*-json.log

  - job_name: db_docker
    static_configs:
      - targets: ['localhost']
        labels:
          job: db_docker
          __path__: /mnt/db-logs/docker/*/*-json.log
~~~

# Then run docker container on each producer LXC to test

~~~
docker run -d --name proxy-nginx -p 80:80 nginx:latest


docker run -d --name app-node -p 3000:3000 node:18-alpine sh -c "npm install -g http-server && echo '<h2>App funcionando 🚀</h2>' > index.html && http-server -p 3000"


docker run -d --name db-postgres -p 5432:5432 -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=admin123 -e POSTGRES_DB=testdb postgres:16
~~~
