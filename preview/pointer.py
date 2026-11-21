"""One virtual pointer that lives as long as the preview.

A pointer made for each command would come and go, and every time the seat
loses its pointer the clients drop theirs. A click on a new pointer comes
before any enter event, so GTK ignores it. This server keeps one pointer and
takes commands on a Unix socket.
"""

import argparse
import os
import socket
import sys
import time

from chena_preview_protocols.wayland import WlSeat
from chena_preview_protocols.wlr_virtual_pointer_unstable_v1 import (
    ZwlrVirtualPointerManagerV1,
)
from pywayland.client import Display

# From linux/input-event-codes.h.
BUTTONS = {"left": 0x110, "right": 0x111, "middle": 0x112}
PRESSED = 1
RELEASED = 0

AXIS_VERTICAL = 0
AXIS_SOURCE_WHEEL = 0
# The distance libinput reports for one wheel step.
WHEEL_STEP = 15.0

# Absolute motion takes integers, so positions are sent in hundredths of a
# pixel to keep fractional layout sizes exact enough.
PRECISION = 100


def now():
    return int(time.monotonic() * 1000) & 0xFFFFFFFF


class Pointer:
    def __init__(self, width, height):
        self.display = Display()
        self.display.connect()

        found = {}
        registry = self.display.get_registry()
        registry.dispatcher["global"] = (
            lambda _registry, name, interface, _version: found.__setitem__(interface, name)
        )
        self.display.roundtrip()

        seat = registry.bind(found["wl_seat"], WlSeat, 1)
        manager = registry.bind(
            found["zwlr_virtual_pointer_manager_v1"], ZwlrVirtualPointerManagerV1, 1
        )
        self.device = manager.create_virtual_pointer(seat)
        self.extent = (round(width * PRECISION), round(height * PRECISION))
        self.display.roundtrip()

    def move(self, x, y):
        self.device.motion_absolute(
            now(), round(x * PRECISION), round(y * PRECISION), *self.extent
        )
        self.device.frame()

    def button(self, name, state):
        if name not in BUTTONS:
            raise ValueError(f"unknown button {name}")
        self.device.button(now(), BUTTONS[name], state)
        self.device.frame()

    def click(self, name):
        self.button(name, PRESSED)
        self.button(name, RELEASED)

    def scroll(self, steps):
        self.device.axis_source(AXIS_SOURCE_WHEEL)
        self.device.axis_discrete(now(), AXIS_VERTICAL, steps * WHEEL_STEP, steps)
        self.device.frame()

    def run(self, words):
        match words:
            case ["move", x, y]:
                self.move(float(x), float(y))
            case ["press", name]:
                self.button(name, PRESSED)
            case ["release", name]:
                self.button(name, RELEASED)
            case ["click", name]:
                self.click(name)
            case ["scroll", steps]:
                self.scroll(int(steps))
            case _:
                raise ValueError(f"unknown command {' '.join(words)}")
        self.display.roundtrip()


def serve(path, width, height, scale):
    pointer = Pointer(width / scale, height / scale)
    if os.path.exists(path):
        os.unlink(path)
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(path)
    server.listen()
    while True:
        connection, _ = server.accept()
        with connection:
            words = connection.makefile().readline().split()
            try:
                pointer.run(words)
                reply = "ok\n"
            except ValueError as error:
                reply = f"error: {error}\n"
            connection.sendall(reply.encode())


def send(path, words):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.connect(path)
        client.sendall((" ".join(words) + "\n").encode())
        reply = client.makefile().readline().strip()
    if reply != "ok":
        print(reply, file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(prog="chena-preview-pointer")
    commands = parser.add_subparsers(dest="command", required=True)

    serve_parser = commands.add_parser("serve")
    serve_parser.add_argument("socket")
    serve_parser.add_argument("width", type=int)
    serve_parser.add_argument("height", type=int)
    serve_parser.add_argument("scale", type=float)

    send_parser = commands.add_parser("send")
    send_parser.add_argument("socket")
    send_parser.add_argument("words", nargs="+")

    args = parser.parse_args()
    if args.command == "serve":
        serve(args.socket, args.width, args.height, args.scale)
    else:
        send(args.socket, args.words)


if __name__ == "__main__":
    main()
