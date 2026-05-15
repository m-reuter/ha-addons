# vzlogger to MQTT Add-on

[![Build](https://github.com/m-reuter/ha-addons/actions/workflows/build-vzlogger2mqtt.yml/badge.svg)](https://github.com/m-reuter/ha-addons/actions/workflows/build-vzlogger2mqtt.yml)

This addon provides [vzlogger](https://github.com/volkszaehler/vzlogger) with MQTT
communication as a HomeAssistant Add-On.
vzlogger is a program to interact with smart electrical meters via SML and an IR interface.
You can read current usage and overall usage from some smart meters, but may have to
request a PIN (from the electricity provider) to unlock detailled information from your
smart meter. One advantage of having this as an Add-On is that HomeAssistant can simply
restart the Add-On if gets stuck (e.g. via an automation that checks if it gets continuous
readings or not).

# Configuration

These parameters will populate the vzlogger.conf. Not all parameters are supported. For more info see
also [vzlogger parameters (ger)] (https://wiki.volkszaehler.org/software/controller/vzlogger/vzlogger_conf_parameter)

### verbosity (int)

Level of verbosity (default: 3):
0=log_alert, 1=log_error, 3=log_warning, 5=log_info, 10=log_debug, 15=log_finest

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

### mqtt_timestamp (bool)

Add Timestamp to MQTT message (default: false)

### mqtt_cafile / mqtt_capath (str, optional)

Path to CA certificate file or directory for TLS-encrypted MQTT connections (e.g. port 8883). Specify either cafile or
capath, not both.

### mqtt_certfile / mqtt_keyfile / mqtt_keypass (str, optional)

Client certificate, private key file, and optional key passphrase for mutual TLS authentication with your MQTT broker.

### meter1_protocol / meter2_protocol (str)

Protocol for meter, currently only sml and d0 are confirmed working

### meter1_parity / meter2_parity (str)

Parity setting for meter (default: 8N1)

### meter1_baudrate / meter2_baudrate (int)

Baudrate for meter (default: 9600)

### meter1_baudrate_read / meter2_baudrate_read

Pull meter may permit higher read rates, default: use same as baudrate above. 300 should always work.

### meter1_pullseq / meter2_pullseq (str)

Init sequence for pull meters (default "")

### meter1_ackseq / meter2_ackseq (str)

Sequence to recieve data in pull meter (default "")

### meter1_aggtime / meter2_aggtime (int)

Time in seconds to aggregate meter data before sending (default: 10)

### meter1_interval / meter2_interval (int)

Time in seconds between accessing a pull meter in seconds. Make sure that the time for the meter to respond is
sufficient, even at low read speeds. Recommendatation for push-meters: "-1".

### meter1_read_timeout / meter2_read_timeout

Time in seconds after which the logger times out (default: 10)

### meter1_use_local_time / meter2_use_local_time

True: use local time instead the one send from the meter (default: False)

### meter1_device (str)

Device name for IR reader on host OS, e.g.:
`/dev/serial/by-id/usb-FTDI_FT230X_Basic_UART_D1234567A-if00-port0`
Recommendation: use by-id instead of the ttyUSBx directly as that can get assigned differently, e.g. after a reboot. The
ID is fixed until you change the device hardware itself.

### meter2_device (str)

Second device if available. Currently only max of 2 devices are supported.

### meter1_channels / meter2_channels (list of dict)

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

# Troubleshooting

### Meter stops reading after Home Assistant restart (HA 2026.5+)

HA 2026.5 changed how USB serial devices are handed to containers, which can cause
the meter's serial stream to arrive mid-frame after a restart, producing log spam like
`Too much data for value` or `Too much data for unit`. The addon includes a 3-second
startup delay to let the device settle, and enables the vzlogger built-in HTTP server
so Home Assistant can automatically restart the addon if it stops producing readings.

For extra reliability, consider setting up an automation that restarts the addon when
no MQTT messages have been received for a configurable period.

**Recommendation:** always use a stable `by-id` path for `meter_device` (e.g.
`/dev/serial/by-id/usb-FTDI_FT230X_Basic_UART_D1234567A-if00-port0`) rather than
`/dev/ttyUSBx`, which can change between reboots.

# Thanks ...

Thanks for your interest in this project! If you like it and it is useful to you, you can now buy me a coffee:
https://www.buymeacoffee.com/mreuter
