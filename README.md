<h1 align="center">⚡ MF286D FOTA Update Script</h1>

<p align="center">
  <b>Shell script for sequential FOTA firmware updates on ZTE MF286D running OpenWrt</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Device-ZTE%20MF286D-blue" />
  <img src="https://img.shields.io/badge/OS-OpenWrt%2025-green" />
  <img src="https://img.shields.io/badge/Shell-BusyBox-orange" />
  <img src="https://img.shields.io/badge/Transfer-ADB-red" />
  <img src="https://img.shields.io/badge/Commands-AT%20Serial-purple" />
  <img src="https://img.shields.io/badge/Language-IT%20%2F%20EN-yellow" />
</p>

---

## Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/ilblogdicristiangallo/fota_zte_mf286d_openwrt_telia/main/fota1.png" width="32%" />
  <img src="https://raw.githubusercontent.com/ilblogdicristiangallo/fota_zte_mf286d_openwrt_telia/main/fota2.png" width="32%" />
  <img src="https://raw.githubusercontent.com/ilblogdicristiangallo/fota_zte_mf286d_openwrt_telia/main/fota3.png" width="32%" />
</p>

---

## Contenuto del repository / Repository contents

Questo repository contiene / This repository contains:

- `fota_it.sh` → script con messaggi in **italiano**
- `fota_en.sh` → script with messages in **English**
- `telia-05/` → firmware B05
- `telia-06/` → firmware B06
- `telia-08/` → firmware B08
- `telia-09/` → firmware B09
- `telia-10/` → firmware B10
- `telia-11/` → firmware B11
- `telia-12/` → firmware B12

Dentro ogni cartella `telia-xx` ci sono due file:  
Inside every `telia-xx` folder there are two files:

- `delta.package`
- `delta.signature`

---


---

# Italiano

## Descrizione

Questo progetto permette di aggiornare il firmware del **ZTE MF286D** in modo **automatico e sequenziale**.

Lo script utilizza:

- **ADB** per copiare i file firmware sul dispositivo
- **comandi AT** sulla porta seriale per avviare il processo FOTA
- rilevamento automatico della **versione firmware attuale**
- esecuzione automatica solo degli **aggiornamenti necessari**
- un **timer countdown** in tempo reale visibile a schermo
- un **file di log** completo salvato su disco
- **due tentativi** per ogni aggiornamento in caso di errore

---

### Come funziona lo script

Lo script esegue queste operazioni automaticamente:

1. legge la versione firmware attuale dal modem
2. confronta la versione con la lista degli aggiornamenti disponibili
3. decide automaticamente da quale aggiornamento partire
4. per ogni aggiornamento necessario:
   - copia i file `delta.package` e `delta.signature` sul dispositivo
   - invia la prima sequenza di comandi AT FOTA
   - aspetta 10 minuti per il processo di flash
   - copia di nuovo i file `delta.package` e `delta.signature`
   - invia la seconda sequenza di comandi AT FOTA
   - aspetta 3 minuti per il completamento
   - verifica che la versione firmware sia stata aggiornata
5. se l'aggiornamento riesce, passa automaticamente al successivo
6. se fallisce, ritenta una seconda volta
7. se fallisce due volte, lo script si ferma

Se una versione è già installata, viene saltata e lo script parte direttamente dalla successiva.

---

## Script disponibili

Nel repository sono presenti **due script identici nella logica** ma con lingua diversa:

| Script | Lingua dei messaggi |
|---|---|
| `fota_it.sh` | Italiano |
| `fota_en.sh` | English |

I due script fanno la **stessa identica cosa**.  
Cambia solo la lingua dei messaggi:

- mostrati a schermo durante l'esecuzione
- scritti nel file di log

Scegli quello che preferisci.

---

## Requisiti

Prima di iniziare assicurati di avere:

- un modem/router **ZTE MF286D**
- **OpenWrt** installato sul dispositivo (testato su OpenWrt 25)
- accesso **SSH** al dispositivo
- connessione **ADB** funzionante tra il dispositivo e il modem
- porta seriale AT disponibile e funzionante su:


<pre>/dev/ttyUSB1</pre>

## Description

This project allows you to update the **ZTE MF286D** firmware **automatically and sequentially**.

The script utilizes:

- **ADB** to copy firmware files to the device
- **AT commands** via the serial port to initiate the FOTA process
- automatic detection of the **current firmware version**
- automatic execution of **only the necessary updates**
- a real-time **countdown timer** displayed on screen
- a comprehensive **log file** saved to disk
- **two attempts** per update in case of error

---

### How the script works

The script performs the following operations automatically:

1. reads the current firmware version from the modem
2. compares the version against the list of available updates
3. automatically determines which update to start with
4. for each required update:
   - copies the `delta.package` and `delta.signature` files to the device
   - sends the first sequence of FOTA AT commands
   - waits 10 minutes for the flashing process
   - copies the `delta.package` and `delta.signature` files again
   - sends the second sequence of FOTA AT commands
   - waits 3 minutes for completion
   - verifies that the firmware version has been updated
5. if the update succeeds, it automatically proceeds to the next one
6. if it fails, it retries a second time
7. if it fails twice, the script stops

If a version is already installed, it is skipped, and the script proceeds directly to the next one.

