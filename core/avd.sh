#!/usr/bin/env bash

andromeda_create_avd() {
    andromeda_avdmanager_require

    if ! andromeda_sdk_image_installed; then
        andromeda_die "No esta instalada la imagen $(andromeda_android_image). Ejecuta: ./bin/andromeda install-sdk"
    fi

    if [ -d "$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.avd" ] || [ -f "$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.ini" ]; then
        andromeda_info "La instancia ya existe: $ANDROMEDA_AVD_NAME"
        andromeda_info "No se toca userdata. Usa './bin/andromeda repair' si quieres recrearla."
        return 0
    fi

    _andromeda_avdmanager="$(andromeda_avdmanager)"

    andromeda_print_section "Crear instancia Android"
    printf 'Nombre AVD:     %s\n' "$ANDROMEDA_AVD_NAME"
    printf 'Imagen:         %s\n' "$(andromeda_android_image)"
    printf 'Dispositivo:    %s\n' "$ANDROMEDA_DEVICE"
    printf 'RAM:            %s MB\n' "$ANDROMEDA_RAM_MB"
    printf 'Cores:          %s\n' "$ANDROMEDA_CORES"
    printf 'Disk:           %s\n' "$ANDROMEDA_DISK_SIZE"

    printf 'no\n' | "$_andromeda_avdmanager" create avd \
        -n "$ANDROMEDA_AVD_NAME" \
        -k "$(andromeda_android_image)" \
        --device "$ANDROMEDA_DEVICE"

    andromeda_configure_avd
    andromeda_info "Instancia creada correctamente."
}

andromeda_configure_avd() {
    _andromeda_config_ini="$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.avd/config.ini"

    if [ ! -f "$_andromeda_config_ini" ]; then
        andromeda_warn "No se encontro config.ini del AVD para ajustar hardware."
        return 0
    fi

    andromeda_set_ini_value "$_andromeda_config_ini" "hw.ramSize" "$ANDROMEDA_RAM_MB"
    andromeda_set_ini_value "$_andromeda_config_ini" "hw.cpu.ncore" "$ANDROMEDA_CORES"
    andromeda_set_ini_value "$_andromeda_config_ini" "disk.dataPartition.size" "$ANDROMEDA_DISK_SIZE"
    andromeda_set_ini_value "$_andromeda_config_ini" "hw.keyboard" "yes"
    andromeda_set_ini_value "$_andromeda_config_ini" "showDeviceFrame" "no"
    andromeda_set_ini_value "$_andromeda_config_ini" "skin.dynamic" "yes"

    andromeda_info "Configuracion AVD actualizada: $_andromeda_config_ini"
}

andromeda_list_avd() {
    if [ -x "$(andromeda_avdmanager)" ]; then
        "$(andromeda_avdmanager)" list avd
        return 0
    fi

    andromeda_print_section "AVDs locales"
    find "$ANDROMEDA_AVD_HOME" -maxdepth 1 -type d -name '*.avd' -print 2>/dev/null || true
}

andromeda_repair_avd() {
    if [ ! -d "$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.avd" ] && [ ! -f "$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.ini" ]; then
        andromeda_info "No existe la instancia $ANDROMEDA_AVD_NAME. Ejecuta './bin/andromeda create'."
        return 0
    fi

    andromeda_confirm_delete_avd || return 0

    andromeda_info "Intentando detener emulador antes de reparar."
    andromeda_stop_emulator || true

    _andromeda_backup="$ANDROMEDA_BACKUP_DIR/${ANDROMEDA_AVD_NAME}-$(andromeda_timestamp)"
    mkdir -p "$_andromeda_backup"

    if [ -f "$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.ini" ]; then
        cp "$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.ini" "$_andromeda_backup/" || true
    fi
    if [ -f "$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.avd/config.ini" ]; then
        cp "$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.avd/config.ini" "$_andromeda_backup/" || true
    fi

    rm -rf "$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.avd"
    rm -f "$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.ini"

    andromeda_info "Instancia eliminada. Backups de configuracion: $_andromeda_backup"
    andromeda_info "Crea una instancia nueva con: ./bin/andromeda create"
}
