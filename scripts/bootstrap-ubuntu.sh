#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or: sudo $0)" >&2
  exit 1
fi

REPO_URL="${1:-}"
INSTALL_DIR="${2:-/opt/basic-iot-setup}"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  git \
  ufw \
  docker.io \
  docker-compose-v2

systemctl enable --now docker

# Firewall (safe defaults: keep SSH open)
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 1883/tcp
ufw --force enable

if [[ -n "${REPO_URL}" ]]; then
  if [[ -e "${INSTALL_DIR}" ]]; then
    echo "Refusing to overwrite existing ${INSTALL_DIR}" >&2
    exit 1
  fi
  git clone "${REPO_URL}" "${INSTALL_DIR}"
fi

mkdir -p "${INSTALL_DIR}/data/traefik/letsencrypt"
touch "${INSTALL_DIR}/data/traefik/letsencrypt/acme.json"
chmod 600 "${INSTALL_DIR}/data/traefik/letsencrypt/acme.json"

cat <<EOF
Bootstrap done.
Next:
  cd ${INSTALL_DIR}
  cp .env.example .env
  nano .env
  docker compose up -d
EOF

