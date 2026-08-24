# pyHPSU to MQTT Add-on for ROTEX Heat Pumps

[![CI](https://github.com/m-reuter/ha-addons/actions/workflows/ci-pyhpsu2mqtt.yml/badge.svg)](https://github.com/m-reuter/ha-addons/actions/workflows/ci-pyhpsu2mqtt.yml)

This add-on provides [pyHPSU](https://github.com/Spanni26/pyHPSU) with MQTT bi-directional communication as a Home
Assistant add-on.
pyHPSU is a Python toolbox to communicate with a Rotex/Daikin heat pump via CAN bus (J13).
Tested hardware includes Raspberry Pi systems with either a USB CAN adapter supported by the Linux `gs_usb` driver (for
example a CANable/candleLight-compatible adapter) or a PiCAN 2 HAT. ELM327 did not work for me.

You can read many different variables (flow, pressure, temperatures, statistics, and more) from the Rotex heat pump, and
you can also control it by writing variables. For example, you can temporarily raise the hot water target temperature to
trigger water heating with the heat pump instead of the less efficient electrical heating rod. Variables and commands
are passed via MQTT, so you need an MQTT broker running in Home Assistant, for example the Mosquitto add-on.

Possible commands are available in the upstream pyHPSU project:
[pyHPSU Commands CSV](https://github.com/Spanni26/pyHPSU/tree/master/etc/pyHPSU)

## Installation

1. Add this repository to Home Assistant.
2. Install the `pyhpsu2mqtt` add-on.
3. Configure the MQTT settings and the pyHPSU device settings described below.
4. Start the add-on.

## Hardware setup

For this add-on you need a Raspberry Pi running Home Assistant and a working `can0` interface on the host OS. The add-on
talks to the host CAN interface directly because it runs with host networking enabled.

Before configuring the add-on, verify that the host can already talk to the heat pump:

```bash
ip -details link show type can
ip -s -d link show can0
```

If `can0` is not up yet, bring it up manually:

```bash
sudo ip link set can0 down 2>/dev/null
sudo ip link set can0 type can bitrate 20000
sudo ip link set can0 up
```

After that, a quick smoke test with `candump` can confirm that the CAN interface is working while something is actively
polling the heat pump, for example `pyHPSU`, the `pyhpsu2mqtt` add-on, or another CAN query tool:

```bash
candump -x -e can0
```

### USB CAN adapter (`gs_usb`, recommended on Bookworm)

On current Raspberry Pi OS / Bookworm systems, a USB CAN adapter supported by the Linux `gs_usb` driver is often the
easiest option. This includes candleLight/CANable-compatible adapters that show up as a `gs_usb` device.

1. Plug in the adapter and confirm that Linux detects it:

   ```bash
   dmesg | grep -Ei 'gs_usb|canable|candle'
   ```

2. Bring up `can0` with bitrate `20000` as shown above.
3. Start `candump -x -e can0`, then trigger traffic by running `pyHPSU`, starting the `pyhpsu2mqtt` add-on, or sending
   another known-good CAN query, and confirm that frames appear.

If the adapter is detected but `cansend`/`candump` do not work reliably on Bookworm, updating the adapter to current
candleLight firmware may help. Some older firmware revisions appear to behave badly with newer `gs_usb` stacks.

To bring `can0` up automatically at boot and after a USB replug, use a small helper script with a templated `systemd`
service plus a `udev` rule:

```sh
#!/bin/sh
set -eu
IFACE="${1:-can0}"
/sbin/ip link set "$IFACE" down 2>/dev/null || true
/sbin/ip link set "$IFACE" type can bitrate 20000
/sbin/ip link set "$IFACE" up
```

Save that as `/usr/local/sbin/can-up`, make it executable, then create `/etc/systemd/system/can-up@.service`:

```ini
[Unit]
Description = Bring up %I CAN
BindsTo = sys-subsystem-net-devices-%i.device
After = sys-subsystem-net-devices-%i.device

[Service]
Type = oneshot
ExecStart = /usr/local/sbin/can-up %I
RemainAfterExit = yes
```

And `/etc/udev/rules.d/80-can0-auto-up.rules`:

```udev
ACTION=="add", SUBSYSTEM=="net", KERNEL=="can0", TAG+="systemd", ENV{SYSTEMD_WANTS}+="can-up@can0.service"
```

Finally reload the configuration:

```bash
sudo systemctl daemon-reload
sudo udevadm control --reload
sudo udevadm trigger -c add /sys/class/net/can0
```

### PiCAN 2 HAT

If you use a PiCAN 2 HAT instead, first set up the HAT according to
its [documentation](https://raspberry-valley.azurewebsites.net/ref/Raspberry-Pi-PICAN2-Hat-User-Guide.pdf) and the
pyHPSU [README](https://github.com/Spanni26/pyHPSU/blob/master/README.md), then reboot.

For this you need access to the host OS:

```bash
sudo nano /boot/firmware/config.txt
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

Then connect CAN-H and CAN-L to your RoCon BM1 board J13 CAN-H (pin 1) and CAN-L (pin 2) at your own risk (see also the
pyHPSU disclaimer).
For the connection you need a twisted pair, for instance one pair from an Ethernet cable.
When working on the heat pump, remove the plastic cover, switch off the pump, then switch off the fuse switches and
restore them in reverse order when done.

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

### canpi_log_level (list)

Log level for CAN bus retry/timeout diagnostics (`WARNING` or `ERROR`; default: `ERROR`). At the default level, only
final failures after all retries are logged. Set to `WARNING` to also see individual retry attempts and raw
`SEND`/`RECV` bytes, which is useful when diagnosing bus issues but produces much more log output. This setting only
affects CAN bus diagnostics; other log lines (for example from the MQTT command listener) are unaffected.

### jobs (list of dict)

pyHPSU jobs are commands that are passed to the heat pump at regular intervals to read values and report them back to
MQTT. These jobs must be entered as a list of dictionaries with `command` and `interval` pairs, for example:

```yaml
- command: t_dhw
  interval: 10
- command: t_hs
  interval: 10
```

This reads the domestic hot water temperature (`t_dhw`) and the current heat generator temperature (`t_hs`) every 10
seconds.
With the default `mqtt_prefix` of `rotex`, results are written to MQTT as `/rotex/t_dhw` and `/rotex/t_hs` with their
respective values as payloads. If you changed `mqtt_prefix`, replace `rotex` in the examples below with your configured
prefix.

To confirm that the add-on is publishing to MQTT, use Home Assistant's MQTT integration and listen temporarily on
`<mqtt_prefix>/#` under `Settings` -> `Devices & Services` -> `MQTT` -> `Configure` -> `Listen to a topic`. For example,
if `mqtt_prefix` is left at the default, listen on `rotex/#`.

Not every command in the [pyHPSU Commands CSV](https://github.com/Spanni26/pyHPSU/tree/master/etc/pyHPSU) is guaranteed
to work on every heat pump variant/firmware. If the log repeatedly shows `msg not sync, timeout` for one specific
command while other jobs update fine, that command's reply likely doesn't match what pyHPSU expects on your hardware (
for example `quiet` and `mode` failed this way on a Rotex unit); remove it from your `jobs` list rather than treating it
as a bus problem.

## Home Assistant integration

In Home Assistant you can read values from MQTT by adding sensors in your `configuration.yaml` (for example via the File
Editor add-on). The examples below use the default `mqtt_prefix` of `rotex`; replace it with your configured prefix if
you changed it:

```yaml
sensor:
  - platform: mqtt
    name: "t_dhw"
    state_topic: "rotex/t_dhw"
    unit_of_measurement: "°C"
    device_class: "temperature"
```

Writing to the heat pump, for example adjusting the `t_dhw_setpoint1` hot water target, can be done via an automation in
`automations.yaml`:

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
It then sets `t_dhw_setpoint1` to 51 degrees, which triggers hot water mode, and later resets it to 48 degrees, which is
the default for the rest of the day. You can also attach a Lovelace button to this automation to quickly make hot water
before returning home.

The advantage here is that no electric heating rod is used unless the heat pump exceeds the time limit before reaching
the target temperature, which is usually 50 minutes by default.

## Additional notes

### Security and permissions

To access the host `can0` interface (PiCAN 2 HAT), this add-on currently needs `--network host`.
If you know how to limit access to `can0` more narrowly, let me know.

### Rotex heat pump settings

If you want to optimize your heat pump, take a look at https://m-reuter.github.io/Rotex-Daikin-WP for an introduction
and recommended settings (in German).

## Thanks

Thanks for your interest in this project. If you like it and it is useful to you, you can buy me a coffee:
https://www.buymeacoffee.com/mreuter
