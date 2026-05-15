# pyHPSU to MQTT Add-on for ROTEX Heat Pumps
[![Build Status](https://travis-ci.com/m-reuter/ha-addons.svg?branch=master)](https://travis-ci.com/m-reuter/ha-addons)

This add-on provides [pyHPSU](https://github.com/Spanni26/pyHPSU) with MQTT bi-directional communication as a Home Assistant add-on.
pyHPSU is a Python toolbox to communicate with a Rotex/Daikin heat pump via CAN bus (J13).
Tested hardware is a Raspberry Pi 4B with a PiCAN 2 HAT. ELM327 did not work for me.

You can read many different variables (flow, pressure, temperatures, statistics, and more) from the Rotex heat pump, and you can also control it by writing variables. For example, you can temporarily raise the hot water target temperature to trigger water heating with the heat pump instead of the less efficient electrical heating rod. Variables and commands are passed via MQTT, so you need an MQTT broker running in Home Assistant, for example the Mosquitto add-on.

Possible commands are available in the upstream pyHPSU project:
[pyHPSU Commands CSV](https://github.com/Spanni26/pyHPSU/tree/master/etc/pyHPSU)

## Installation

1. Add this repository to Home Assistant.
2. Install the `pyhpsu2mqtt` add-on.
3. Configure the MQTT settings and the pyHPSU device settings described below.
4. Start the add-on.

## Hardware setup

For this add-on to work you need a Raspberry Pi with a PiCAN 2 HAT and a running Home Assistant instance on the same device. First set up the PiCAN HAT according to its [documentation](https://raspberry-valley.azurewebsites.net/ref/Raspberry-Pi-PICAN2-Hat-User-Guide.pdf) and the pyHPSU [README](https://github.com/Spanni26/pyHPSU/blob/master/README.md), then reboot.

For this you need access to the host OS:

```bash
sudo nano /boot/config.txt
```

Add:

```bash
dtparam=spi=on
dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25
dtoverlay=spi-bcm2835-overlay
```

Also create the interface by editing:

```bash
sudo nano /etc/network/interfaces
```

And add:

```bash
auto can0
iface can0 inet manual
     pre-up /sbin/ip link set $IFACE type can bitrate 20000 triple-sampling on
     up /sbin/ifconfig $IFACE up
     down /sbin/ifconfig $IFACE down
```

Then connect CAN-H and CAN-L to your RoCon BM1 board J13 CAN-H (pin 1) and CAN-L (pin 2) at your own risk (see also the pyHPSU disclaimer).
For the connection you need a twisted pair, for instance one pair from an Ethernet cable.
When working on the heat pump, remove the plastic cover, switch off the pump, then switch off the fuse switches and restore them in reverse order when done.

## Configuration

These parameters populate `pyhpsu.conf`:

### pyhpsu_device (str)

Should be `PYCAN`. Let me know if you have success connecting an ELM327.

### pyhpsu_port (str)

Should be empty for the `PYCAN` device. For ELM327 this should be the TTY/USB device.

### mqtt_broker (str)

IP address of your MQTT broker.

### mqtt_port (port)

Usually `1883`, or your MQTT broker port.

### mqtt_username (str)

MQTT username to access the broker.

### mqtt_password (str)

MQTT password to access the broker.

### mqtt_clientname (str)

Name of the pyHPSU MQTT client (default: `rotex_hpsu`).

### mqtt_prefix (str)

Prefix for topics sent from pyHPSU to MQTT (default: `rotex`).

### mqtt_commandtopic (str)

Topic for commands going from MQTT to pyHPSU (default: `command`).

### canpi_timeout (float)

Timeout in seconds for the CAN interface (default: `0.05`).

### jobs (list of dict)

pyHPSU jobs are commands that are passed to the heat pump at regular intervals to read values and report them back to MQTT. These jobs must be entered as a list of dictionaries with `command` and `interval` pairs, for example:

```yaml
- command: t_dhw
  interval: 10
- command: t_hs
  interval: 10
```

This reads the domestic hot water temperature (`t_dhw`) and the current heat generator temperature (`t_hs`) every 10 seconds.
Results are written to MQTT as `/rotex/t_dhw` and `/rotex/t_hs` with their respective values as payloads.

## Home Assistant integration

In Home Assistant you can read values from MQTT by adding sensors in your `configuration.yaml` (for example via the File Editor add-on):

```yaml
sensor:
  - platform: mqtt
    name: "t_dhw"
    state_topic: "rotex/t_dhw"
    unit_of_measurement: "°C"
    device_class: "temperature"
```

Writing to the heat pump, for example adjusting the `t_dhw_setpoint1` hot water target, can be done via an automation in `automations.yaml`:

```yaml
- id: 'make_warm_water'
  alias: "Make Warm Water"
  trigger:
    - platform: time
      at: '19:00'
  action:
    - condition: numeric_state
      entity_id: sensor.t_dhw
      below: '46'
    - service: mqtt.publish
      data:
        topic: rotex/command/t_dhw_setpoint1
        payload: '51'
    - delay:
        hours: 0
        minutes: 0
        seconds: 15
        milliseconds: 0
    - service: mqtt.publish
      data:
        topic: rotex/command/t_dhw_setpoint1
        payload: '48'
  mode: single
```

This checks at 19:00 whether the warm water temperature is below 46 to reduce unnecessary write operations.
It then sets `t_dhw_setpoint1` to 51 degrees, which triggers hot water mode, and later resets it to 48 degrees, which is the default for the rest of the day. You can also attach a Lovelace button to this automation to quickly make hot water before returning home.

The advantage here is that no electric heating rod is used unless the heat pump exceeds the time limit before reaching the target temperature, which is usually 50 minutes by default.

## Additional notes

### Security and permissions

To access the host `can0` interface (PiCAN 2 HAT), this add-on currently needs `--network host`.
If you know how to limit access to `can0` more narrowly, let me know.

### Rotex heat pump settings

If you want to optimize your heat pump, take a look at https://m-reuter.github.io/Rotex-Daikin-WP for an introduction and recommended settings (in German).

## Thanks

Thanks for your interest in this project. If you like it and it is useful to you, you can buy me a coffee:
https://www.buymeacoffee.com/mreuter
