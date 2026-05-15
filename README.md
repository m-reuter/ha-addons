# Home Assistant Add-ons
[![Build Status](https://app.travis-ci.com/m-reuter/ha-addons.svg?branch=master)](https://app.travis-ci.com/github/m-reuter/ha-addons)

This repository contains Home Assistant add-ons for MQTT-based integrations with external devices.

## Add this repository to Home Assistant

Click the badge below to add this repository to Home Assistant Supervisor, or add it manually with the repository URL.

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fm-reuter%2Fha-addons)

**Repository URL:** `https://github.com/m-reuter/ha-addons`

## Available add-ons

### [pyhpsu2mqtt](https://github.com/m-reuter/ha-addons/tree/master/pyhpsu2mqtt)

Runs [pyHPSU](https://github.com/Spanni26/pyHPSU) and connects a Rotex/Daikin heat pump to Home Assistant via MQTT. It supports reading values such as temperatures and statistics, and sending control commands back to the heat pump.

See also the upstream project and related discussion:
- https://github.com/Spanni26/pyHPSU
- https://github.com/Spanni26/pyHPSU/pull/44

### [vzlogger2mqtt](https://github.com/m-reuter/ha-addons/tree/master/vzlogger2mqtt)

Runs [vzlogger](https://github.com/volkszaehler/vzlogger) and publishes smart meter readings to Home Assistant via MQTT. This is useful for monitoring current and total electricity usage without requiring the Volkszaehler middleware.

## Thanks

Thanks for your interest in these projects. If any of them are useful to you, you can buy me a coffee:
https://www.buymeacoffee.com/mreuter
