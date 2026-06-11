#!/usr/bin/env bash

andromeda_latest_log() {
    ls -t "$ANDROMEDA_LOG_DIR"/emulator-*.log 2>/dev/null | sed -n '1p'
}

andromeda_logs() {
    _andromeda_mode="${1:-tail}"

    case "$_andromeda_mode" in
        --list|list)
            andromeda_print_section "Logs"
            ls -lt "$ANDROMEDA_LOG_DIR"/*.log 2>/dev/null || printf 'No hay logs todavia.\n'
            ;;
        --follow|follow|-f)
            _andromeda_latest="$(andromeda_latest_log || true)"
            if [ -z "$_andromeda_latest" ]; then
                andromeda_die "No hay logs para seguir."
            fi
            andromeda_info "Siguiendo $_andromeda_latest"
            tail -f "$_andromeda_latest"
            ;;
        tail|"")
            _andromeda_latest="$(andromeda_latest_log || true)"
            if [ -z "$_andromeda_latest" ]; then
                andromeda_info "No hay logs todavia."
                return 0
            fi
            andromeda_print_section "Ultimo log"
            printf '%s\n\n' "$_andromeda_latest"
            tail -n 80 "$_andromeda_latest"
            ;;
        *)
            if [ -f "$_andromeda_mode" ]; then
                tail -n 80 "$_andromeda_mode"
            else
                andromeda_die "Modo de logs desconocido: $_andromeda_mode"
            fi
            ;;
    esac
}

andromeda_clean_cache() {
    andromeda_ensure_dirs

    andromeda_info "Limpiando cache de descargas y temporales del SDK."
    rm -rf "$ANDROMEDA_DOWNLOAD_DIR/cmdline-tools-tmp"
    rm -rf "$ANDROMEDA_SDK_DIR/.temp"
    rm -rf "$ANDROMEDA_TMP_DIR"/*

    find "$ANDROMEDA_DOWNLOAD_DIR" -type f -name '*.tmp' -delete 2>/dev/null || true
    find "$ANDROMEDA_DOWNLOAD_DIR" -type f -name '*.partial' -delete 2>/dev/null || true

    andromeda_info "Cache limpia. No se tocaron userdata ni AVDs."
}
