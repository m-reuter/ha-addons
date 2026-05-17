#!/usr/bin/env python3

import configparser
import logging
import os
import subprocess
import sys

import paho.mqtt.client as mqtt


LOGGER = logging.getLogger("pyhpsu-mqtt-command-daemon")


def make_client(client_id):
    try:
        return mqtt.Client(
            callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
            client_id=client_id,
        )
    except (AttributeError, TypeError, ValueError):
        return mqtt.Client(client_id=client_id)


def load_config(path):
    config = configparser.ConfigParser()
    if not config.read(path):
        raise FileNotFoundError(f"config file not found: {path}")
    return config


def mqtt_settings(config):
    section = config["MQTT"]
    prefix = section.get("PREFIX", "").strip("/")
    command_topic = section.get("COMMANDTOPIC", section.get("COMMAND", "command")).strip("/")
    return {
        "broker": section.get("BROKER", "localhost"),
        "port": section.getint("PORT", 1883),
        "username": section.get("USERNAME", fallback=None) or None,
        "password": section.get("PASSWORD", fallback=None) or None,
        "clientname": section.get("CLIENTNAME", "rotex_hpsu"),
        "prefix": prefix,
        "command_topic": command_topic,
        "qos": section.getint("QOS", 0),
    }


def run_pyhpsu(conf_path, command, publish_result):
    cmd = ["pyHPSU.py", "-f", conf_path, "-c", command]
    if publish_result:
        cmd.extend(["-o", "MQTT"])

    LOGGER.info("Running %s", " ".join(cmd))
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        LOGGER.error("pyHPSU command failed (%s): %s", result.returncode, command)
        if result.stdout:
            LOGGER.error("stdout: %s", result.stdout.strip())
        if result.stderr:
            LOGGER.error("stderr: %s", result.stderr.strip())
    elif result.stdout.strip():
        LOGGER.debug("stdout: %s", result.stdout.strip())
    elif result.stderr.strip():
        LOGGER.debug("stderr: %s", result.stderr.strip())

    return result.returncode == 0


def on_connect(client, _userdata, _flags, reason_code, _properties=None):
    if reason_code != 0:
        LOGGER.error("MQTT connect failed with code %s", reason_code)
        return

    subscribe_topic = client.user_data_get()["subscribe_topic"]
    qos = client.user_data_get()["qos"]
    LOGGER.info("Subscribing to %s", subscribe_topic)
    client.subscribe(subscribe_topic, qos=qos)


def on_message(_client, userdata, message):
    command = message.topic.rsplit("/", 1)[-1]
    payload = message.payload.decode("utf-8").strip()
    LOGGER.info("Received MQTT command %s=%s", command, payload or "<read>")

    if payload.lower() in ("", "read"):
        run_pyhpsu(userdata["conf_path"], command, publish_result=True)
        return

    if run_pyhpsu(userdata["conf_path"], f"{command}:{payload}", publish_result=False):
        run_pyhpsu(userdata["conf_path"], command, publish_result=True)


def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

    conf_path = sys.argv[1] if len(sys.argv) > 1 else "/etc/pyHPSU/pyhpsu.conf"
    config = load_config(conf_path)
    settings = mqtt_settings(config)

    subscribe_topic = "/".join(part for part in (settings["prefix"], settings["command_topic"], "+") if part)
    client_id = f"{settings['clientname']}-mqttdaemon-{os.getpid()}"

    client = make_client(client_id)
    if settings["username"]:
        client.username_pw_set(settings["username"], settings["password"])
    client.user_data_set(
        {
            "conf_path": conf_path,
            "subscribe_topic": subscribe_topic,
            "qos": settings["qos"],
        }
    )
    client.on_connect = on_connect
    client.on_message = on_message

    LOGGER.info("Connecting to MQTT broker %s:%s", settings["broker"], settings["port"])
    client.connect(settings["broker"], settings["port"])
    client.loop_forever()


if __name__ == "__main__":
    main()
