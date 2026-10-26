# Pokemon Reloaded -> Trimui Smart Pro (OpenGMK / Rust)

## Estado del repo original (revisado)
- `src/OpenGMK` + `patches/`: ya tiene ruta **EGL/GLES** (cfg `target_os="android"`), pensada para Android.
- `vendor/ramen` (ventanas) solo tiene plataformas win32 / linux(X11) / android. **No hay SDL2 ni fbdev**: la consola no tiene X11.
- `vendor/udon` (audio) usa libsoundio -> hay que comprobar que enlaza con ALSA en la consola.
- `PANTALLA-NEGRA-ANDROID.md`: en una PowerVR GE8320 el juego arrancaba con **pantalla negra** (no se rasterizaba nada).
  La Smart Pro lleva PowerVR GE8300 (misma familia). Es el riesgo n.1: por eso el probe va primero.

## Orden de trabajo
1. `.\build.ps1 image` y `.\build.ps1 probe` -> `out/Apps/GLProbe` -> copiar a la SD, ejecutar, enviar `probe_log.txt` + foto de lo que se ve.
2. `.\build.ps1 emulator` -> comprueba que `gm8emulator` compila a aarch64 y que version de glibc exige.
3. Segun el probe: nueva plataforma `ramen/sdl2` (ventana + contexto GLES + joystick) y feature `gles` en el render
   (reusar los `#[cfg(target_os="android")]` como `#[cfg(any(android, feature="gles"))]`).
4. Mapeo de mando -> teclas de GM, `launch.sh`, empaquetado.
