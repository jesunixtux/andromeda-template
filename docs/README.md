# Andromeda 1.0

Andromeda es una CLI para ejecutar Android oficial en macOS sin instalar Android Studio. Usa Android SDK Command Line Tools, `sdkmanager`, `avdmanager`, Android Emulator y `adb`, manteniendo SDK, AVDs, descargas, logs y configuracion dentro del proyecto.

La prioridad inicial es macOS Apple Silicon `arm64` con la imagen oficial:

```text
system-images;android-36;google_apis;arm64-v8a
```

## Requisitos

- macOS.
- Java disponible en `PATH`.
- `curl` y `unzip`.
- Espacio libre suficiente para SDK, system image y userdata del emulador.

No se usa Android Studio, LineageOS, Android-x86, ROMs de terceros, Electron, Swift, Tauri ni backend.

## Primer uso

Desde la raiz del proyecto:

```bash
./bin/andromeda doctor
./bin/andromeda install-sdk
./bin/andromeda create
./bin/andromeda start
./bin/andromeda install-apk ./test.apk
./bin/andromeda stop
```

`start` lanza el emulador en segundo plano y deja el log en `runtime/logs`.

## Comandos

```bash
./bin/andromeda doctor
./bin/andromeda install-sdk
./bin/andromeda update-sdk
./bin/andromeda create
./bin/andromeda start
./bin/andromeda stop
./bin/andromeda restart
./bin/andromeda install-apk /ruta/app.apk
./bin/andromeda devices
./bin/andromeda list-avd
./bin/andromeda repair
./bin/andromeda clean-cache
./bin/andromeda logs
./bin/andromeda paths
./bin/andromeda help
```

## Configuracion

La configuracion vive en:

```text
config/andromeda.json
```

Valores principales:

- `android.api_level`: API de Android, por defecto `36`.
- `android.image_type`: tipo de imagen, por defecto `google_apis`.
- `android.abi`: ABI, por defecto `arm64-v8a`.
- `android.device`: perfil de dispositivo de `avdmanager`.
- `android.avd_name`: nombre de la instancia.
- `emulator.ram_mb`: memoria del emulador.
- `emulator.cores`: nucleos CPU.
- `emulator.gpu`: backend GPU.
- `emulator.disk_size`: tamano de userdata.

Si `jq` existe, Andromeda lo usa para leer JSON. Si no existe, intenta `plutil` en macOS. Si no hay parser disponible, usa defaults seguros.

## Rutas

```text
bin/andromeda                 CLI principal
core/                         Modulos Bash
scripts/install-sdk-macos.sh  Wrapper del instalador SDK
config/andromeda.json         Configuracion del proyecto
runtime/sdk/                  Android SDK local
runtime/avd/                  AVDs locales
runtime/downloads/            Descargas y temporales
runtime/logs/                 Logs del emulador
runtime/backups/              Backups pequenos de configuracion
runtime/profiles/             Perfiles futuros
runtime/android-user/         Configuracion de usuario Android/Emulator
runtime/tmp/                  Temporales del emulador cuando sea posible
```

## Seguridad de datos

Andromeda no borra userdata del usuario en comandos normales. `repair` pide confirmacion explicita escribiendo:

```text
BORRAR <nombre-del-avd>
```

`clean-cache` solo borra temporales de descargas y del SDK; no toca AVDs ni userdata.
