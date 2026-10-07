# Changelog

## 0.1.0

- First release. Clients share one MeshCore companion over TCP. Serial and Bluetooth stay behind dev mode.
- Assert DTR and RTS after opening a serial port, so a native-USB radio will transmit.
- Negotiate companion app version 3, and answer later client startups from the cached identity.
- Hold each queued message, including channel data, until that client sends GET_MSG.
- Echo a sent channel message as a V3 frame whose text starts with this node's name.
