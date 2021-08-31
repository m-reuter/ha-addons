#!/usr/bin/with-contenv bashio

CONFIG_PATH=/data/options.json

# Settings for vzlogger.conf
VERBOSITY="$(bashio::config 'verbosity')"
MQTT_BROKER="$(bashio::config 'mqtt_broker')"
MQTT_PORT="$(bashio::config 'mqtt_port')"
MQTT_USERNAME="$(bashio::config 'mqtt_username')"
MQTT_PASSWORD="$(bashio::config 'mqtt_password')"
MQTT_TOPIC="$(bashio::config 'mqtt_topic')"
MQTT_TIMESTAMP="$(bashio::config 'mqtt_timestamp')"

METER1_PROTOCOL="$(bashio::config 'meter1_protocol')"
METER1_PARITY="$(bashio::config 'meter1_parity')"
METER1_BAUDRATE="$(bashio::config 'meter1_baudrate')"
METER1_AGGTIME="$(bashio::config 'meter1_aggtime')"
METER1_INTERVAL="$(bashio::config 'meter1_interval')"
METER1_DEVICE="$(bashio::config 'meter1_device')"

METER2_PROTOCOL="$(bashio::config 'meter2_protocol')"
METER2_PARITY="$(bashio::config 'meter2_parity')"
METER2_BAUDRATE="$(bashio::config 'meter2_baudrate')"
METER2_AGGTIME="$(bashio::config 'meter2_aggtime')"
METER2_INTERVAL="$(bashio::config 'meter2_interval')"
METER2_DEVICE="$(bashio::config 'meter2_device')"



#CLEN =$(jq '.channels | length' /data/options.json)
MMETER1_CHANNELS=$(jq -r 'if .meter1_channels then [.meter1_channels[] | "{\n           \"uuid\": \"1\", \n           \"api\": \"null\", \n           \"identifier\": \""+.identifier+"\", \n           \"aggmode\": \""+.aggmode+"\" }" ] | join(",\n         ") else "" end' /data/options.json)
#echo "$CHANNELS"

METER2_ENABLED="false"
if [[ ! -z $METER2_DEVICE ]]
then
  echo "Enabling second meter ... "
  METER2_ENABLED="true"
fi

# Replace in vzlogger.conf
echo "Initializing vzlogger configuration ..."

#MQTT options
sed -i "s/{verbosity}/${VERBOSITY}/g" "vzlogger.conf"
sed -i "s/{mqtt_broker}/${MQTT_BROKER}/g" "vzlogger.conf"
sed -i "s/{mqtt_port}/${MQTT_PORT}/g" "vzlogger.conf"
sed -i "s/{mqtt_username}/${MQTT_USERNAME}/g" "vzlogger.conf"
sed -i "s/{mqtt_password}/${MQTT_PASSWORD}/g" "vzlogger.conf"
sed -i "s#{mqtt_topic}#${MQTT_TOPIC}#g" "vzlogger.conf"
sed -i "s#{mqtt_timestamp}#${MQTT_TIMESTAMP}#g" "vzlogger.conf"

#Meter 1 options
sed -i "s/{meter1_protocol}/${METER1_PROTOCOL}/g" "vzlogger.conf"
sed -i "s/{meter1_parity}/${METER1_PARITY}/g" "vzlogger.conf"
sed -i "s/{meter1_baudrate}/${METER1_BAUDRATE}/g" "vzlogger.conf"
sed -i "s/{meter1_aggtime}/${METER1_AGGTIME}/g" "vzlogger.conf"
sed -i "s/{meter1_interval}/${METER1_INTERVAL}/g" "vzlogger.conf"
sed -i "s#{meter1_device}#${METER1_DEVICE}#g" "vzlogger.conf"



sed -i "s/{meter1_channels}/${MMETER1_CHANNELS//$'\n'/\\n}/g" "vzlogger.conf"
#Meter 2 options
sed -i "s/{meter2_enabled}/${METER2_ENABLED}/g" "vzlogger.conf"
sed -i "s#{meter2_device}#${METER2_DEVICE}#g" "vzlogger.conf"
sed -i "s/{meter2_protocol}/${METER2_PROTOCOL}/g" "vzlogger.conf"
sed -i "s/{meter2_parity}/${METER2_PARITY}/g" "vzlogger.conf"
sed -i "s/{meter2_baudrate}/${METER2_BAUDRATE}/g" "vzlogger.conf"
sed -i "s/{meter2_aggtime}/${METER2_AGGTIME}/g" "vzlogger.conf"
sed -i "s/{meter2_interval}/${METER2_INTERVAL}/g" "vzlogger.conf"


echo
echo vzlogger.conf: 
echo
cat vzlogger.conf
echo

echo "CMD: /usr/local/bin/vzlogger --foreground --config /vzlogger.conf"
/usr/local/bin/vzlogger --foreground --config /vzlogger.conf
#echo out.txt:
#echo
#cat /out.txt
echo
echo vzlogger.log:
echo
cat /vzlogger.log

