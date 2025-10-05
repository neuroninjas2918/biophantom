# BioPhantom Mainframe

The mainframe dashboard for BioPhantom neurotoxin detection system.

## Features

- WebSocket server for receiving RiskEvents from devices
- BLE scanner fallback for passive detection
- Room risk aggregation with EMA and peak hold
- Automatic room sealing when risk threshold exceeded
- Simulation tools for testing

## Running the Server

1. Start the mainframe app:
   ```bash
   flutter run
   ```
   The WS server starts automatically on port 8765.

2. Run the simulation script to test:
   ```bash
   dart tools/simulate_devices.dart
   ```
   This simulates 2 devices in room1 sending high risk events, triggering sealing.

## Configuration

- Shared secret: assets/config/bio_key.txt
- Mainframe IP for devices: assets/config/mainframe_ip.txt (optional, uses mDNS otherwise)

## Demo Steps

1. Open mainframe on desktop.
2. Run simulate_devices.dart.
3. Observe room sealing in logs and data/rooms.json.
4. Two devices with risk >=0.9 in same room within 10s triggers seal.
