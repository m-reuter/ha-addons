#!/usr/bin/with-contenv bashio

# ── MQTT settings ────────────────────────────────────────────────────────────
VERBOSITY="$(bashio::config 'verbosity')"
MQTT_BROKER="$(bashio::config 'mqtt_broker')"
MQTT_PORT="$(bashio::config 'mqtt_port')"
MQTT_USERNAME="$(bashio::config 'mqtt_username')"
MQTT_PASSWORD="$(bashio::config 'mqtt_password')"
MQTT_TOPIC="$(bashio::config 'mqtt_topic')"
MQTT_TIMESTAMP="$(bashio::config 'mqtt_timestamp')"

# ── Meter 1 settings ─────────────────────────────────────────────────────────
METER1_PROTOCOL="$(bashio::config 'meter1_protocol')"
METER1_PARITY="$(bashio::config 'meter1_parity')"
METER1_BAUDRATE="$(bashio::config 'meter1_baudrate')"
METER1_BAUDRATE_READ="$(bashio::config 'meter1_baudrate_read')"
METER1_PULLSEQ="$(bashio::config 'meter1_pullseq' '')"
METER1_ACKSEQ="$(bashio::config 'meter1_ackseq' '')"
METER1_AGGTIME="$(bashio::config 'meter1_aggtime')"
METER1_INTERVAL="$(bashio::config 'meter1_interval')"
METER1_READ_TIMEOUT="$(bashio::config 'meter1_read_timeout')"
METER1_USE_LOCAL_TIME="$(bashio::config 'meter1_use_local_time')"
METER1_DEVICE="$(bashio::config 'meter1_device')"

# null → empty string for optional fields
[[ "$METER1_PULLSEQ" == "null" ]] && METER1_PULLSEQ=""
[[ "$METER1_ACKSEQ"  == "null" ]] && METER1_ACKSEQ=""

# ── Build meter1 channels JSON array ─────────────────────────────────────────
METER1_CHANNELS=$(jq '[.meter1_channels[] | {uuid: "1", api: "null", identifier: .identifier, aggmode: .aggmode}]' /data/options.json)

# ── Build meter1 config object ───────────────────────────────────────────────
METER1_OBJ=$(jq -n \
    --arg     protocol       "$METER1_PROTOCOL"      \
    --arg     device         "$METER1_DEVICE"         \
    --arg     parity         "$METER1_PARITY"         \
    --argjson baudrate       "$METER1_BAUDRATE"       \
    --argjson baudrate_read  "$METER1_BAUDRATE_READ"  \
    --arg     pullseq        "$METER1_PULLSEQ"        \
    --arg     ackseq         "$METER1_ACKSEQ"         \
    --argjson aggtime        "$METER1_AGGTIME"        \
    --argjson interval       "$METER1_INTERVAL"       \
    --argjson read_timeout   "$METER1_READ_TIMEOUT"   \
    --argjson use_local_time "$METER1_USE_LOCAL_TIME" \
    --argjson channels       "$METER1_CHANNELS"       \
    '{
        protocol:         $protocol,
        enabled:          true,
        device:           $device,
        parity:           $parity,
        baudrate:         $baudrate,
        baudrate_read:    $baudrate_read,
        pullseq:          $pullseq,
        ackseq:           $ackseq,
        aggtime:          $aggtime,
        interval:         $interval,
        read_timeout:     $read_timeout,
        aggfixedinterval: true,
        duplicates:       60,
        use_local_time:   $use_local_time,
        channels:         $channels
    }')

# ── Optionally build meter2 ───────────────────────────────────────────────────
METER2_DEVICE="$(bashio::config 'meter2_device' '')"
[[ "$METER2_DEVICE" == "null" ]] && METER2_DEVICE=""

if [[ -n "$METER2_DEVICE" ]]; then
    echo "Enabling second meter ..."

    METER2_PROTOCOL="$(bashio::config 'meter2_protocol')"
    METER2_PARITY="$(bashio::config 'meter2_parity')"
    METER2_BAUDRATE="$(bashio::config 'meter2_baudrate')"
    METER2_BAUDRATE_READ="$(bashio::config 'meter2_baudrate_read')"
    METER2_PULLSEQ="$(bashio::config 'meter2_pullseq' '')"
    METER2_ACKSEQ="$(bashio::config 'meter2_ackseq' '')"
    METER2_AGGTIME="$(bashio::config 'meter2_aggtime')"
    METER2_INTERVAL="$(bashio::config 'meter2_interval')"
    METER2_READ_TIMEOUT="$(bashio::config 'meter2_read_timeout')"
    METER2_USE_LOCAL_TIME="$(bashio::config 'meter2_use_local_time')"

    [[ "$METER2_PULLSEQ" == "null" ]] && METER2_PULLSEQ=""
    [[ "$METER2_ACKSEQ"  == "null" ]] && METER2_ACKSEQ=""

    METER2_CHANNELS=$(jq '[.meter2_channels[] | {uuid: "1", api: "null", identifier: .identifier, aggmode: .aggmode}]' /data/options.json)

    METER2_OBJ=$(jq -n \
        --arg     protocol       "$METER2_PROTOCOL"      \
        --arg     device         "$METER2_DEVICE"         \
        --arg     parity         "$METER2_PARITY"         \
        --argjson baudrate       "$METER2_BAUDRATE"       \
        --argjson baudrate_read  "$METER2_BAUDRATE_READ"  \
        --arg     pullseq        "$METER2_PULLSEQ"        \
        --arg     ackseq         "$METER2_ACKSEQ"         \
        --argjson aggtime        "$METER2_AGGTIME"        \
        --argjson interval       "$METER2_INTERVAL"       \
        --argjson read_timeout   "$METER2_READ_TIMEOUT"   \
        --argjson use_local_time "$METER2_USE_LOCAL_TIME" \
        --argjson channels       "$METER2_CHANNELS"       \
        '{
            protocol:         $protocol,
            enabled:          true,
            device:           $device,
            parity:           $parity,
            baudrate:         $baudrate,
            baudrate_read:    $baudrate_read,
            pullseq:          $pullseq,
            ackseq:           $ackseq,
            aggtime:          $aggtime,
            interval:         $interval,
            read_timeout:     $read_timeout,
            aggfixedinterval: true,
            duplicates:       60,
            use_local_time:   $use_local_time,
            channels:         $channels
        }')

    METERS=$(jq -n --argjson m1 "$METER1_OBJ" --argjson m2 "$METER2_OBJ" '[$m1, $m2]')
else
    METERS=$(jq -n --argjson m1 "$METER1_OBJ" '[$m1]')
fi

# ── Generate /vzlogger.conf ───────────────────────────────────────────────────
echo "Generating vzlogger configuration ..."

jq -n \
    --argjson verbosity  "$VERBOSITY"    \
    --arg     broker     "$MQTT_BROKER"  \
    --argjson port       "$MQTT_PORT"    \
    --arg     username   "$MQTT_USERNAME" \
    --arg     password   "$MQTT_PASSWORD" \
    --arg     topic      "$MQTT_TOPIC"   \
    --argjson timestamp  "$MQTT_TIMESTAMP" \
    --argjson meters     "$METERS"       \
    '{
        retry:     10,
        daemon:    true,
        verbosity: $verbosity,
        log:       "/vzlogger.log",
        local: {
            enabled: false,
            port:    8081,
            index:   true,
            timeout: 30,
            buffer:  600
        },
        mqtt: {
            enabled:   true,
            host:      $broker,
            port:      $port,
            cafile:    "",
            capath:    "",
            certfile:  "",
            keyfile:   "",
            keypass:   "",
            keepalive: 30,
            topic:     $topic,
            user:      $username,
            pass:      $password,
            retain:    false,
            rawAndAgg: false,
            qos:       0,
            timestamp: $timestamp
        },
        meters: $meters
    }' > /vzlogger.conf

echo
echo "vzlogger.conf:"
echo
cat /vzlogger.conf
echo

echo "CMD: /usr/local/bin/vzlogger --foreground --config /vzlogger.conf"
/usr/local/bin/vzlogger --foreground --config /vzlogger.conf
echo
echo "vzlogger.log:"
echo
cat /vzlogger.log
