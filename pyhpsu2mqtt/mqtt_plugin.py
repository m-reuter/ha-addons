#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import configparser
import os
import paho.mqtt.client as mqtt
import sys


def make_client(client_id):
    try:
        return mqtt.Client(
            callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
            client_id=client_id,
        )
    except (AttributeError, TypeError, ValueError):
        return mqtt.Client(client_id=client_id)


class export:
    hpsu = None

    def __init__(self, hpsu=None, logger=None, config_file=None):
        self.hpsu = hpsu
        self.logger = logger
        self.config_file = config_file
        self.config = configparser.ConfigParser()
        if os.path.isfile(self.config_file):
            self.config.read(self.config_file)
        else:
            sys.exit(9)

        mqtt_config = self.config["MQTT"]
        self.brokerhost = mqtt_config.get("BROKER", "localhost")
        self.brokerport = mqtt_config.getint("PORT", 1883)
        self.clientname = mqtt_config.get("CLIENTNAME", "rotex")
        self.username = mqtt_config.get("USERNAME", None)
        self.password = mqtt_config.get("PASSWORD", "NoPasswordSpecified")
        self.prefix = mqtt_config.get("PREFIX", "")
        self.qos = mqtt_config.getint("QOS", 0)
        self.retain = mqtt_config.get("RETAIN", "NOT TRUE") == "True"

        client_name = f"{self.clientname}-{os.getpid()}"
        self.client = make_client(client_name)
        if self.username:
            self.client.username_pw_set(self.username, password=self.password)
        self.client.enable_logger()
        self.client.reconnect_delay_set(min_delay=1, max_delay=30)
        self.client.connect_async(self.brokerhost, port=self.brokerport)
        self.client.loop_start()

    def pushValues(self, vars=None):
        for item in vars or []:
            if self.prefix:
                topic = f"{self.prefix}/{item['name']}"
            else:
                topic = item["name"]
            self.client.publish(
                topic,
                payload=item["resp"],
                qos=int(self.qos),
                retain=self.retain,
            )

    def __del__(self):
        client = getattr(self, "client", None)
        if client is not None:
            try:
                client.loop_stop()
                client.disconnect()
            except Exception:
                pass
