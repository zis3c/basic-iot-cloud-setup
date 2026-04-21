# Basic IoT Cloud Setup

A simple, automated IoT infrastructure stack for DigitalOcean droplets. This project was originally developed for the **KSC6493** course to provide a secure and scalable lab environment.

### 🚀 Included Services:
- **DuckDNS**: Automated dynamic DNS updates.
- **Traefik**: Reverse proxy with automatic HTTPS (Let's Encrypt).
- **Node-RED**: Flow-based programming for IoT logic.
- **Mosquitto**: MQTT broker with user-based authentication.
- **InfluxDB 2**: Time-series database for sensor data.
- **Grafana**: Real-time dashboards and visualization.
- **Portainer**: Lightweight Docker management UI.

## Quick setup (Ubuntu 24.04 droplet)

On a fresh droplet:

```bash
ssh root@<DROPLET_IP>
apt update && apt install -y git
cd /opt
git clone https://github.com/zis3c/basic-iot-cloud-setup.git basic-iot-setup
cd /opt/basic-iot-setup
chmod +x scripts/setup.sh
sudo bash scripts/setup.sh
```

The script will ask only:

- DuckDNS subdomain prefix (example: `myclass-iot`)
- DuckDNS token
- Let's Encrypt email

Then it will:

- install Docker + Compose + firewall rules
- create and fill `.env`
- generate all service passwords
- generate Traefik routing and auth files
- configure MQTT users/passwords
- start the full core stack
- write all credentials to `INSTALL_SUMMARY.txt`

## 🔑 Post-Setup: Accessing Your Credentials

Once the setup script finishes, **all your generated passwords and service URLs** are saved in a summary file. You can view them by running:

```bash
cat INSTALL_SUMMARY.txt
```

### What's inside:
- **Service URLs**: Traefik, Node-RED, InfluxDB, Grafana, Portainer, and Adminer.
- **Admin Credentials**: Automatically generated secure passwords for all web UIs.
- **MQTT Credentials**: Device and user credentials for your ESP32 and Node-RED.

> [!TIP]
> The raw environment variables are also stored in the `.env` file if you need to reference them for Docker Compose.


## Hardware Requirements

To use this stack for a real-world IoT project, you will typically need:

- **Microcontroller**: ESP32 (recommended) or ESP8266.
- **Sensor**: DHT11 or DHT22 (Temperature & Humidity).
- **Wiring**: Jumper wires and a breadboard.
- **Connection**: USB-to-MicroUSB or USB-C cable.

### Standard Wiring (ESP32 + DHT11)

| DHT11 Pin | ESP32 Pin | Description |
|-----------|-----------|-------------|
| VCC       | 3V3       | Power (3.3V) |
| GND       | GND       | Ground      |
| DATA      | GPIO 4    | Sensor Data |

## ESP32 Firmware Configuration

Use these values from `INSTALL_SUMMARY.txt` in your code (e.g., PlatformIO `secrets.h` or Arduino Header):

- **MQTT Host**: Your droplet public IP address.
- **MQTT Port**: `1883`
- **MQTT User**: Device user (default: `esp32dht`)
- **MQTT Password**: (Found in `INSTALL_SUMMARY.txt`)
- **MQTT Topic**: `iot/dht11`

## 🛠️ Troubleshooting

If you encounter issues during setup:

### 1. Check Logs
View live logs to see why a service isn't starting:
```bash
docker compose logs -f [service_name]
```
*(Example: `docker compose logs -f traefik`)*

### 2. Port 1883 (MQTT) Issues
If your ESP32 cannot connect, ensure the port is open in your cloud provider's (DigitalOcean) firewall settings and that the droplet firewall is on:
```bash
sudo ufw status
```

### 3. HTTPS/Certificates
It can take 2-5 minutes for Let's Encrypt to issue certificates. Check the Traefik logs for "ACME" messages if your dashboard shows "Not Secure" for a long time.

## 💾 Backup Automation

Your data is stored in the `./data` folder. We've included a backup script:

```bash
# Run a manual backup
sudo bash scripts/backup.sh
```

### Automatic Backups (Cron Job)
To backup every day at 2 AM:
1. Open crontab: `sudo crontab -e`
2. Add this line at the bottom:
   `0 2 * * * /bin/bash /opt/basic-iot-setup/scripts/backup.sh`

## 📂 Project Structure

```text
.
├── backups/           # Auto-generated backup archives
├── data/              # Persistent volume data (databases, dashboards)
├── firmware/          # ESP32/Hardware source code
├── landing/           # Landing page assets
├── mosquitto/         # MQTT configurations
├── scripts/           # Management & setup scripts
├── traefik/           # Routing & auth configurations
└── docker-compose.yml # Main service orchestration
```

## Update stack later

```bash
cd /opt/basic-iot-setup
./scripts/update.sh
```

