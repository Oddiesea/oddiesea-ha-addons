# MeshCore TCP Proxy

The add-on listens on port 5000. Point companion clients at the Home Assistant host, on the address logged at startup. The log line looks like `tcp://192.168.1.20:5000`.

The radio itself stays on its own TCP companion port. This add-on is the only client that radio should have. Everyone else connects here.

## Radio

Set **Radio host** and **Radio port** to the companion's TCP endpoint. The default port is 5000, which is also the port this add-on publishes, so the two must not be the same service. The radio's port is the one in its Wi-Fi config. This add-on's port is the one clients use.

Contacts, channels, and the radio's identity are kept in SQLite under the add-on's data directory. A client that asks for those gets the stored copy, so the radio is not queried once per client.

**Clear cache** deletes that database on the next start, then turns itself off. Turn it on and restart the add-on. Clients see an empty list until the proxy has read the radio again. Channel secrets that existed only in the cache are dropped and read from the radio with the rest.

## MeshCore for Home Assistant

In the [MeshCore integration](https://github.com/meshcore-dev/meshcore-ha), choose connection type TCP. Use the host from the add-on log, and port 5000.

`127.0.0.1` is the Home Assistant core container, so it does not reach this add-on. The radio's own TCP port is also the wrong target when that port only accepts one client.

Leave **Retrieve queued incoming messages** on. The add-on keeps a copy of each queued message and returns it when that client asks. The integration's note about turning the setting off is for a phone sharing the radio directly. This add-on is that sharing.

A channel message sent through the add-on is echoed to the other clients with this node's name in front of the text, in the form `name: message`. The integration may treat that copy as your own send and hide it.

## Dev mode

**Dev mode** is off by default. Leave it off. The TCP path is the one Core Splitter's author tested, against a Heltec V3 on firmware v1.15.0.

Turning it on adds serial and Bluetooth as connection choices. Those backends are in the program and have not had a hardware test for this add-on. Serial and Bluetooth settings are ignored while dev mode is off, and the log says so if they were filled in.

## Log

**Log level** follows the usual names, `off` through `verbose`. **JSON log** writes one JSON object per protocol event.
