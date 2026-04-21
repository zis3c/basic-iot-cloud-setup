# ESP32 DHT11 MQTT Example

This folder contains a ready-to-use Arduino sketch to connect your physical hardware to this cloud stack.

## 📦 Requirements

1.  **Libraries**:
    - `PubSubClient` by Nick O'Leary
    - `DHT sensor library` by Adafruit
    - `Adafruit Unified Sensor` by Adafruit
2.  **Hardware**:
    - ESP32 Development Board
    - DHT11 or DHT22 Sensor
    - Jumper wires

## 🛠️ Setup

1.  Open `esp32-dht-mqtt.ino` in the **Arduino IDE** or **VS Code (PlatformIO)**.
2.  Update the `ssid` and `password` with your WiFi credentials.
3.  Update `mqtt_server` with your Droplet's Public IP.
4.  Update `mqtt_password` with the **Device Password** found in your `INSTALL_SUMMARY.txt`.
5.  Upload the code to your ESP32.

## 📌 Wiring

| DHT11 Pin | ESP32 Pin |
| :--- | :--- |
| VCC | 3V3 |
| GND | GND |
| DATA | GPIO 4 |

## 📡 Monitoring

Once uploaded, open the **Serial Monitor** (115200 baud). You should see the ESP32 connecting to WiFi and then publishing JSON data every 10 seconds.

You can then see this data in **Node-RED** by subscribing to the `iot/dht11` topic!
