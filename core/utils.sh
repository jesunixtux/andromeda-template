#!/usr/bin/env bash

andromeda_info() {
    printf '[Andromeda] %s\n' "$*"
}

andromeda_warn() {
    printf '[Andromeda] Aviso: %s\n' "$*" >&2
}

andromeda_error() {
    printf '[Andromeda] Error: %s\n' "$*" >&2
}

andromeda_die() {
    andromeda_error "$*"
    exit 1
}

andromeda_print_section() {
    printf '\n== %s ==\n' "$1"
}

andromeda_timestamp() {
    date '+%Y%m%d-%H%M%S'
}

andromeda_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

andromeda_require_command() {
    if ! andromeda_command_exists "$1"; then
        andromeda_die "Falta '$1'. Instala esa herramienta y vuelve a intentar."
    fi
}

andromeda_check_macos() {
    _andromeda_os="$(uname -s)"
    if [ "$_andromeda_os" != "Darwin" ]; then
        andromeda_die "Andromeda 1.0 esta preparado primero para macOS. Detectado: $_andromeda_os"
    fi
}

andromeda_warn_architecture() {
    _andromeda_arch="$(uname -m)"
    if [ "$_andromeda_arch" != "arm64" ]; then
        andromeda_warn "Prioridad inicial: Apple Silicon arm64. Detectado: $_andromeda_arch."
        andromeda_warn "Cambia android.abi en config/andromeda.json si vas a usar otra arquitectura."
    fi
}

andromeda_check_required_host_tools() {
    andromeda_require_command curl
    andromeda_require_command unzip
    andromeda_require_command java
}

andromeda_strip_quotes() {
    _andromeda_value="$1"
    _andromeda_value="${_andromeda_value%\"}"
    _andromeda_value="${_andromeda_value#\"}"
    _andromeda_value="${_andromeda_value%\'}"
    _andromeda_value="${_andromeda_value#\'}"
    printf '%s\n' "$_andromeda_value"
}

andromeda_abspath() {
    case "$1" in
        /*) printf '%s\n' "$1" ;;
        *) printf '%s/%s\n' "$(pwd)" "$1" ;;
    esac
}

andromeda_confirm_delete_avd() {
    printf 'Esto eliminara la instancia AVD actual: %s\n' "$ANDROMEDA_AVD_NAME"
    printf 'Puede borrar datos del Android emulado.\n\n'
    printf 'Para confirmar, escribe exactamente: BORRAR %s\n' "$ANDROMEDA_AVD_NAME"
    printf '> '
    read -r _andromeda_confirm

    if [ "$_andromeda_confirm" != "BORRAR $ANDROMEDA_AVD_NAME" ]; then
        andromeda_info "Cancelado. No se borro la instancia."
        return 1
    fi

    return 0
}

andromeda_set_ini_value() {
    _andromeda_file="$1"
    _andromeda_key="$2"
    _andromeda_value="$3"
    _andromeda_tmp="${_andromeda_file}.andromeda.$$"

    if [ ! -f "$_andromeda_file" ]; then
        : > "$_andromeda_file"
    fi

    awk -v key="$_andromeda_key" -v value="$_andromeda_value" '
        BEGIN { found = 0 }
        index($0, key "=") == 1 {
            print key "=" value
            found = 1
            next
        }
        { print }
        END {
            if (found == 0) {
                print key "=" value
            }
        }
    ' "$_andromeda_file" > "$_andromeda_tmp"

    mv "$_andromeda_tmp" "$_andromeda_file"
}

andromeda_paths() {
    andromeda_print_section "Rutas"
    printf 'Proyecto:       %s\n' "$ANDROMEDA_ROOT"
    printf 'Config:         %s\n' "$ANDROMEDA_CONFIG_DIR"
    printf 'Runtime:        %s\n' "$ANDROMEDA_RUNTIME_DIR"
    printf 'SDK:            %s\n' "$ANDROMEDA_SDK_DIR"
    printf 'AVD Home:       %s\n' "$ANDROMEDA_AVD_HOME"
    printf 'Descargas:      %s\n' "$ANDROMEDA_DOWNLOAD_DIR"
    printf 'Logs:           %s\n' "$ANDROMEDA_LOG_DIR"
    printf 'Backups:        %s\n' "$ANDROMEDA_BACKUP_DIR"
    printf 'Profiles:       %s\n' "$ANDROMEDA_PROFILE_DIR"
    printf 'Android user:   %s\n' "$ANDROMEDA_ANDROID_USER_HOME"
    printf 'Tmp:            %s\n' "$ANDROMEDA_TMP_DIR"
    printf 'Scripts:        %s\n' "$ANDROMEDA_SCRIPTS_DIR"
    printf 'Config file:    %s\n' "$ANDROMEDA_CONFIG_FILE"
}

andromeda_doctor() {
    andromeda_print_section "Andromeda Doctor"
    printf 'Version CLI:    %s\n' "$ANDROMEDA_VERSION"
    printf 'Proyecto:       %s\n' "$ANDROMEDA_ROOT"
    printf 'Config:         %s\n' "$ANDROMEDA_CONFIG_FILE"

    andromeda_print_section "Host"
    printf 'Sistema:        %s\n' "$(uname -s 2>/dev/null || printf 'desconocido')"
    printf 'Arquitectura:   %s\n' "$(uname -m 2>/dev/null || printf 'desconocida')"
    printf 'Kernel:         %s\n' "$(uname -r 2>/dev/null || printf 'desconocido')"

    andromeda_print_section "Herramientas"
    _andromeda_doctor_tool java "java -version"
    _andromeda_doctor_tool curl "curl --version"
    _andromeda_doctor_tool unzip "unzip -v"
    _andromeda_doctor_optional_tool jq "jq --version"
    _andromeda_doctor_optional_tool plutil "plutil -help"

    andromeda_print_section "Config activa"
    if andromeda_config_validate_json; then
        printf 'JSON:           OK\n'
    else
        printf 'JSON:           INVALIDO (se usaran defaults cuando no se pueda leer)\n'
    fi
    printf 'API level:      %s\n' "$ANDROMEDA_API_LEVEL"
    printf 'Imagen:         %s\n' "$(andromeda_android_image)"
    printf 'Device:         %s\n' "$ANDROMEDA_DEVICE"
    printf 'AVD name:       %s\n' "$ANDROMEDA_AVD_NAME"
    printf 'RAM MB:         %s\n' "$ANDROMEDA_RAM_MB"
    printf 'Cores:          %s\n' "$ANDROMEDA_CORES"
    printf 'GPU:            %s\n' "$ANDROMEDA_GPU"
    printf 'Disk:           %s\n' "$ANDROMEDA_DISK_SIZE"

    andromeda_print_section "Variables Android"
    printf 'ANDROID_HOME:       %s\n' "${ANDROID_HOME:-}"
    printf 'ANDROID_SDK_ROOT:   %s\n' "${ANDROID_SDK_ROOT:-}"
    printf 'ANDROID_AVD_HOME:   %s\n' "${ANDROID_AVD_HOME:-}"
    printf 'ANDROID_USER_HOME:  %s\n' "${ANDROID_USER_HOME:-}"
    printf 'ANDROID_EMULATOR_HOME: %s\n' "${ANDROID_EMULATOR_HOME:-}"

    andromeda_print_section "Directorios"
    _andromeda_doctor_path "$ANDROMEDA_SDK_DIR"
    _andromeda_doctor_path "$ANDROMEDA_AVD_HOME"
    _andromeda_doctor_path "$ANDROMEDA_DOWNLOAD_DIR"
    _andromeda_doctor_path "$ANDROMEDA_LOG_DIR"
    _andromeda_doctor_path "$ANDROMEDA_BACKUP_DIR"
    _andromeda_doctor_path "$ANDROMEDA_PROFILE_DIR"
    _andromeda_doctor_path "$ANDROMEDA_ANDROID_USER_HOME"
    _andromeda_doctor_path "$ANDROMEDA_TMP_DIR"

    andromeda_print_section "Android SDK"
    _andromeda_doctor_binary "sdkmanager" "$ANDROMEDA_SDK_DIR/cmdline-tools/latest/bin/sdkmanager"
    _andromeda_doctor_binary "avdmanager" "$ANDROMEDA_SDK_DIR/cmdline-tools/latest/bin/avdmanager"
    _andromeda_doctor_binary "emulator" "$ANDROMEDA_SDK_DIR/emulator/emulator"
    _andromeda_doctor_binary "adb" "$ANDROMEDA_SDK_DIR/platform-tools/adb"

    _andromeda_image_dir="$ANDROMEDA_SDK_DIR/system-images/android-${ANDROMEDA_API_LEVEL}/${ANDROMEDA_IMAGE_TYPE}/${ANDROMEDA_ABI}"
    _andromeda_doctor_path "$_andromeda_image_dir"

    andromeda_print_section "AVD"
    if [ -d "$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.avd" ]; then
        printf 'Instancia:      OK (%s)\n' "$ANDROMEDA_AVD_HOME/${ANDROMEDA_AVD_NAME}.avd"
    else
        printf 'Instancia:      No creada (%s)\n' "$ANDROMEDA_AVD_NAME"
    fi

    if [ -f "$ANDROMEDA_SDK_DIR/cmdline-tools/latest/bin/avdmanager" ]; then
        "$ANDROMEDA_SDK_DIR/cmdline-tools/latest/bin/avdmanager" list avd || true
    else
        printf 'avdmanager no esta instalado.\n'
    fi

    andromeda_print_section "ADB"
    if [ -f "$ANDROMEDA_SDK_DIR/platform-tools/adb" ]; then
        "$ANDROMEDA_SDK_DIR/platform-tools/adb" devices -l || true
    else
        printf 'adb no esta instalado.\n'
    fi

    andromeda_print_section "Logs"
    _andromeda_latest_log="$(andromeda_latest_log || true)"
    if [ -n "$_andromeda_latest_log" ]; then
        printf 'Ultimo log:     %s\n' "$_andromeda_latest_log"
    else
        printf 'Ultimo log:     No hay logs todavia.\n'
    fi
}

_andromeda_doctor_tool() {
    _andromeda_name="$1"
    _andromeda_command="$2"
    if andromeda_command_exists "$_andromeda_name"; then
        printf '%-15s OK - ' "$_andromeda_name"
        sh -c "$_andromeda_command" 2>&1 | sed -n '1p'
    else
        printf '%-15s FALTA\n' "$_andromeda_name"
    fi
}

_andromeda_doctor_optional_tool() {
    _andromeda_name="$1"
    _andromeda_command="$2"
    if andromeda_command_exists "$_andromeda_name"; then
        printf '%-15s OK - ' "$_andromeda_name"
        sh -c "$_andromeda_command" 2>&1 | sed -n '1p'
    else
        printf '%-15s opcional, no instalado\n' "$_andromeda_name"
    fi
}

_andromeda_doctor_path() {
    if [ -d "$1" ]; then
        printf 'OK             %s\n' "$1"
    else
        printf 'FALTA          %s\n' "$1"
    fi
}

_andromeda_doctor_binary() {
    if [ -x "$2" ]; then
        printf '%-15s OK - %s\n' "$1" "$2"
    elif [ -f "$2" ]; then
        printf '%-15s Existe pero no ejecutable - %s\n' "$1" "$2"
    else
        printf '%-15s FALTA - %s\n' "$1" "$2"
    fi
}
