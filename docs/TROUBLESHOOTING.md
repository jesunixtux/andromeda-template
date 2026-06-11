# Troubleshooting

## `java` no encontrado

Instala Java y verifica que quede disponible en `PATH`:

```bash
java -version
```

Con Homebrew:

```bash
brew install openjdk
```

Si macOS no lo detecta, agrega el binario de OpenJDK a tu shell.

## `sdkmanager` o `avdmanager` no existen

Ejecuta:

```bash
./bin/andromeda install-sdk
```

Luego revisa:

```bash
./bin/andromeda doctor
```

## La imagen Android no esta instalada

La imagen por defecto es:

```text
system-images;android-36;google_apis;arm64-v8a
```

Ejecuta:

```bash
./bin/andromeda install-sdk
```

Si cambiaste `api_level`, `image_type` o `abi` en `config/andromeda.json`, vuelve a ejecutar `install-sdk` o `update-sdk`.

## `create` dice que el AVD ya existe

Andromeda no sobrescribe una instancia existente para no borrar userdata. Si quieres recrearla:

```bash
./bin/andromeda repair
./bin/andromeda create
```

`repair` pedira confirmacion explicita.

## El emulador no arranca

Revisa el ultimo log:

```bash
./bin/andromeda logs
```

Tambien puedes listar logs:

```bash
./bin/andromeda logs --list
```

Causas comunes:

- Falta la system image oficial.
- AVD corrupto.
- RAM insuficiente.
- `ANDROID_AVD_HOME` apunta fuera del proyecto por una terminal heredada.

Verifica rutas con:

```bash
./bin/andromeda paths
```

## `install-apk` no encuentra dispositivo

Inicia Android primero:

```bash
./bin/andromeda start
```

Espera a que termine el boot. Puedes revisar ADB:

```bash
./bin/andromeda devices
```

## `adb emu kill` falla

`stop` intenta apagar con `adb emu kill` y luego usa el PID local si existe. Si el proceso quedo fuera del control de Andromeda, revisa procesos de `emulator` manualmente o reinicia la maquina.

## Quiero cambiar RAM, cores, API o ABI

Edita `config/andromeda.json`. Para cambios de Android image (`api_level`, `image_type`, `abi`), instala los paquetes:

```bash
./bin/andromeda install-sdk
```

Si la instancia ya existe, Andromeda no la sobrescribe. Usa `repair` solo si aceptas borrar la userdata de esa instancia.
