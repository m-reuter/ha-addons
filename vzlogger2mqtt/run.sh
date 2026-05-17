#!/usr/bin/with-contenv bashio

# ── MQTT settings ────────────────────────────────────────────────────────────
VERBOSITY="$(bashio::config 'verbosity')"
MQTT_BROKER="$(bashio::config 'mqtt_broker')"
MQTT_PORT="$(bashio::config 'mqtt_port')"
MQTT_USERNAME="$(bashio::config 'mqtt_username')"
MQTT_PASSWORD="$(bashio::config 'mqtt_password')"
MQTT_TOPIC="$(bashio::config 'mqtt_topic')"
MQTT_TIMESTAMP="$(bashio::config 'mqtt_timestamp')"
MQTT_CAFILE="$(bashio::config 'mqtt_cafile' '')"
MQTT_CAPATH="$(bashio::config 'mqtt_capath' '')"
MQTT_CERTFILE="$(bashio::config 'mqtt_certfile' '')"
MQTT_KEYFILE="$(bashio::config 'mqtt_keyfile' '')"
MQTT_KEYPASS="$(bashio::config 'mqtt_keypass' '')"

# null → empty string for optional fields
[[ "$MQTT_CAFILE"   == "null" ]] && MQTT_CAFILE=""
[[ "$MQTT_CAPATH"   == "null" ]] && MQTT_CAPATH=""
[[ "$MQTT_CERTFILE" == "null" ]] && MQTT_CERTFILE=""
[[ "$MQTT_KEYFILE"  == "null" ]] && MQTT_KEYFILE=""
[[ "$MQTT_KEYPASS"  == "null" ]] && MQTT_KEYPASS=""

configure_serial_device() {
    local device="$1"
    local baudrate="$2"
    local parity="$3"

    if ! command -v stty >/dev/null 2>&1 || [[ ! -e "$device" ]]; then
        return 0
    fi

    local databits="${parity:0:1}"
    local parity_mode="${parity:1:1}"
    local stopbits="${parity:2:1}"
    local stty_args=(raw "$baudrate" -echo -ixon -ixoff -crtscts clocal)

    case "$databits" in
        7) stty_args+=(cs7) ;;
        8) stty_args+=(cs8) ;;
    esac

    case "$parity_mode" in
        [Nn]) stty_args+=(-parenb -parodd) ;;
        [Ee]) stty_args+=(parenb -parodd) ;;
        [Oo]) stty_args+=(parenb parodd) ;;
    esac

    case "$stopbits" in
        1) stty_args+=(-cstopb) ;;
        2) stty_args+=(cstopb) ;;
    esac

    stty -F "$device" "${stty_args[@]}" 2>/dev/null || true
}

drain_serial_device() {
    local device="$1"
    local baudrate="$2"
    local parity="$3"
    local label="$4"
    local drained=0
    local deadline
    local fd

    if [[ -z "$device" || "$device" != /dev/* || ! -e "$device" ]]; then
        return 0
    fi

    echo "Preparing ${label} device ${device} ..."
    configure_serial_device "$device" "$baudrate" "$parity"

    if ! exec {fd}<"$device"; then
        echo "Warning: could not open ${device} to drain stale input."
        return 0
    fi

    deadline=$((SECONDS + 5))
    while (( SECONDS < deadline )); do
        if IFS= read -r -t 0.2 -u "$fd" -N 1; then
            ((drained += 1))
            while IFS= read -r -t 0.05 -u "$fd" -N 1; do
                ((drained += 1))
            done
        else
            break
        fi
    done

    exec {fd}<&-

    if (( drained > 0 )); then
        echo "Discarded ${drained} stale byte(s) from ${label} before startup."
    else
        echo "No stale bytes waiting on ${label}."
    fi
}

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

    # Apply defaults for optional fields that may come back as "null"
    [[ "$METER2_PROTOCOL"       == "null" ]] && METER2_PROTOCOL="sml"
    [[ "$METER2_PARITY"         == "null" ]] && METER2_PARITY="8N1"
    [[ "$METER2_BAUDRATE"       == "null" ]] && METER2_BAUDRATE=9600
    [[ "$METER2_BAUDRATE_READ"  == "null" ]] && METER2_BAUDRATE_READ=9600
    [[ "$METER2_PULLSEQ"        == "null" ]] && METER2_PULLSEQ=""
    [[ "$METER2_ACKSEQ"         == "null" ]] && METER2_ACKSEQ=""
    [[ "$METER2_AGGTIME"        == "null" ]] && METER2_AGGTIME=10
    [[ "$METER2_INTERVAL"       == "null" ]] && METER2_INTERVAL=0
    [[ "$METER2_READ_TIMEOUT"   == "null" ]] && METER2_READ_TIMEOUT=10
    [[ "$METER2_USE_LOCAL_TIME" == "null" ]] && METER2_USE_LOCAL_TIME=false

    METER2_CHANNELS=$(jq '[(.meter2_channels // [])[] | {uuid: "1", api: "null", identifier: .identifier, aggmode: .aggmode}]' /data/options.json)

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
    --arg     cafile     "$MQTT_CAFILE"  \
    --arg     capath     "$MQTT_CAPATH"  \
    --arg     certfile   "$MQTT_CERTFILE" \
    --arg     keyfile    "$MQTT_KEYFILE" \
    --arg     keypass    "$MQTT_KEYPASS" \
    --argjson meters     "$METERS"       \
    '{
        retry:     10,
        daemon:    true,
        verbosity: $verbosity,
        log:       "/vzlogger.log",
        local: {
            enabled: true,
            port:    8081,
            index:   true,
            timeout: 30,
            buffer:  600
        },
        mqtt: {
            enabled:   true,
            host:      $broker,
            port:      $port,
            cafile:    $cafile,
            capath:    $capath,
            certfile:  $certfile,
            keyfile:   $keyfile,
            keypass:   $keypass,
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
echo "vzlogger.conf (sensitive values redacted):"
echo
jq '
    .mqtt.pass |= if . == "" then . else "<redacted>" end
    | .mqtt.keypass |= if . == "" then . else "<redacted>" end
' /vzlogger.conf
echo

# Give the serial device time to finish enumerating after an HA restart
sleep 3

drain_serial_device "$METER1_DEVICE" "$METER1_BAUDRATE_READ" "$METER1_PARITY" "meter1"
drain_serial_device "$METER2_DEVICE" "${METER2_BAUDRATE_READ:-9600}" "${METER2_PARITY:-8N1}" "meter2"

# Reset the log on each start so stale output does not accumulate across restarts.
: > /vzlogger.log

echo "CMD: /usr/local/bin/vzlogger --foreground --config /vzlogger.conf"
/usr/local/bin/vzlogger --foreground --config /vzlogger.conf
echo
if [[ -f /vzlogger.log ]]; then
    echo "vzlogger.log:"
    echo
    cat /vzlogger.log
else
    echo "vzlogger.log not found"
fi
