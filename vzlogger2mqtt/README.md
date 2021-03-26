# vzlogger to MQTT Add-on
[![Build Status](https://travis-ci.com/m-reuter/ha-addons.svg?branch=master)](https://travis-ci.com/m-reuter/ha-addons)


This addon provides [vzlogger](https://github.com/volkszaehler/vzlogger) with MQTT 
communication as a HomeAssistant Add-On.
vzlogger is a program to interact with smart electrical meters via SML and an IR interface. 
You can read current usage and overall usage from some smart meters, but may have to 
request a PIN (from the electricity provider) to unlock detailled information from your
smart meter. 


# Configuration

These parameters will populate the vzlogger.conf:

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

