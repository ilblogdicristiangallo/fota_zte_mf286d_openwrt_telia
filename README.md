# MF286D FOTA Update Script

Shell script for sequential FOTA firmware updates on **ZTE MF286D** running **OpenWrt**.

This repository contains:

- the update scripts
- the firmware update folders
- the required `delta.package` and `delta.signature` files

The script automatically detects the current firmware version and runs only the required update steps in the correct order.

---

## Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/ilblogdicristiangallo/fota_zte_mf286d_openwrt_telia/main/fota1.png" width="32%" />
  <img src="https://raw.githubusercontent.com/ilblogdicristiangallo/fota_zte_mf286d_openwrt_telia/main/fota2.png" width="32%" />
  <img src="https://raw.githubusercontent.com/ilblogdicristiangallo/fota_zte_mf286d_openwrt_telia/main/fota3.png" width="32%" />
</p>

---

# Italiano

## Descrizione

Questo repository contiene tutto il necessario per eseguire aggiornamenti **FOTA sequenziali** su **ZTE MF286D** con **OpenWrt**.

Sono presenti:

- gli script di aggiornamento
- le cartelle firmware
- i file `delta.package`
- i file `delta.signature`

Lo script:

1. legge la versione firmware attuale
2. decide da quale aggiornamento partire
3. copia i file firmware sul dispositivo tramite `adb`
4. invia i comandi AT FOTA sulla seriale
5. aspetta i tempi necessari
6. ripete upload e comandi una seconda volta
7. verifica la nuova versione installata
8. passa automaticamente all'aggiornamento successivo

Se una versione è già installata, lo script parte direttamente dalla successiva.

---

## Script disponibili

Nel repository sono disponibili due script:

- versione italiana: `fota_it.sh`
- versione inglese: `fota_en.sh`

Entrambi fanno esattamente la stessa cosa.  
Cambia solo la lingua dei messaggi mostrati a schermo e salvati nel log.

### Percorso consigliato sul router/modem

Gli script devono essere copiati in:

```bash
/tmp/fota_it.sh
/tmp/fota_en.sh

# MF286D FOTA Update Script

Shell script for sequential FOTA firmware updates on **ZTE MF286D** running **OpenWrt**.

The script automatically detects the current firmware version and runs only the required update steps in the correct order using:

- **ADB** for file transfer
- **AT commands** over serial port for FOTA control

---

## Overview

This project is designed to automate firmware updates on the **ZTE MF286D**.

The script:

1. reads the current firmware version from the modem
2. decides which update step must run first
3. uploads `delta.package` and `delta.signature` using `adb`
4. sends the required FOTA AT commands over the serial interface
5. waits for the required flash time
6. uploads the update files again
7. sends the FOTA AT commands a second time
8. waits again for final FOTA processing
9. checks the installed firmware version
10. automatically moves to the next update step

If a firmware version is already installed, the script skips it and starts from the next one.
