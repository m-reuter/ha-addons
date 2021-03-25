# pyHPSU to MQTT Add-on
[![Build Status](https://travis-ci.com/m-reuter/ha-addons.svg?branch=master)](https://travis-ci.com/m-reuter/ha-addons)

## Description

This addon provides [pyHPSU](https://github.com/Spanni26/pyHPSU) with MQTT bi-directional communication as a HomeAssistant Add-On.
pyHPSU is a python toolbox to communicate with a Rotex/Daikin Heat Pump via CAN Bus (J13). 
Tested hardware is Raspberry Pi 4b with a pyCAN 2 Hat. ELM327 did not work for me.

You can pull many different variables (flow, pressure, temperatures, statistics etc) from the Rotex,
and you can also control it by writing variables (e.g. you can raise the target hot water temp for a few 
seconds to trigger water heating with heat pump instead of the one-hot option which uses the inefficient 
electrical heating rod). Variables and commands are passed via MQTT, so you need to have an MQTT broker 
running (e.g. the Mosquitto Add-on in HA). Possible commands are available in the pyHPSU project.

In order for this Add-on to access the can0 interface (pican 2 hat) of the host, --network host is needed. 
If you know how to only limit access to can0 differently, let me know. 

## Configuration

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

Set timeout for canpi interface (default: 0.05)

### jobs (list of dict)

pyHPSU jobs: must be entered as a list of dictionaries with this format : `{"command": "...", "interval": "..."}`
pyHPSU will push the command in the specified interval in seconds to Rotex and report the answer back to MQTT.
For example: 
`{"command": "t_dhw", "interval": 10}`
to obtain the domestic hot water temperature every 10 seconds as MQTT /rotex/t_dhw

