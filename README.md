# wiattend
RFID attendance system realized using MFRC522 and ESP32.

## Overview

When user apply RFID card on the RC522 module, ESP32 will detect presence of card and read the serial number. ESP will send serial number to the NodeJS server ([wiattend-srv](https://github.com/abobija/wiattend-srv)). Server will save new log in MySQL database, then broadcast `JSON` logged tag to the clients ([wiattend-client](https://github.com/abobija/wiattend-client)) via permanent WebSocket channels, and at the end return `JSON` logged tag, as well, back to the ESP32.

## Demo

[![RFID Attendance System - ESP32 - NodeJS + MySQL](https://img.youtube.com/vi/TH8eR9hSwzc/mqdefault.jpg)](https://www.youtube.com/watch?v=TH8eR9hSwzc)

## Usage

Upload next files to ESP32 (using [ESPLorer](https://www.youtube.com/watch?v=ICRAlUCPpwY&t=23s) or some other tools):
  - `config.json`
  - `config_io.lua`
  - `rfid32/rfid32.lua`
  - `piezo.lua`
  - `init.lua`

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
