#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo bash scripts/setup.sh" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
ENV_EXAMPLE_FILE="${ROOT_DIR}/.env.example"
SUMMARY_FILE="${ROOT_DIR}/INSTALL_SUMMARY.txt"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
cat << "EOF"
╺━┓╻┏━┓┏━┓┏━╸   ╻┏━┓╺┳╸   ╻ ╻   ┏━╸╻  ┏━┓╻ ╻╺┳┓
┏━┛┃┗━┓╺━┫┃     ┃┃ ┃ ┃    ┏╋┛   ┃  ┃  ┃ ┃┃ ┃ ┃┃
┗━╸╹┗━┛┗━┛┗━╸   ╹┗━┛ ╹    ╹ ╹   ┗━╸┗━╸┗━┛┗━┛╺┻┛
EOF
echo -e "${NC}"
echo -e "${BLUE}>>> Initializing Basic IoT Cloud Setup...${NC}\n"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  docker.io \
  docker-compose-v2 \
  apache2-utils \
  openssl \
  python3 \
  ufw

systemctl enable --now docker

ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 1883/tcp
ufw --force enable

docker network create iotnetwork >/dev/null 2>&1 || true

if [[ ! -f "${ENV_FILE}" ]]; then
  cp "${ENV_EXAMPLE_FILE}" "${ENV_FILE}"
fi

read -r -p "DuckDNS subdomain prefix (example: team-iot): " DUCKDNS_SUBDOMAIN
DUCKDNS_SUBDOMAIN="${DUCKDNS_SUBDOMAIN,,}"
while [[ ! "${DUCKDNS_SUBDOMAIN}" =~ ^[a-z0-9-]+$ ]]; do
  read -r -p "Use only lowercase letters, numbers, and '-'. Try again: " DUCKDNS_SUBDOMAIN
  DUCKDNS_SUBDOMAIN="${DUCKDNS_SUBDOMAIN,,}"
done

read -r -s -p "DuckDNS token: " DUCKDNS_TOKEN
echo
while [[ -z "${DUCKDNS_TOKEN}" ]]; do
  read -r -s -p "DuckDNS token cannot be empty. Enter again: " DUCKDNS_TOKEN
  echo
done

read -r -p "Let's Encrypt email: " LETSENCRYPT_EMAIL
while [[ -z "${LETSENCRYPT_EMAIL}" ]]; do
  read -r -p "Email cannot be empty. Enter again: " LETSENCRYPT_EMAIL
done

gen_password() {
  openssl rand -base64 24 | tr -d '\n' | tr '/+' 'AB' | cut -c1-24
}

DOMAIN="${DUCKDNS_SUBDOMAIN}.duckdns.org"
TRAEFIK_SUBDOMAIN="traefik"
PORTAINER_SUBDOMAIN="ops"
NODERED_SUBDOMAIN="nodered"
INFLUXDB_SUBDOMAIN="influx"
GRAFANA_SUBDOMAIN="dash"
ADMINER_SUBDOMAIN="adminer"

INFLUXDB_ORG="iot-org"
INFLUXDB_BUCKET="iot"
INFLUXDB_ADMIN_USER="admin"
INFLUXDB_ADMIN_PASSWORD="$(gen_password)"
INFLUXDB_ADMIN_TOKEN="$(openssl rand -hex 32)"
GRAFANA_ADMIN_PASSWORD="$(gen_password)"
PORTAINER_ADMIN_PASSWORD="$(gen_password)"
MARIADB_ROOT_PASSWORD="$(gen_password)"
MARIADB_DATABASE="iot"
MARIADB_USER="iot"
MARIADB_PASSWORD="$(gen_password)"

MQTT_DEVICE_USER="esp32dht"
MQTT_DEVICE_PASSWORD="$(gen_password)"
MQTT_NODERED_USER="nodered"
MQTT_NODERED_PASSWORD="$(gen_password)"
MQTT_IOTUSER="iotuser"
MQTT_IOTUSER_PASSWORD="$(gen_password)"

TRAEFIK_ADMIN_USER="admin"
TRAEFIK_ADMIN_PASSWORD="$(gen_password)"
NODERED_BASIC_AUTH_USER="nodered"
NODERED_BASIC_AUTH_PASSWORD="$(gen_password)"

export DOMAIN TRAEFIK_SUBDOMAIN PORTAINER_SUBDOMAIN NODERED_SUBDOMAIN INFLUXDB_SUBDOMAIN GRAFANA_SUBDOMAIN ADMINER_SUBDOMAIN
export DUCKDNS_SUBDOMAIN DUCKDNS_TOKEN LETSENCRYPT_EMAIL
export INFLUXDB_ORG INFLUXDB_BUCKET INFLUXDB_ADMIN_USER INFLUXDB_ADMIN_PASSWORD INFLUXDB_ADMIN_TOKEN GRAFANA_ADMIN_PASSWORD
export MARIADB_ROOT_PASSWORD MARIADB_DATABASE MARIADB_USER MARIADB_PASSWORD
export MQTT_DEVICE_USER MQTT_DEVICE_PASSWORD MQTT_NODERED_USER MQTT_NODERED_PASSWORD MQTT_IOTUSER MQTT_IOTUSER_PASSWORD

python3 - "${ENV_FILE}" <<'PY'
from pathlib import Path
import os
import sys

env_path = Path(sys.argv[1])
lines = env_path.read_text().splitlines()

updates = {
    "DOMAIN": os.environ["DOMAIN"],
    "LETSENCRYPT_EMAIL": os.environ["LETSENCRYPT_EMAIL"],
    "TRAEFIK_SUBDOMAIN": os.environ["TRAEFIK_SUBDOMAIN"],
    "PORTAINER_SUBDOMAIN": os.environ["PORTAINER_SUBDOMAIN"],
    "NODERED_SUBDOMAIN": os.environ["NODERED_SUBDOMAIN"],
    "INFLUXDB_SUBDOMAIN": os.environ["INFLUXDB_SUBDOMAIN"],
    "GRAFANA_SUBDOMAIN": os.environ["GRAFANA_SUBDOMAIN"],
    "ADMINER_SUBDOMAIN": os.environ["ADMINER_SUBDOMAIN"],
    "DUCKDNS_SUBDOMAINS": os.environ["DUCKDNS_SUBDOMAIN"],
    "DUCKDNS_TOKEN": os.environ["DUCKDNS_TOKEN"],
    "INFLUXDB_ORG": os.environ["INFLUXDB_ORG"],
    "INFLUXDB_BUCKET": os.environ["INFLUXDB_BUCKET"],
    "INFLUXDB_ADMIN_USER": os.environ["INFLUXDB_ADMIN_USER"],
    "INFLUXDB_ADMIN_PASSWORD": os.environ["INFLUXDB_ADMIN_PASSWORD"],
    "INFLUXDB_ADMIN_TOKEN": os.environ["INFLUXDB_ADMIN_TOKEN"],
    "GRAFANA_ADMIN_PASSWORD": os.environ["GRAFANA_ADMIN_PASSWORD"],
    "MARIADB_ROOT_PASSWORD": os.environ["MARIADB_ROOT_PASSWORD"],
    "MARIADB_DATABASE": os.environ["MARIADB_DATABASE"],
    "MARIADB_USER": os.environ["MARIADB_USER"],
    "MARIADB_PASSWORD": os.environ["MARIADB_PASSWORD"],
    "MQTT_DEVICE_USER": os.environ["MQTT_DEVICE_USER"],
    "MQTT_DEVICE_PASSWORD": os.environ["MQTT_DEVICE_PASSWORD"],
    "MQTT_NODERED_USER": os.environ["MQTT_NODERED_USER"],
    "MQTT_NODERED_PASSWORD": os.environ["MQTT_NODERED_PASSWORD"],
    "MQTT_IOTUSER": os.environ["MQTT_IOTUSER"],
    "MQTT_IOTUSER_PASSWORD": os.environ["MQTT_IOTUSER_PASSWORD"],
}

found = set()
new_lines = []
for line in lines:
    if "=" in line and not line.startswith("#"):
        key = line.split("=", 1)[0]
        if key in updates:
            new_lines.append(f"{key}={updates[key]}")
            found.add(key)
            continue
    new_lines.append(line)

for key, value in updates.items():
    if key not in found:
        new_lines.append(f"{key}={value}")

env_path.write_text("\n".join(new_lines) + "\n")
PY

mkdir -p \
  "${ROOT_DIR}/traefik/auth" \
  "${ROOT_DIR}/data/traefik/letsencrypt" \
  "${ROOT_DIR}/data/grafana" \
  "${ROOT_DIR}/data/portainer" \
  "${ROOT_DIR}/data/node-red" \
  "${ROOT_DIR}/data/influxdb" \
  "${ROOT_DIR}/data/influxdb-config" \
  "${ROOT_DIR}/data/mosquitto/data" \
  "${ROOT_DIR}/data/mosquitto/log" \
  "${ROOT_DIR}/data/mariadb" \
  "${ROOT_DIR}/backups" \
  "${ROOT_DIR}/landing"

touch "${ROOT_DIR}/data/traefik/letsencrypt/acme.json"
chmod 600 "${ROOT_DIR}/data/traefik/letsencrypt/acme.json"
chown -R 472:472 "${ROOT_DIR}/data/grafana"
chown -R 1883:1883 "${ROOT_DIR}/data/mosquitto/data" "${ROOT_DIR}/data/mosquitto/log"

htpasswd -nbB "${TRAEFIK_ADMIN_USER}" "${TRAEFIK_ADMIN_PASSWORD}" > "${ROOT_DIR}/traefik/auth/users"
htpasswd -nbB "${NODERED_BASIC_AUTH_USER}" "${NODERED_BASIC_AUTH_PASSWORD}" >> "${ROOT_DIR}/traefik/auth/users"
chmod 640 "${ROOT_DIR}/traefik/auth/users"

cat > "${ROOT_DIR}/traefik/dynamic.yml" <<EOF
http:
  routers:
    traefik:
      rule: Host(\`${TRAEFIK_SUBDOMAIN}.${DOMAIN}\`)
      entryPoints: [websecure]
      tls:
        certResolver: le
      service: api@internal
      middlewares: [traefik-auth]

    nodered:
      rule: Host(\`${NODERED_SUBDOMAIN}.${DOMAIN}\`)
      entryPoints: [websecure]
      tls:
        certResolver: le
      service: nodered
      middlewares: [nodered-auth]

    influxdb:
      rule: Host(\`${INFLUXDB_SUBDOMAIN}.${DOMAIN}\`)
      entryPoints: [websecure]
      tls:
        certResolver: le
      service: influxdb

    grafana:
      rule: Host(\`${GRAFANA_SUBDOMAIN}.${DOMAIN}\`)
      entryPoints: [websecure]
      tls:
        certResolver: le
      service: grafana

    portainer:
      rule: Host(\`${PORTAINER_SUBDOMAIN}.${DOMAIN}\`)
      entryPoints: [websecure]
      tls:
        certResolver: le
      service: portainer

    adminer:
      rule: Host(\`${ADMINER_SUBDOMAIN}.${DOMAIN}\`)
      entryPoints: [websecure]
      tls:
        certResolver: le
      service: adminer

  middlewares:
    traefik-auth:
      basicAuth:
        usersFile: /auth/users
    nodered-auth:
      basicAuth:
        usersFile: /auth/users

  services:
    nodered:
      loadBalancer:
        servers:
          - url: http://node-red:1880
    influxdb:
      loadBalancer:
        servers:
          - url: http://influxdb:8086
    grafana:
      loadBalancer:
        servers:
          - url: http://grafana:3000
    portainer:
      loadBalancer:
        servers:
          - url: http://portainer:9000
    adminer:
      loadBalancer:
        servers:
          - url: http://adminer:8080
EOF

sed -i "s/{{DOMAIN}}/${DOMAIN}/g" "${ROOT_DIR}/landing/index.html" || true

cat > "${ROOT_DIR}/mosquitto/config/mosquitto.conf" <<'EOF'
listener 1883
allow_anonymous false
password_file /mosquitto/config/pwfile
acl_file /mosquitto/config/aclfile

persistence true
persistence_location /mosquitto/data/

log_dest file /mosquitto/log/mosquitto.log
EOF

cat > "${ROOT_DIR}/mosquitto/config/aclfile" <<EOF
user ${MQTT_DEVICE_USER}
topic write iot/dht11

user ${MQTT_NODERED_USER}
topic read iot/dht11

user ${MQTT_IOTUSER}
topic readwrite iot/#
EOF

docker run --rm -v "${ROOT_DIR}/mosquitto/config:/mosquitto/config" eclipse-mosquitto:2 \
  mosquitto_passwd -b -c /mosquitto/config/pwfile "${MQTT_DEVICE_USER}" "${MQTT_DEVICE_PASSWORD}" >/dev/null
docker run --rm -v "${ROOT_DIR}/mosquitto/config:/mosquitto/config" eclipse-mosquitto:2 \
  mosquitto_passwd -b /mosquitto/config/pwfile "${MQTT_NODERED_USER}" "${MQTT_NODERED_PASSWORD}" >/dev/null
docker run --rm -v "${ROOT_DIR}/mosquitto/config:/mosquitto/config" eclipse-mosquitto:2 \
  mosquitto_passwd -b /mosquitto/config/pwfile "${MQTT_IOTUSER}" "${MQTT_IOTUSER_PASSWORD}" >/dev/null

chmod +x "${ROOT_DIR}/scripts/"*.sh

cd "${ROOT_DIR}"
docker compose pull traefik duckdns mosquitto node-red influxdb grafana portainer
docker compose up -d traefik duckdns mosquitto node-red influxdb grafana portainer
sleep 5
docker compose stop portainer
docker run --rm -v "${ROOT_DIR}/data/portainer:/data" portainer/helper-reset-password \
  --password "${PORTAINER_ADMIN_PASSWORD}" >/dev/null
docker compose up -d portainer

cat > "${SUMMARY_FILE}" <<EOF
IoT stack setup complete
Generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

URLs
- Traefik: https://${TRAEFIK_SUBDOMAIN}.${DOMAIN}
- Node-RED: https://${NODERED_SUBDOMAIN}.${DOMAIN}
- InfluxDB: https://${INFLUXDB_SUBDOMAIN}.${DOMAIN}
- Grafana: https://${GRAFANA_SUBDOMAIN}.${DOMAIN}
- Portainer: https://${PORTAINER_SUBDOMAIN}.${DOMAIN}
- Adminer: https://${ADMINER_SUBDOMAIN}.${DOMAIN}

Credentials
- Traefik basic auth user: ${TRAEFIK_ADMIN_USER}
- Traefik basic auth password: ${TRAEFIK_ADMIN_PASSWORD}
- Node-RED basic auth user: ${NODERED_BASIC_AUTH_USER}
- Node-RED basic auth password: ${NODERED_BASIC_AUTH_PASSWORD}
- Grafana user: admin
- Grafana password: ${GRAFANA_ADMIN_PASSWORD}
- InfluxDB user: ${INFLUXDB_ADMIN_USER}
- InfluxDB password: ${INFLUXDB_ADMIN_PASSWORD}
- Portainer user: admin
- Portainer password: ${PORTAINER_ADMIN_PASSWORD}

MQTT / ESP32
- Broker: $(hostname -I | awk '{print $1}')
- Port: 1883
- Topic: iot/dht11
- Device user: ${MQTT_DEVICE_USER}
- Device password: ${MQTT_DEVICE_PASSWORD}
- Node-RED broker user: ${MQTT_NODERED_USER}
- Node-RED broker password: ${MQTT_NODERED_PASSWORD}
- Power user: ${MQTT_IOTUSER}
- Power user password: ${MQTT_IOTUSER_PASSWORD}

Saved config
- ${ENV_FILE}
- ${SUMMARY_FILE}
EOF

chmod 600 "${SUMMARY_FILE}"

echo -e "${GREEN}"
echo "-------------------------------------------------------"
echo "  Setup complete! Your IoT Hub is ready."
echo "  Credentials saved to: ${SUMMARY_FILE}"
echo "-------------------------------------------------------"
echo -e "${NC}"
docker compose ps
