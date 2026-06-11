#!/usr/bin/env bash

andromeda_sdkmanager() {
    printf '%s\n' "$ANDROMEDA_SDK_DIR/cmdline-tools/latest/bin/sdkmanager"
}

andromeda_avdmanager() {
    printf '%s\n' "$ANDROMEDA_SDK_DIR/cmdline-tools/latest/bin/avdmanager"
}

andromeda_sdkmanager_require() {
    _andromeda_sdkmanager="$(andromeda_sdkmanager)"
    if [ ! -x "$_andromeda_sdkmanager" ]; then
        andromeda_die "No existe sdkmanager. Ejecuta: ./bin/andromeda install-sdk"
    fi
}

andromeda_avdmanager_require() {
    _andromeda_avdmanager="$(andromeda_avdmanager)"
    if [ ! -x "$_andromeda_avdmanager" ]; then
        andromeda_die "No existe avdmanager. Ejecuta: ./bin/andromeda install-sdk"
    fi
}

andromeda_install_sdk() {
    andromeda_check_macos
    andromeda_warn_architecture
    andromeda_check_required_host_tools
    andromeda_ensure_dirs

    _andromeda_tools_dir="$ANDROMEDA_SDK_DIR/cmdline-tools"
    _andromeda_latest_dir="$_andromeda_tools_dir/latest"
    _andromeda_tools_zip="$ANDROMEDA_DOWNLOAD_DIR/$(basename "$ANDROMEDA_CMDLINE_TOOLS_URL")"
    _andromeda_tmp_dir="$ANDROMEDA_DOWNLOAD_DIR/cmdline-tools-tmp"

    mkdir -p "$_andromeda_tools_dir"

    andromeda_print_section "Instalador SDK macOS"
    andromeda_info "Android oficial sin Android Studio."
    andromeda_info "SDK local: $ANDROMEDA_SDK_DIR"

    andromeda_download_cmdline_tools "$_andromeda_tools_zip"

    andromeda_info "Instalando Android Command Line Tools."
    rm -rf "$_andromeda_tmp_dir"
    mkdir -p "$_andromeda_tmp_dir"
    unzip -q "$_andromeda_tools_zip" -d "$_andromeda_tmp_dir"

    if [ ! -d "$_andromeda_tmp_dir/cmdline-tools" ]; then
        rm -rf "$_andromeda_tmp_dir"
        andromeda_die "El ZIP de Command Line Tools no contiene la carpeta esperada."
    fi

    rm -rf "$_andromeda_latest_dir"
    mkdir -p "$_andromeda_latest_dir"
    mv "$_andromeda_tmp_dir/cmdline-tools/"* "$_andromeda_latest_dir/"
    rm -rf "$_andromeda_tmp_dir"

    andromeda_export_android_env
    andromeda_sdkmanager_require

    _andromeda_sdkmanager="$(andromeda_sdkmanager)"

    andromeda_info "Aceptando licencias del SDK."
    yes | "$_andromeda_sdkmanager" --sdk_root="$ANDROMEDA_SDK_DIR" --licenses || true

    andromeda_info "Instalando paquetes oficiales minimos."
    "$_andromeda_sdkmanager" --sdk_root="$ANDROMEDA_SDK_DIR" \
        "platform-tools" \
        "emulator" \
        "$(andromeda_platform_package)" \
        "$(andromeda_android_image)"

    andromeda_info "SDK instalado/actualizado correctamente."
}

andromeda_update_sdk() {
    andromeda_sdkmanager_require
    _andromeda_sdkmanager="$(andromeda_sdkmanager)"

    andromeda_info "Actualizando paquetes SDK instalados."
    yes | "$_andromeda_sdkmanager" --sdk_root="$ANDROMEDA_SDK_DIR" --licenses || true
    "$_andromeda_sdkmanager" --sdk_root="$ANDROMEDA_SDK_DIR" --update
    "$_andromeda_sdkmanager" --sdk_root="$ANDROMEDA_SDK_DIR" \
        "platform-tools" \
        "emulator" \
        "$(andromeda_platform_package)" \
        "$(andromeda_android_image)"
    andromeda_info "SDK actualizado."
}

andromeda_download_cmdline_tools() {
    _andromeda_destination="$1"

    if [ -f "$_andromeda_destination" ] && andromeda_verify_sha256 "$_andromeda_destination" "$ANDROMEDA_CMDLINE_TOOLS_SHA256"; then
        andromeda_info "Usando descarga existente: $_andromeda_destination"
        return 0
    fi

    if [ -f "$_andromeda_destination" ]; then
        andromeda_warn "La descarga existente no coincide con el checksum esperado. Se descargara de nuevo."
        rm -f "$_andromeda_destination"
    fi

    andromeda_info "Descargando Command Line Tools."
    curl -fL "$ANDROMEDA_CMDLINE_TOOLS_URL" -o "$_andromeda_destination"

    if ! andromeda_verify_sha256 "$_andromeda_destination" "$ANDROMEDA_CMDLINE_TOOLS_SHA256"; then
        rm -f "$_andromeda_destination"
        andromeda_die "Checksum invalido para Command Line Tools."
    fi
}

andromeda_verify_sha256() {
    _andromeda_file="$1"
    _andromeda_expected="$2"

    if [ -z "$_andromeda_expected" ]; then
        return 0
    fi

    if ! andromeda_command_exists shasum; then
        andromeda_warn "No existe shasum; se omitio verificacion SHA-256."
        return 0
    fi

    _andromeda_actual="$(shasum -a 256 "$_andromeda_file" | awk '{print $1}')"
    [ "$_andromeda_actual" = "$_andromeda_expected" ]
}

andromeda_sdk_image_installed() {
    _andromeda_image_dir="$ANDROMEDA_SDK_DIR/system-images/android-${ANDROMEDA_API_LEVEL}/${ANDROMEDA_IMAGE_TYPE}/${ANDROMEDA_ABI}"
    [ -d "$_andromeda_image_dir" ]
}
