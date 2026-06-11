#!/usr/bin/env bash

andromeda_adb() {
    printf '%s\n' "$ANDROMEDA_SDK_DIR/platform-tools/adb"
}

andromeda_adb_require() {
    _andromeda_adb="$(andromeda_adb)"
    if [ ! -x "$_andromeda_adb" ]; then
        andromeda_die "No existe adb. Ejecuta: ./bin/andromeda install-sdk"
    fi
}

andromeda_devices() {
    andromeda_adb_require
    "$(andromeda_adb)" devices -l
}

andromeda_adb_first_ready_serial() {
    _andromeda_adb="$(andromeda_adb)"
    "$_andromeda_adb" devices | awk '
        /^emulator-[0-9]+[[:space:]]+device$/ { print $1; exit }
    '
}

andromeda_adb_first_any_ready_serial() {
    _andromeda_adb="$(andromeda_adb)"
    "$_andromeda_adb" devices | awk '
        NR > 1 && $2 == "device" { print $1; exit }
    '
}

andromeda_adb_wait_for_ready_device() {
    andromeda_adb_require
    _andromeda_adb="$(andromeda_adb)"
    _andromeda_elapsed=0
    _andromeda_wait="$ANDROMEDA_ADB_WAIT_SECONDS"

    "$_andromeda_adb" start-server >/dev/null 2>&1 || true

    while [ "$_andromeda_elapsed" -le "$_andromeda_wait" ]; do
        _andromeda_serial="$(andromeda_adb_first_ready_serial)"
        if [ -z "$_andromeda_serial" ]; then
            _andromeda_serial="$(andromeda_adb_first_any_ready_serial)"
        fi

        if [ -n "$_andromeda_serial" ]; then
            printf '%s\n' "$_andromeda_serial"
            return 0
        fi

        sleep 2
        _andromeda_elapsed=$(( _andromeda_elapsed + 2 ))
    done

    return 1
}

andromeda_adb_wait_for_boot() {
    _andromeda_serial="$1"
    _andromeda_adb="$(andromeda_adb)"
    _andromeda_elapsed=0
    _andromeda_wait="$ANDROMEDA_ADB_WAIT_SECONDS"

    while [ "$_andromeda_elapsed" -le "$_andromeda_wait" ]; do
        _andromeda_boot="$("$_andromeda_adb" -s "$_andromeda_serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
        if [ "$_andromeda_boot" = "1" ]; then
            return 0
        fi

        sleep 2
        _andromeda_elapsed=$(( _andromeda_elapsed + 2 ))
    done

    return 1
}

andromeda_adb_kill_emulator() {
    andromeda_adb_require
    _andromeda_adb="$(andromeda_adb)"
    _andromeda_serial="$(andromeda_adb_first_ready_serial)"

    if [ -n "$_andromeda_serial" ]; then
        "$_andromeda_adb" -s "$_andromeda_serial" emu kill
        return $?
    fi

    "$_andromeda_adb" emu kill
}
