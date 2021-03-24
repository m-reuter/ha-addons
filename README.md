# hassio-addons
[![Build Status](https://www.travis-ci.com/m-reuter/ha-addons.svg?branch=master)](https://www.travis-ci.com/m-reuter/ha-addons)

Repository for HomeAssistant Addons.


## [pyHPSU](https://github.com/m-reuter/ha-addons/tree/master/pyhpsu) 

This Addon runs pyHPSU and communicates with HomeAssistant via MQTT in both directions. 
pyHPSU is a python interface that communicates with Rotex/Daikin Heat Pumps via the CAN interface.
This Addon allows integration of the Heat Pump into HomeAssistant for reading all Rotex values,
such as warm water temperature, heat pump mode, statistics etc. You can also send commands,
e.g. to make hot water, adjust the room temp. 
See also https://github.com/Spanni26/pyHPSU and https://github.com/Spanni26/pyHPSU/pull/44
