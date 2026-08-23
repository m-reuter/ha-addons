#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import configparser
import fcntl
import os
import sys

try:
    import can
except Exception:
    pass

LOCK_FILE = "/run/pyhpsu-can.lock"


class CanPI(object):
    hpsu = None
    timeout = None
    retry = None

    def __init__(self, hpsu=None):
        self.hpsu = hpsu
        try:
            self.bus = can.interface.Bus(channel="can0", bustype="socketcan")
        except can.CanInterfaceNotImplementedError:
            self.bus = can.interface.Bus(channel="can0", bustype="socketcan_native")
        except Exception:
            self.hpsu.printd("exception", "Error opening bus can0")
            sys.exit(9)

        config = configparser.ConfigParser()
        ini_file = "%s/%s.conf" % (self.hpsu.pathCOMMANDS, "pyhpsu")
        config.read(ini_file)
        self.timeout = float(self.get_with_default(config=config, section="CANPI", name="timeout", default=0.05))
        self.retry = float(self.get_with_default(config=config, section="CANPI", name="retry", default=15))

    def __del__(self):
        bus = getattr(self, "bus", None)
        if bus is not None:
            try:
                bus.shutdown()
            except Exception:
                pass

    def get_with_default(self, config, section, name, default):
        if "config" not in config.sections():
            return default

        if config.has_option(section, name):
            return config.get(section, name)
        return default

    def make_can_message(self, receiver, data):
        try:
            return can.Message(
                arbitration_id=receiver,
                data=data,
                is_extended_id=False,
            )
        except TypeError:
            return can.Message(
                arbitration_id=receiver,
                data=data,
                extended_id=False,
                dlc=len(data),
            )

    def sendCommandWithID(self, cmd, setValue=None, priority=1):
        if setValue:
            receiver_id = 0x680
        else:
            receiver_id = int(cmd["id"], 16)
        command = cmd["command"]

        if setValue:
            command = command[:1] + "2" + command[2:]
            if command[6:8] != "FA":
                command = command[:3] + "00 FA" + command[2:8]
            command = command[:14]
            if cmd["type"] == "longint":
                setValue = int(setValue)
                command = command + " 00 %02X" % (setValue)
            if cmd["type"] == "int":
                setValue = int(setValue)
                command = command + " %02X 00" % (setValue)
            if cmd["type"] == "float":
                setValue = int(setValue)
                if setValue < 0:
                    setValue = 0x10000 + setValue
                command = command + " %02X %02X" % (setValue >> 8, setValue & 0xFF)
            if cmd["type"] == "value":
                setValue = int(setValue)
                command = command + " 00 %02X" % (setValue)

        msg_data = [int(r, 16) for r in command.split(" ")]

        os.makedirs(os.path.dirname(LOCK_FILE), exist_ok=True)
        with open(LOCK_FILE, "w") as lock_handle:
            fcntl.flock(lock_handle, fcntl.LOCK_EX)
            return self._exchange(receiver_id, msg_data, setValue=setValue)

    def _exchange(self, receiver_id, msg_data, setValue=None):
        not_timeout = True
        retry_count = 0

        try:
            msg = self.make_can_message(receiver_id, msg_data)
            self.bus.send(msg)
        except Exception as exc:
            self.hpsu.printd("exception", f"Error sending msg: {exc}")

        if setValue:
            return "OK"

        while not_timeout:
            retry_count += 1
            rc_bus = None
            try:
                rc_bus = self.bus.recv(self.timeout)
            except Exception:
                self.hpsu.printd("exception", "Error recv")

            if rc_bus:
                if (
                        msg_data[2] == 0xFA
                        and msg_data[3] == rc_bus.data[3]
                        and msg_data[4] == rc_bus.data[4]
                ) or (msg_data[2] != 0xFA and msg_data[2] == rc_bus.data[2]):
                    return "%02X %02X %02X %02X %02X %02X %02X" % (
                        rc_bus.data[0],
                        rc_bus.data[1],
                        rc_bus.data[2],
                        rc_bus.data[3],
                        rc_bus.data[4],
                        rc_bus.data[5],
                        rc_bus.data[6],
                    )

                self.hpsu.printd("error", "SEND:%s" % (str(msg_data)))
                self.hpsu.printd("error", "RECV:%s" % (str(rc_bus.data)))
            else:
                self.hpsu.printd("error", "Not aquired bus")

            self.hpsu.printd("warning", "msg not sync, retry: %s" % retry_count)
            if retry_count >= self.retry:
                self.hpsu.printd("error", "msg not sync, timeout")
                not_timeout = False

        return "KO"
