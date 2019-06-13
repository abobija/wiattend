# wiattend
RFID attendance system realized using MFRC522 and ESP32.

## Overview

When user apply RFID card on the RC522 module, ESP32 will detect presence of card and read the serial number. ESP will send serial number to the NodeJS server ([wiattend-srv](https://github.com/abobija/wiattend-srv)). Server will save new log in MySQL database, then broadcast `JSON` logged tag to the clients ([wiattend-client](https://github.com/abobija/wiattend-client)) via permanent WebSocket channels, and at the end return `JSON` logged tag, as well, back to the ESP32.

## Demo

[![RFID Attendance System - ESP32 - NodeJS + MySQL](https://img.youtube.com/vi/TH8eR9hSwzc/mqdefault.jpg)](https://www.youtube.com/watch?v=TH8eR9hSwzc)

## Usage

**Tip!** Make sure to include `--recurse-submodules` option in time of cloning

```
git clone --recurse-submodules "https://github.com/abobija/wiattend.git"
```

Install dependencies

```
npm i
```

Connect ESP32 and run next command to upload files (set correct COM port of your ESP).

```
npm run upload -- --port=COM7
```

## Used Technologies

  - [NodeJS](https://nodejs.org) ([HTTP](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol), [WebSocket](https://en.wikipedia.org/wiki/WebSocket))
  - [MySQL](https://www.mysql.com/) (DBMS)
  - [Lua for ESP32](https://nodemcu.readthedocs.io/en/dev-esp32) (IoT)

## Dependencies

Project depends on the following NodeMCU modules:

  - `gpio`
  - `file`
  - `node`
  - `net`
  - `http`
  - `wifi`
  - `sjson`
  - `tmr`
  - `ledc`
  - Modules required by [`rfid32`](https://github.com/abobija/rfid32#dependencies) library
