#!/usr/bin/env bash

andromeda_emulator() {
    printf '%s\n' "$ANDROMEDA_SDK_DIR/emulator/emulator"
}

andromeda_emulator_require() {
    _andromeda_emulator="$(andromeda_emulator)"
    if [ ! -x "$_andromeda_emulator" ]; then
        andromeda_die "No existe emulator. Ejecuta: ./bin/andromeda install-sdk"
    fi
}

andromeda_emulator_pid_running() {
    if [ ! -f "$ANDROMEDA_PID_FILE" ]; then
        return 1
    fi

    _andromeda_pid="$(sed -n '1p' "$ANDROMEDA_PID_FILE" 2>/dev/null || true)"
    if [ -z "$_andromeda_pid" ]; then
        return 1
    fi

    kill -0 "$_andromeda_pid" >/dev/null 2>&1
}

andromeda_start_emulator() {
    andromeda_emulator_require

    if [ ! -d "$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.avd" ]; then
        andromeda_die "No existe la instancia $ANDROMEDA_AVD_NAME. Ejecuta: ./bin/andromeda create"
    fi

    if andromeda_emulator_pid_running; then
        _andromeda_pid="$(sed -n '1p' "$ANDROMEDA_PID_FILE")"
        andromeda_info "El emulador ya parece estar corriendo. PID: $_andromeda_pid"
        return 0
    fi

    _andromeda_log="$ANDROMEDA_LOG_DIR/emulator-$(andromeda_timestamp).log"
    _andromeda_emulator="$(andromeda_emulator)"

    andromeda_print_section "Iniciar Android"
    printf 'AVD:            %s\n' "$ANDROMEDA_AVD_NAME"
    printf 'RAM:            %s MB\n' "$ANDROMEDA_RAM_MB"
    printf 'Cores:          %s\n' "$ANDROMEDA_CORES"
    printf 'GPU:            %s\n' "$ANDROMEDA_GPU"
    printf 'Log:            %s\n' "$_andromeda_log"

    (
        export TMPDIR="$ANDROMEDA_TMP_DIR"
        "$_andromeda_emulator" \
            -avd "$ANDROMEDA_AVD_NAME" \
            -memory "$ANDROMEDA_RAM_MB" \
            -cores "$ANDROMEDA_CORES" \
            -gpu "$ANDROMEDA_GPU" \
            -no-snapshot-load \
            -no-boot-anim \
            > "$_andromeda_log" 2>&1
    ) &

    _andromeda_pid="$!"
    printf '%s\n' "$_andromeda_pid" > "$ANDROMEDA_PID_FILE"

    sleep 2
    if kill -0 "$_andromeda_pid" >/dev/null 2>&1; then
        andromeda_info "Emulador iniciado en segundo plano. PID: $_andromeda_pid"
        andromeda_info "Puede tardar unos minutos en completar boot."
        return 0
    fi

    rm -f "$ANDROMEDA_PID_FILE"
    andromeda_error "El emulador salio durante el arranque. Ultimas lineas del log:"
    tail -n 40 "$_andromeda_log" || true
    exit 1
}

andromeda_stop_emulator() {
    andromeda_print_section "Detener Android"

    if [ -x "$(andromeda_adb)" ]; then
        andromeda_info "Intentando apagar con adb emu kill."
        andromeda_adb_kill_emulator >/dev/null 2>&1 || true
    else
        andromeda_warn "adb no esta instalado; se omitio adb emu kill."
    fi

    if andromeda_emulator_pid_running; then
        _andromeda_pid="$(sed -n '1p' "$ANDROMEDA_PID_FILE")"
        andromeda_info "Esperando cierre del PID $_andromeda_pid."
        _andromeda_elapsed=0
        while kill -0 "$_andromeda_pid" >/dev/null 2>&1 && [ "$_andromeda_elapsed" -lt 20 ]; do
            sleep 1
            _andromeda_elapsed=$(( _andromeda_elapsed + 1 ))
        done

        if kill -0 "$_andromeda_pid" >/dev/null 2>&1; then
            andromeda_warn "El emulador no cerro con adb; enviando SIGTERM al PID $_andromeda_pid."
            kill "$_andromeda_pid" >/dev/null 2>&1 || true
        fi
    else
        if [ -f "$ANDROMEDA_PID_FILE" ]; then
            andromeda_info "El PID registrado ya no esta activo."
        else
            andromeda_info "No hay PID activo registrado."
        fi
    fi

    rm -f "$ANDROMEDA_PID_FILE"
    andromeda_info "Stop completado."
}

andromeda_restart_emulator() {
    andromeda_stop_emulator || true
    sleep 2
    andromeda_start_emulator
}
