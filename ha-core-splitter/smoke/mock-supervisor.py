#!/usr/bin/env python3
"""Stand-in for the Supervisor API used by bashio during the listen-port smoke."""

import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

OPTIONS = json.loads(Path("/smoke/options.json").read_text())

INTERFACE = {
    "interface": "eth0",
    "type": "ethernet",
    "enabled": True,
    "ipv4": {
        "method": "static",
        "address": ["192.168.1.50/24"],
        "nameservers": ["192.168.1.1"],
        "gateway": "192.168.1.1",
    },
}


class Handler(BaseHTTPRequestHandler):
    def _read_body(self) -> None:
        length = int(self.headers.get("Content-Length", "0") or 0)
        if length:
            self.rfile.read(length)

    def _send(self, data: object) -> None:
        raw = json.dumps({"result": "ok", "data": data}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self) -> None:
        self._read_body()
        path = self.path.split("?", 1)[0]
        if path == "/addons/self/options/config":
            self._send(OPTIONS)
            return
        if path == "/addons/self/options":
            self._send({"options": OPTIONS})
            return
        if path == "/addons/self/info":
            self._send(
                {
                    "slug": "ha-core-splitter",
                    "name": "MeshCore TCP Proxy",
                    "options": OPTIONS,
                    "state": "started",
                }
            )
            return
        if path.startswith("/network/interface/") and path.endswith("/info"):
            self._send(INTERFACE)
            return
        if path == "/network/info":
            self._send({"interfaces": [INTERFACE]})
            return
        self._send({})

    def do_POST(self) -> None:
        self._read_body()
        self._send({})

    def log_message(self, fmt: str, *args: object) -> None:
        print(fmt % args)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 80), Handler).serve_forever()
