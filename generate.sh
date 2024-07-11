#!/usr/bin/bash
podman volume create nc-pgdata
podman volume create nc-redisdata
podman volume create nc-html
podman volume create nc-caddydata
podman pod create --restart no --name nc -p 8080:8080/tcp
# PostgreSQL
podman run -d --pod nc --name postgres \
  -e TZ=Asia/Tokyo \
  -e POSTGRES_DB=nextcloud \
  -e POSTGRES_USER=nextcloud \
  -e POSTGRES_PASSWORD=nextcloud \
  -v nc-pgdata:/var/lib/postgresql/data \
  docker.io/library/postgres:latest
# Redis
podman run -d --pod nc --name redis \
  -v nc-redisdata:/data \
  docker.io/library/redis:latest
# NextCloud
podman run -d --pod nc --name nextcloud \
  -e REDIS_HOST=localhost \
  -v nc-html:/var/www/html \
  docker.io/library/nextcloud:latest
# Caddy
podman run -d --pod nc --name caddy \
  -v ./caddy/Caddyfile:/etc/caddy/Caddyfile \
  -v nc-caddydata:/data \
  -v nc-html:/var/www/html \
  docker.io/library/caddy:latest
# Generate k8s YAML
podman generate kube nc > nc.yml
echo "Wait 10 sec. for the containers to start."
sleep 10
# Setup
# see: https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#command-line-installation
# see: https://denor.jp/%E3%81%8A%E3%81%86%E3%81%A1lan%E5%86%85%E3%81%AEnextcloud%E3%82%B5%E3%83%BC%E3%83%90%E3%82%92ssl%E8%87%AA%E5%8B%95%E6%9B%B4%E6%96%B0%E3%81%AEcaddy%E3%81%A7%E3%83%9B%E3%82%B9%E3%83%86%E3%82%A3%E3%83%B3
podman exec -it -u www-data nextcloud ./occ maintenance:install --database="pgsql" \
	--database-name="nextcloud" --database-user="nextcloud" --database-pass="nextcloud"
podman exec -it -u www-data nextcloud ./occ config:system:set overwritehost --value="localhost:8080"
podman exec -it -u www-data nextcloud ./occ config:system:set overwriteprotocol --value="http"
podman exec -it -u www-data nextcloud ./occ config:system:set overwritewebroot --value="/nextcloud"
podman exec -it -u www-data nextcloud ./occ config:system:set overwritecondaddr --value="^localhost:8080$"
podman exec -it -u www-data nextcloud ./occ config:system:set overwrite.cli.url --value="http://localhost:8080"
podman exec -it -u www-data nextcloud ./occ config:system:set trusted_proxies 0 --value="localhost"
podman exec -it -u www-data nextcloud ./occ db:add-missing-indices
## Cleanup
podman pod rm -f nc
echo "Let's play the pod."
echo ""
echo "$ podman kube play nc.yml"
