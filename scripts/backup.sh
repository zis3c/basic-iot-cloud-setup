#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_ROOT="${ROOT_DIR}/backups"
TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"

mkdir -p "${BACKUP_DIR}"

echo "Starting full backup..."

# 1. Node-RED
echo "Backing up Node-RED..."
mkdir -p "${BACKUP_DIR}/node-red"
cp -a "${ROOT_DIR}/data/node-red/." "${BACKUP_DIR}/node-red/"

# 2. InfluxDB (using influx backup command if container is running)
echo "Backing up InfluxDB..."
if [ "$(docker ps -q -f name=influxdb)" ]; then
    docker exec influxdb influx backup /tmp/influx_backup > /dev/null
    docker cp influxdb:/tmp/influx_backup "${BACKUP_DIR}/influxdb"
    docker exec influxdb rm -rf /tmp/influx_backup
else
    echo "Warning: InfluxDB container not running. Backing up data folder directly."
    mkdir -p "${BACKUP_DIR}/influxdb"
    cp -a "${ROOT_DIR}/data/influxdb/." "${BACKUP_DIR}/influxdb/"
fi

# 3. Mosquitto Config
echo "Backing up Mosquitto config..."
mkdir -p "${BACKUP_DIR}/mosquitto"
cp -a "${ROOT_DIR}/mosquitto/config/." "${BACKUP_DIR}/mosquitto/"

# 4. Environment and Metadata
echo "Backing up configuration files..."
cp "${ROOT_DIR}/.env" "${BACKUP_DIR}/" || true
cp "${ROOT_DIR}/INSTALL_SUMMARY.txt" "${BACKUP_DIR}/" || true

# Compress
cd "${BACKUP_ROOT}"
tar -czf "${TIMESTAMP}.tar.gz" "${TIMESTAMP}"
rm -rf "${TIMESTAMP}"

echo "------------------------------------------"
echo "Backup complete: ${BACKUP_ROOT}/${TIMESTAMP}.tar.gz"
echo "------------------------------------------"
