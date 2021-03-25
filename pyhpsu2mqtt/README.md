# pyHPSU to MQTT Add-on for ROTEX Heat Pumps
[![Build Status](https://travis-ci.com/m-reuter/ha-addons.svg?branch=master)](https://travis-ci.com/m-reuter/ha-addons)


This addon provides [pyHPSU](https://github.com/Spanni26/pyHPSU) with MQTT bi-directional communication as a HomeAssistant Add-On.
pyHPSU is a python toolbox to communicate with a Rotex/Daikin Heat Pump via CAN Bus (J13). 
Tested hardware is Raspberry Pi 4b with a PiCAN 2 Hat. ELM327 did not work for me.

You can pull many different variables (flow, pressure, temperatures, statistics etc) from the Rotex,
and you can also control it by writing variables (e.g. you can raise the target hot water temp for a few 
seconds to trigger water heating with heat pump instead of the one-hot option which uses the inefficient 
electrical heating rod). Variables and commands are passed via MQTT, so you need to have an MQTT broker 
running (e.g. the Mosquitto Add-on in HA). Possible commands are available in the pyHPSU project:
[pyHPSU Commands CSV](https://github.com/Spanni26/pyHPSU/tree/master/etc/pyHPSU).

Security rating of this Add-on: 
In order for this Add-on to access the `can0` interface (PiCAN 2 hat) of the host, `--network host` is needed. 
If you know how to only limit access to `can0` differently, let me know. 

# Hardware Setup

For this to work you need to have a Raspberry Pi 2,3,4 with PiCAN 2 Hat and a running Home Assistant
on the same device. First setup the PiCAN hat according to its [documentation](https://raspberry-valley.azurewebsites.net/ref/Raspberry-Pi-PICAN2-Hat-User-Guide.pdf )
and pyHPSU [README](https://github.com/Spanni26/pyHPSU/blob/master/README.md) and reboot. For this you need
access to the host OS:

```
sudo nano /boot/config.txt
```
and add:
```
dtparam=spi=on
dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25
dtoverlay=spi-bcm2835-overlay
```
Also create the interface by editing:
```
sudo nano /etc/network/interfaces
```
and adding:
```
auto can0
iface can0 inet manual
     pre-up /sbin/ip link set $IFACE type can bitrate 20000 triple-sampling on
     up /sbin/ifconfig $IFACE up
     down /sbin/ifconfig $IFACE down
```

Then connect CAN-hi and CAN-low to your RoCon BM1 board J13 CAN-H (Pin1) and CAN-L (Pin2) at your own risk (see also pyHPSU disclaimer). 
For the connection you need a twisted! pair, for instance use a twisted pair in an ethernet cable. 
When working on the heat pump, remove plastic cover, switch off the pump and then switch off fuse-switches and when done
reverse order. 

# Configuration of Add-On

These parameters will populate the pyhpsu.conf:

### pyhpsu_device (str)

Should be "PYCAN", let me know if you have success connecting an ELM327.

### pyhpsu_port (str)

Should be empty for PYCAN device. For ELM327 this should be the TTY/USB device. 

### pyhpsu_lang (str)

Select language (probably not necessary for MQTT communication, default EN)

### mqtt_broker (str)

IP address of your MQTT broker

### mqtt_port (port)

1883 or your MQTT Broker port

### mqtt_username (str)

MQTT username to access broker

### mqtt_password (str)

MQTT password to access broker (you should setup your broker to require this!)

### mqtt_clientname (str)

Name of the pyHPSU MQTT client (default: rotex_hpsu, no need to change)

### mqtt_prefix (str)

Prefix for topic to send information from pyHPSU to MQTT (default: rotex)

### mqtt_commandtopic (str)

Topic for commands going from MQTT to pyHPSU (default: command)

### canpi_timeout (float)

Set timeout in seconds for canpi interface (default: 0.05)

### jobs (list of dict)

pyHPSU jobs are commands that are passed to the heat pump in regular intervalls to read values and report back to MQTT.
These jobs must be entered as a list of dictionaries as command and interval pairs, for example:

```
  - command: t_dhw
    interval: 10
  - command: t_hs
    interval: 10
```
to obtain the domestic hot water temperature (t_dhw) and current temperature (t_hs) of the heat generator every 10 seconds. 
Results are written to MQTT as /rotex/t_dhw and /rotex/t_hs with there respective values as payloads.  


# Home Assistant

In Home Assistant you can read values from MQTT by adding sensors in your configuration.yaml (e.g. via the File Editor Add-on):

```
sensor:
  - platform: mqtt
    name: "t_dhw"
    state_topic: "rotex/t_dhw"
    unit_of_measurement: "°C"
    device_class: "temperature"
```

Writing to the heatpump (e.g. adjusting the setpoint1 of hot water) could be done via an automation
in automations.yaml: 

```
- id: 'make_warm_ater'
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

This will check at 19:00 if warm water temp is below 46 (done to reduce unnecessary write operations). 
It will then set the dhw setpoint1 to 51 degrees, triggering the pump to go into hot water mode. It will
then reset the dhw setpoint1 to 48 degrees, which is the default for the rest of the day. You can also 
attach a lovelace button to this automation to quickly make hot water before returning home if you
expect that several people want to take a shower soon. The advantage here is that no electric heating 
rod is used (unless the heat pump exceeds the timelimit before reaching the target temp, which is
usually 50 mins by default - I set mine to 60 min to avoid using the heting rod at all for warm water).


