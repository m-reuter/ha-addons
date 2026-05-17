# vzlogger to MQTT Add-on

[![CI](https://github.com/m-reuter/ha-addons/actions/workflows/ci-vzlogger2mqtt.yml/badge.svg)](https://github.com/m-reuter/ha-addons/actions/workflows/ci-vzlogger2mqtt.yml)

This add-on provides [vzlogger](https://github.com/volkszaehler/vzlogger) with MQTT communication as a Home Assistant add-on.
vzlogger interacts with smart electrical meters via SML and an IR interface.
You can read current usage and total usage from supported smart meters, although you may need to request a PIN from your electricity provider to unlock detailed information.
One advantage of having this as an add-on is that Home Assistant can automatically restart it if it gets stuck, for example via an automation that checks whether readings continue to arrive.

## Quick start

1. Install the `vzlogger2mqtt` add-on from this repository.
2. Configure the MQTT connection settings.
3. Configure at least one meter, including `meter1_device`, `meter1_protocol`, and `meter1_channels`.
4. Start the add-on and verify in the logs that the meter is being read successfully.

## Configuration

These parameters populate `vzlogger.conf`. Not all parameters are supported. For more information see also [vzlogger parameters (German)](https://wiki.volkszaehler.org/software/controller/vzlogger/vzlogger_conf_parameter).

### verbosity (int)

Level of verbosity (default: `3`):
`0=log_alert, 1=log_error, 3=log_warning, 5=log_info, 10=log_debug, 15=log_finest`

### mqtt_broker (str)

IP address of your MQTT broker.

### mqtt_port (port)

Usually `1883`, or your MQTT broker port.

### mqtt_username (str)

MQTT username to access the broker.

### mqtt_password (str)

MQTT password to access the broker.

### mqtt_topic (str)

Prefix for the MQTT topic used to publish readings (default: `vzlogger/data`).

### mqtt_timestamp (bool)

Add a timestamp to the MQTT message (default: `false`).

### mqtt_cafile / mqtt_capath (str, optional)

Path to a CA certificate file or directory for TLS-encrypted MQTT connections (for example port `8883`). Specify either `cafile` or `capath`, not both.

### mqtt_certfile / mqtt_keyfile / mqtt_keypass (str, optional)

Client certificate, private key file, and optional key passphrase for mutual TLS authentication with your MQTT broker.

### meter1_protocol / meter2_protocol (str)

Meter protocol. Currently `sml` and `d0` are confirmed working.

### meter1_parity / meter2_parity (str)

Parity setting for the meter (default: `8N1`).

### meter1_baudrate / meter2_baudrate (int)

Baud rate for the meter (default: `9600`).

### meter1_baudrate_read / meter2_baudrate_read

Pull meters may support higher read rates. By default this uses the same value as the normal baud rate. `300` baud should always work.

### meter1_pullseq / meter2_pullseq (str)

Initialization sequence for pull meters (default: empty string).

### meter1_ackseq / meter2_ackseq (str)

Sequence used to receive data from a pull meter (default: empty string).

### meter1_aggtime / meter2_aggtime (int)

Time in seconds to aggregate meter data before sending (default: `10`).

### meter1_interval / meter2_interval (int)

Time in seconds between accesses to a pull meter. Make sure the meter has enough time to respond, especially at low read speeds. Recommendation for push meters: `-1`.

### meter1_read_timeout / meter2_read_timeout

Time in seconds before the logger times out waiting for a meter response (default: `10`). Increase this for slow devices or low baud rates.

### meter1_use_local_time / meter2_use_local_time

`true`: use local time instead of the timestamp sent by the meter (default: `false`).

### meter1_device (str)

Device name for the IR reader on the host OS, for example:
`/dev/serial/by-id/usb-FTDI_FT230X_Basic_UART_D1234567A-if00-port0`

Recommendation: use a stable `by-id` path instead of `ttyUSBx`, because `ttyUSBx` assignments can change after a reboot.

### meter2_device (str)

Second device if available. Currently a maximum of two devices is supported.

### meter1_channels / meter2_channels (list of dict)

Here you specify the identifiers you want to read from the smart meter and how to aggregate them, for example:

```yaml
- identifier: 1-0:16.7.0*255
  aggmode: avg
- identifier: 1-0:1.8.0*255
  aggmode: max
```

On an Iskraemeco MT176 this reads the current consumption (`aggmode: avg`) and total consumption (`aggmode: max`).
More details can be found on the Volkszaehler and vzlogger pages:
https://wiki.volkszaehler.org/software/controller/vzlogger/overview_en

## Troubleshooting

### Meter stops reading after Home Assistant restart (HA 2026.5+)

HA 2026.5 changed how USB serial devices are handed to containers, which can cause the meter's serial stream to arrive mid-frame after a restart, producing log spam like `Too much data for value` or `Too much data for unit`.
The add-on now waits briefly for USB serial devices to settle and drains any stale bytes from each configured meter device before launching `vzlogger`. It also enables the vzlogger built-in HTTP server so Home Assistant can monitor that endpoint and automatically restart the add-on if the HTTP health check stops responding.

For extra reliability, consider setting up an automation that restarts the add-on when no MQTT messages have been received for a configurable period.

**Recommendation:** always use a stable `by-id` path for `meter1_device` / `meter2_device` (for example `/dev/serial/by-id/usb-FTDI_FT230X_Basic_UART_D1234567A-if00-port0`) rather than `/dev/ttyUSBx`, which can change between reboots.

## Thanks

Thanks for your interest in this project. If you like it and it is useful to you, you can buy me a coffee:
https://www.buymeacoffee.com/mreuter
