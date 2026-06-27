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

    log "$LABEL - duration ${SECS}s"

    while [ "$SECS" -gt 0 ]; do
        MINS=$((SECS / 60))
        REST=$((SECS % 60))
        printf "\r>>> %s: %02d:%02d remaining " "$LABEL" "$MINS" "$REST"
        sleep 1
        SECS=$((SECS - 1))
    done

    printf "\r>>> %s: COMPLETED              \n" "$LABEL"
}

# --------------------------------------------------
read_version() {
    rm -f "$TMP_ATI"

    # Clean serial buffer
    cat "$TTY" > /dev/null 2>&1 &
    CLEAN_PID=$!
    sleep 1
    kill "$CLEAN_PID" 2>/dev/null

    # Start capture
    cat "$TTY" > "$TMP_ATI" 2>/dev/null &
    CAT_PID=$!
    sleep 1

    # Send ATI
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
        log "ERROR: missing files in $BASE/$FOLDER"
        return 1
    fi

    # --------------------------------------------------
    # FIRST FILE UPLOAD
    # --------------------------------------------------
    log "FIRST UPLOAD delta.package"
    adb push "$BASE/$FOLDER/delta.package" /cache/
    pause

    log "FIRST UPLOAD delta.signature"
    adb push "$BASE/$FOLDER/delta.signature" /cache/
    pause

    # --------------------------------------------------
    # FIRST FOTA SEQUENCE
    # --------------------------------------------------
    log "SENDING FOTA AT COMMANDS - FIRST SEQUENCE"
    send_at "${AT_CMD}=0"
    send_at "${AT_CMD}=1"
    send_at "${AT_CMD}=5"
    send_at "${AT_CMD}=8"
    send_at "${AT_CMD}=2"

    # --------------------------------------------------
    # WAIT 10 MINUTES FOR FLASH
    # --------------------------------------------------
    countdown "FLASH IN PROGRESS" 600

    # --------------------------------------------------
    # SECOND FILE UPLOAD
    # --------------------------------------------------
    log "SECOND UPLOAD delta.package"
    adb push "$BASE/$FOLDER/delta.package" /cache/
    pause

    log "SECOND UPLOAD delta.signature"
    adb push "$BASE/$FOLDER/delta.signature" /cache/
    pause

    # --------------------------------------------------
    # SECOND FOTA SEQUENCE
    # --------------------------------------------------
    log "SENDING FOTA AT COMMANDS - SECOND SEQUENCE"
    send_at "${AT_CMD}=0"
    send_at "${AT_CMD}=1"
    send_at "${AT_CMD}=5"
    send_at "${AT_CMD}=8"
    send_at "${AT_CMD}=2"

    # --------------------------------------------------
    # WAIT 3 MINUTES FOR NEW FOTA PROCESSING
    # --------------------------------------------------
    countdown "WAITING FOR NEW FOTA" 180

    # --------------------------------------------------
    # VERSION CHECK
    # --------------------------------------------------
    log "POST-UPDATE VERSION CHECK"
    NEW_VER=$(read_version)
    log "VERSION AFTER UPDATE: [$NEW_VER]"

    if [ "$NEW_VER" = "$TARGET" ]; then
        log "OK: $TARGET installed successfully"
        return 0
    fi

    log "ERROR: expected [$TARGET] but found [$NEW_VER]"
    return 1
}

# --------------------------------------------------
# MAIN
# --------------------------------------------------

log "=================================="
log "START FOTA ENGINE MF286D"
log "=================================="

VER=$(read_version)
log "CURRENT DETECTED VERSION: [$VER]"

if [ -z "$VER" ]; then
    log "ERROR: unable to read current version"
    exit 1
fi

# --------------------------------------------------
# DECIDE WHERE TO START
# --------------------------------------------------
case "$VER" in
    B05) UPDATES="telia-06:B06 telia-08:B08 telia-09:B09 telia-10:B10 telia-11:B11 telia-12:B12" ;;
    B06) UPDATES="telia-08:B08 telia-09:B09 telia-10:B10 telia-11:B11 telia-12:B12" ;;
    B08) UPDATES="telia-09:B09 telia-10:B10 telia-11:B11 telia-12:B12" ;;
    B09) UPDATES="telia-10:B10 telia-11:B11 telia-12:B12" ;;
    B10) UPDATES="telia-11:B11 telia-12:B12" ;;
    B11) UPDATES="telia-12:B12" ;;
    B12)
        log "ALREADY AT FINAL VERSION B12"
        log "NO UPDATE REQUIRED"
        exit 0
        ;;
    *)
        log "UNRECOGNIZED VERSION: [$VER]"
        log "For safety, starting from telia-05"
        UPDATES="telia-05:B05 telia-06:B06 telia-08:B08 telia-09:B09 telia-10:B10 telia-11:B11 telia-12:B12"
        ;;
esac

log "UPDATE SEQUENCE: $UPDATES"

# --------------------------------------------------
# RUN UPDATES
# --------------------------------------------------
for ENTRY in $UPDATES; do
    FOLDER="${ENTRY%%:*}"
    TARGET="${ENTRY##*:}"

    ATTEMPT=1
    SUCCESS=0

    while [ "$ATTEMPT" -le 2 ]; do
        log "ATTEMPT $ATTEMPT -> $FOLDER ($TARGET)"

        if do_update "$FOLDER" "$TARGET"; then
            SUCCESS=1
            break
        fi

        log "ATTEMPT $ATTEMPT FAILED for $FOLDER"
        ATTEMPT=$((ATTEMPT + 1))
    done

    if [ "$SUCCESS" -eq 0 ]; then
        log "FINAL FAILURE: $FOLDER"
        exit 1
    fi

    log "COMPLETED: $FOLDER -> $TARGET"
done

log "=================================="
log "ALL UPDATES COMPLETED"
log "=================================="
