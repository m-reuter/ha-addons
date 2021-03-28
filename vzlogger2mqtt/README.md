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

### verbosity (int)

Level of verbosity (default: 3)

### mqtt_broker (str)

IP address of your MQTT broker

### mqtt_port (port)

1883 or your MQTT Broker port

### mqtt_username (str)

MQTT username to access broker

### mqtt_password (str)

MQTT password to access broker (you should setup your broker to require this!)

### mqtt_topic (str)

Prefix for MQTT topic to send information (default: vzlogger/data)

### verbose (int)

Level of verboseness in log (default: 3)

### meter_protocol (str)

Protocol for meter, currently only sml

### meter_parity (str)

Parity setting for meter (default: 8N1)

### meter_baudrate (int)

Baudrate for meter (default: 9600)

### meter_aggtime (int)

Time in seconds to aggregate meter data before sending (default: 10)

### meter_device (str)

Device name for IR reader on host OS, e.g.:
`/dev/serial/by-id/usb-FTDI_FT230X_Basic_UART_D1234567A-if00-port0`

### meter_device2 (str)

Second device if available. Currently only max of 2 identical devices are supported,
this means that meter settings (protocol, parity, ... and channel info) need to be identical.

### channels (list of dict)

Here you specify the identifiers that you want to read from the smart meter and how to
aggregate values, e.g.:

```
  - identifier: 1-0:16.7.0*255
    aggmode: avg
  - identifier: 1-0:1.8.0*255
    aggmode: max
```

Will read the total consumption (using agg: max) and the current consumption (using agg: avg) on a 
Iskraemeco MT176. More details can be found on the volkszaehler and vzlogger pages:
https://wiki.volkszaehler.org/software/controller/vzlogger/overview_en 

