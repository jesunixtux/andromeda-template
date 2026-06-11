#!/usr/bin/env bash

andromeda_config_create_default() {
    andromeda_ensure_dirs

    if [ -f "$ANDROMEDA_CONFIG_FILE" ]; then
        return 0
    fi

    cat > "$ANDROMEDA_CONFIG_FILE" <<EOF
{
  "name": "Andromeda",
  "version": "1.0.0",
  "platform": "macos",
  "architecture": "arm64",
  "android": {
    "api_level": 36,
    "image_type": "google_apis",
    "abi": "arm64-v8a",
    "device": "pixel_8",
    "avd_name": "Andromeda_Stable"
  },
  "emulator": {
    "ram_mb": 4096,
    "cores": 4,
    "gpu": "host",
    "disk_size": "16G"
  },
  "sdk": {
    "cmdline_tools_url": "$ANDROMEDA_DEFAULT_CMDLINE_TOOLS_URL",
    "cmdline_tools_sha256": ""
  }
}
EOF
}

andromeda_config_get() {
    _andromeda_path="$1"
    _andromeda_default="$2"
    _andromeda_value=""

    if [ -f "$ANDROMEDA_CONFIG_FILE" ]; then
        if andromeda_command_exists jq; then
            _andromeda_value="$(jq -r ".$_andromeda_path // empty" "$ANDROMEDA_CONFIG_FILE" 2>/dev/null || true)"
        elif andromeda_command_exists plutil; then
            _andromeda_value="$(plutil -extract "$_andromeda_path" raw -o - "$ANDROMEDA_CONFIG_FILE" 2>/dev/null || true)"
        fi
    fi

    if [ -z "$_andromeda_value" ] || [ "$_andromeda_value" = "null" ]; then
        printf '%s\n' "$_andromeda_default"
    else
        printf '%s\n' "$_andromeda_value"
    fi
}

andromeda_config_load() {
    andromeda_config_create_default

    ANDROMEDA_API_LEVEL="$(andromeda_config_get "android.api_level" "$ANDROMEDA_DEFAULT_API_LEVEL")"
    ANDROMEDA_IMAGE_TYPE="$(andromeda_config_get "android.image_type" "$ANDROMEDA_DEFAULT_IMAGE_TYPE")"
    ANDROMEDA_ABI="$(andromeda_config_get "android.abi" "$ANDROMEDA_DEFAULT_ABI")"
    ANDROMEDA_DEVICE="$(andromeda_config_get "android.device" "$ANDROMEDA_DEFAULT_DEVICE")"
    ANDROMEDA_AVD_NAME="$(andromeda_config_get "android.avd_name" "$ANDROMEDA_DEFAULT_AVD_NAME")"
    ANDROMEDA_RAM_MB="$(andromeda_config_get "emulator.ram_mb" "$ANDROMEDA_DEFAULT_RAM_MB")"
    ANDROMEDA_CORES="$(andromeda_config_get "emulator.cores" "$ANDROMEDA_DEFAULT_CORES")"
    ANDROMEDA_GPU="$(andromeda_config_get "emulator.gpu" "$ANDROMEDA_DEFAULT_GPU")"
    ANDROMEDA_DISK_SIZE="$(andromeda_config_get "emulator.disk_size" "$ANDROMEDA_DEFAULT_DISK_SIZE")"
    ANDROMEDA_ADB_WAIT_SECONDS="$(andromeda_config_get "adb.wait_seconds" "$ANDROMEDA_DEFAULT_ADB_WAIT_SECONDS")"
    ANDROMEDA_CMDLINE_TOOLS_URL="$(andromeda_config_get "sdk.cmdline_tools_url" "$ANDROMEDA_DEFAULT_CMDLINE_TOOLS_URL")"
    ANDROMEDA_CMDLINE_TOOLS_SHA256="$(andromeda_config_get "sdk.cmdline_tools_sha256" "$ANDROMEDA_DEFAULT_CMDLINE_TOOLS_SHA256")"

    andromeda_export_android_env
}

andromeda_config_validate_json() {
    if [ ! -f "$ANDROMEDA_CONFIG_FILE" ]; then
        return 1
    fi

    if andromeda_command_exists jq; then
        jq empty "$ANDROMEDA_CONFIG_FILE" >/dev/null 2>&1
        return $?
    fi

    if andromeda_command_exists plutil; then
        plutil -lint "$ANDROMEDA_CONFIG_FILE" >/dev/null 2>&1
        return $?
    fi

    return 0
}
