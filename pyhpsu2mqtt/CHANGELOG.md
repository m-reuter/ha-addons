# Changelog

## 1.0.0

- Move the pyHPSU base from the old release's frozen `testing`-branch commit to a current `master` commit, and
  reimplement the MQTT functionality that only ever existed on `testing` (never merged upstream):
    - `mqtt_command_daemon.py`: standalone listener for incoming MQTT write/read commands
    - Persistent, process-wide MQTT connection for publishing job results (`paho-mqtt` 2.x compatible)
- Fix a race condition in pyHPSU's auto-mode scheduler that could corrupt concurrent job threads' CAN exchanges
- Fix `pyhpsu.conf` overrides being silently ignored (`canpi.py`'s `get_with_default()`)
- Fix `value`-type write commands being corrupted for values > 255
- Fix a write of `0`/`0.0` being silently treated as a read
- Fix the MQTT command listener crashing on non-UTF-8 payloads
- Fix `RETAIN` config parsing (was an exact string match instead of a real boolean)
- New `canpi_log_level` option (`WARNING`/`ERROR`) to control CAN retry/timeout log verbosity
- `canpi_timeout` default raised from `0.05` to `0.1`, measured more reliable in extended live testing
- Ensure log output appears immediately instead of sitting in a buffer (`PYTHONUNBUFFERED=1`)
- Various smaller fixes and log formatting/diagnostics improvements

## 0.9.2

- Adopt pyHPSU to work with python-can 4.0.0

## 0.9.1

- pyHPSU fix for race condition in MQTT re-connects

## 0.9.0

- Initial Release
