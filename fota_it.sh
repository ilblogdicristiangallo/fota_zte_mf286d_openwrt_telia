#!/bin/sh

BASE="/tmp"
TTY="/dev/ttyUSB1"
LOG="/tmp/fota_update.log"
TMP_ATI="/tmp/ati_resp.txt"

AT_CMD="AT+FOTACTR"

# --------------------------------------------------
pause() {
    sleep 5
}

# --------------------------------------------------
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"
}

# --------------------------------------------------
log_file() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

# --------------------------------------------------
send_at() {
    printf '%s\r' "$1" > "$TTY"
    pause
}

# --------------------------------------------------
countdown() {
    LABEL="$1"
    SECS="$2"

    log "$LABEL - durata ${SECS}s"

    while [ "$SECS" -gt 0 ]; do
        MINS=$((SECS / 60))
        REST=$((SECS % 60))
        printf "\r>>> %s: %02d:%02d rimanenti " "$LABEL" "$MINS" "$REST"
        sleep 1
        SECS=$((SECS - 1))
    done

    printf "\r>>> %s: COMPLETATO              \n" "$LABEL"
}

# --------------------------------------------------
read_version() {
    rm -f "$TMP_ATI"

    # Pulisce buffer seriale
    cat "$TTY" > /dev/null 2>&1 &
    CLEAN_PID=$!
    sleep 1
    kill "$CLEAN_PID" 2>/dev/null

    # Avvia cattura
    cat "$TTY" > "$TMP_ATI" 2>/dev/null &
    CAT_PID=$!
    sleep 1

    # Invia ATI
    printf 'ATI\r' > "$TTY"
    sleep 3

    kill "$CAT_PID" 2>/dev/null
    sleep 1

    RESP=$(cat "$TMP_ATI" 2>/dev/null)

    log_file "----- ATI RESPONSE -----"
    log_file "$RESP"
    log_file "------------------------"

    VERSION=$(echo "$RESP" | tr -d '\r' | grep "Revision" | sed -n 's/.*\(B[0-9][0-9]\).*/\1/p' | tail -n1)

    printf '%s' "$VERSION"
}

# --------------------------------------------------
do_update() {
    FOLDER="$1"
    TARGET="$2"

    log "=================================="
    log "INSTALLING: $FOLDER -> $TARGET"
    log "=================================="

    if [ ! -f "$BASE/$FOLDER/delta.package" ] || [ ! -f "$BASE/$FOLDER/delta.signature" ]; then
        log "ERRORE: file mancanti in $BASE/$FOLDER"
        return 1
    fi

    # --------------------------------------------------
    # PRIMO UPLOAD FILE
    # --------------------------------------------------
    log "PRIMO UPLOAD delta.package"
    adb push "$BASE/$FOLDER/delta.package" /cache/
    pause

    log "PRIMO UPLOAD delta.signature"
    adb push "$BASE/$FOLDER/delta.signature" /cache/
    pause

    # --------------------------------------------------
    # PRIMA SEQUENZA FOTA
    # --------------------------------------------------
    log "INVIO COMANDI AT FOTA - PRIMA SEQUENZA"
    send_at "${AT_CMD}=0"
    send_at "${AT_CMD}=1"
    send_at "${AT_CMD}=5"
    send_at "${AT_CMD}=8"
    send_at "${AT_CMD}=2"

    # --------------------------------------------------
    # ATTESA FLASH 10 MINUTI
    # --------------------------------------------------
    countdown "FLASH IN CORSO" 600

    # --------------------------------------------------
    # SECONDO UPLOAD FILE
    # --------------------------------------------------
    log "SECONDO UPLOAD delta.package"
    adb push "$BASE/$FOLDER/delta.package" /cache/
    pause

    log "SECONDO UPLOAD delta.signature"
    adb push "$BASE/$FOLDER/delta.signature" /cache/
    pause

    # --------------------------------------------------
    # SECONDA SEQUENZA FOTA
    # --------------------------------------------------
    log "INVIO COMANDI AT FOTA - SECONDA SEQUENZA"
    send_at "${AT_CMD}=0"
    send_at "${AT_CMD}=1"
    send_at "${AT_CMD}=5"
    send_at "${AT_CMD}=8"
    send_at "${AT_CMD}=2"

    # --------------------------------------------------
    # ATTESA 3 MINUTI PER NUOVI FOTA
    # --------------------------------------------------
    countdown "ATTESA NUOVI FOTA" 180

    # --------------------------------------------------
    # VERIFICA VERSIONE
    # --------------------------------------------------
    log "VERIFICA VERSIONE POST UPDATE"
    NEW_VER=$(read_version)
    log "VERSIONE DOPO UPDATE: [$NEW_VER]"

    if [ "$NEW_VER" = "$TARGET" ]; then
        log "OK: $TARGET installata correttamente"
        return 0
    fi

    log "ERRORE: atteso [$TARGET] ma trovato [$NEW_VER]"
    return 1
}
# --------------------------------------------------
# MAIN
# --------------------------------------------------

log "=================================="
log "START FOTA ENGINE MF286D"
log "=================================="

VER=$(read_version)
log "VERSIONE ATTUALE LETTA: [$VER]"

if [ -z "$VER" ]; then
    log "ERRORE: impossibile leggere la versione attuale"
    exit 1
fi

# --------------------------------------------------
# DECIDE DA DOVE PARTIRE
# --------------------------------------------------
case "$VER" in
    B05) UPDATES="telia-06:B06 telia-08:B08 telia-09:B09 telia-10:B10 telia-11:B11 telia-12:B12" ;;
    B06) UPDATES="telia-08:B08 telia-09:B09 telia-10:B10 telia-11:B11 telia-12:B12" ;;
    B08) UPDATES="telia-09:B09 telia-10:B10 telia-11:B11 telia-12:B12" ;;
    B09) UPDATES="telia-10:B10 telia-11:B11 telia-12:B12" ;;
    B10) UPDATES="telia-11:B11 telia-12:B12" ;;
    B11) UPDATES="telia-12:B12" ;;
    B12)
        log "GIA ALLA VERSIONE FINALE B12"
        log "NESSUN AGGIORNAMENTO NECESSARIO"
        exit 0
        ;;
    *)
        log "VERSIONE NON RICONOSCIUTA: [$VER]"
        log "Per sicurezza parto da telia-05"
        UPDATES="telia-05:B05 telia-06:B06 telia-08:B08 telia-09:B09 telia-10:B10 telia-11:B11 telia-12:B12"
        ;;
esac

log "SEQUENZA UPDATE: $UPDATES"

# --------------------------------------------------
# ESEGUE GLI UPDATE
# --------------------------------------------------
for ENTRY in $UPDATES; do
    FOLDER="${ENTRY%%:*}"
    TARGET="${ENTRY##*:}"

    ATTEMPT=1
    SUCCESS=0

    while [ "$ATTEMPT" -le 2 ]; do
        log "TENTATIVO $ATTEMPT -> $FOLDER ($TARGET)"

        if do_update "$FOLDER" "$TARGET"; then
            SUCCESS=1
            break
        fi

        log "TENTATIVO $ATTEMPT FALLITO per $FOLDER"
        ATTEMPT=$((ATTEMPT + 1))
    done

    if [ "$SUCCESS" -eq 0 ]; then
        log "FAIL DEFINITIVO: $FOLDER"
        exit 1
    fi

    log "COMPLETATO: $FOLDER -> $TARGET"
done

log "=================================="
log "TUTTI GLI AGGIORNAMENTI COMPLETATI"
log "=================================="
