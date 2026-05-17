#!/usr/bin/with-contenv bashio

# Settings for pyhpsu.conf
PYHPSU_DEVICE="$(bashio::config 'pyhpsu_device')"
PYHPSU_PORT="$(bashio::config 'pyhpsu_port')"
#PYHPSU_LANG="$(bashio::config 'pyhpsu_lang')"
MQTT_BROKER="$(bashio::config 'mqtt_broker')"
MQTT_PORT="$(bashio::config 'mqtt_port')"
MQTT_USERNAME="$(bashio::config 'mqtt_username')"
MQTT_PASSWORD="$(bashio::config 'mqtt_password')"
MQTT_CLIENTNAME="$(bashio::config 'mqtt_clientname')"
MQTT_PREFIX="$(bashio::config 'mqtt_prefix')"
MQTT_COMMANDTOPIC="$(bashio::config 'mqtt_commandtopic')"
CANPI_TIMEOUT="$(bashio::config 'canpi_timeout')"
JOBS=$(jq -r 'if .jobs then [.jobs[] | .command+"="+(.interval|tostring) ] | join("\n") else "" end' /data/options.json)


# Replace in pyhpsu.conf (prefix and topic could have "/")
sed -i "s/{pyhpsu_device}/${PYHPSU_DEVICE}/g" "pyhpsu.conf"
sed -i "s/{pyhpsu_port}/${PYHPSU_PORT}/g" "pyhpsu.conf"
#sed -i "s/{pyhpsu_lang}/${PYHPSU_LANG}/g" "pyhpsu.conf"
sed -i "s/{mqtt_broker}/${MQTT_BROKER}/g" "pyhpsu.conf"
sed -i "s/{mqtt_port}/${MQTT_PORT}/g" "pyhpsu.conf"
sed -i "s/{mqtt_username}/${MQTT_USERNAME}/g" "pyhpsu.conf"
sed -i "s/{mqtt_password}/${MQTT_PASSWORD}/g" "pyhpsu.conf"
sed -i "s/{mqtt_clientname}/${MQTT_CLIENTNAME}/g" "pyhpsu.conf"
sed -i "s#{mqtt_prefix}#${MQTT_PREFIX}#g" "pyhpsu.conf"
sed -i "s#{mqtt_commandtopic}#${MQTT_COMMANDTOPIC}#g" "pyhpsu.conf"
sed -i "s/{canpi_timeout}/${CANPI_TIMEOUT}/g" "pyhpsu.conf"
sed -i "s/{jobs}/${JOBS//$'\n'/\\n}/g" "pyhpsu.conf"

echo "Initializing pyhpsu configuration ..."
cp pyhpsu.conf /etc/pyHPSU/pyhpsu.conf

echo
echo "pyHPSU configuration (sensitive values redacted):"
echo
sed -E 's/^([[:space:]]*PASSWORD[[:space:]]*=[[:space:]]*).*/\1<redacted>/' pyhpsu.conf
echo

python3 /usr/local/bin/mqtt_command_daemon.py /etc/pyHPSU/pyhpsu.conf &
MQTT_DAEMON_PID=$!

cleanup() {
    kill "${MQTT_DAEMON_PID}" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

export PYTHONPATH="/usr/lib/python3/dist-packages"
pyHPSU.py -a -o MQTT
