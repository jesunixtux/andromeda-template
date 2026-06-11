#!/usr/bin/env bash

andromeda_install_apk() {
    _andromeda_apk="${1:-}"

    if [ -z "$_andromeda_apk" ]; then
        andromeda_die "Uso: ./bin/andromeda install-apk /ruta/app.apk"
    fi

    _andromeda_apk="$(andromeda_strip_quotes "$_andromeda_apk")"
    _andromeda_apk="$(andromeda_abspath "$_andromeda_apk")"

    if [ ! -f "$_andromeda_apk" ]; then
        andromeda_die "APK no encontrado: $_andromeda_apk"
    fi

    case "$_andromeda_apk" in
        *.apk) ;;
        *) andromeda_warn "El archivo no termina en .apk; se intentara instalar igual." ;;
    esac

    andromeda_adb_require
    _andromeda_adb="$(andromeda_adb)"

    andromeda_print_section "Instalar APK"
    printf 'APK:            %s\n' "$_andromeda_apk"

    andromeda_info "Buscando dispositivo Android listo."
    if ! _andromeda_serial="$(andromeda_adb_wait_for_ready_device)"; then
        andromeda_die "No hay ningun dispositivo listo por ADB. Ejecuta './bin/andromeda start' y vuelve a intentar."
    fi

    andromeda_info "Dispositivo ADB: $_andromeda_serial"
    andromeda_info "Esperando boot completo."
    if ! andromeda_adb_wait_for_boot "$_andromeda_serial"; then
        andromeda_warn "No se pudo confirmar boot completo; se intentara instalar de todos modos."
    fi

    "$_andromeda_adb" -s "$_andromeda_serial" install -r "$_andromeda_apk"
    andromeda_info "APK instalado correctamente."
}
