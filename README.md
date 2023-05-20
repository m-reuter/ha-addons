# HomeAssistant Addons
[![Build Status](https://app.travis-ci.com/m-reuter/ha-addons.svg?branch=master)](https://app.travis-ci.com/github/m-reuter/ha-addons)

Repository for HomeAssistant Addons.

Add this repository to your HA Supervisor

   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fm-reuter%2Fha-addons)

   `https://github.com/m-reuter/ha-addons`

## [pyhpsu2mqtt](https://github.com/m-reuter/ha-addons/tree/master/pyhpsu2mqtt) 

This Add-on runs pyHPSU and communicates with HomeAssistant via MQTT in both directions. 
pyHPSU is a python interface that communicates with Rotex/Daikin Heat Pumps via the CAN interface.
This Addon allows integration of the Heat Pump into HomeAssistant for reading all Rotex values,
such as warm water temperature, heat pump mode, statistics etc. You can also send commands,
e.g. to make hot water, adjust the room temp. 
See also https://github.com/Spanni26/pyHPSU and https://github.com/Spanni26/pyHPSU/pull/44

## [vzlogger2mqtt](https://github.com/m-reuter/ha-addons/tree/master/vzlogger2mqtt) 

This Add-on starts [vzlogger](https://github.com/volkszaehler/vzlogger), a tool to read a
variety of smart meters and sensors. Measurements are passed to HomeAssistant via MQTT. 
This allows the user to inspect and log current electricity usage and overall usage from
several smart meters. Note, that the middleware software Volkszaehler is not needed.
vzlogger can directly pass information via MQTT. 


# Thanks ...

Thanks for your interest in these projects! If any of these are useful to you, you can buy me a coffee:
https://www.buymeacoffee.com/mreuter
