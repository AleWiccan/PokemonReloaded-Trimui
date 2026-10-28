#!/bin/sh
# Lanzador de Pokemon Reloaded (OpenGMK) para Trimui. Va en SDCARD/Roms/PORTS/
PORT="$(cd "$(dirname "$0")/../../Data/ports/PokemonReloaded" 2>/dev/null && pwd)"
[ -n "$PORT" ] || exit 1
cd "$PORT" || exit 1

# libs/ primero (libstdc++/libgcc_s propias); despues la SDL2 de la consola (driver de video "mali")
export LD_LIBRARY_PATH="$PORT/libs:/usr/trimui/lib:$LD_LIBRARY_PATH"
unset SDL_VIDEODRIVER
export HOME="$PORT"
export TRIMUI_CONTROLS="$PORT/controls.ini"
export OPENGMK_SCALING="${OPENGMK_SCALING:-aspect}"   # aspect = mantiene la proporcion; full = estira
[ -f "$PORT/debug.on" ] && export TRIMUI_INPUT_DEBUG=1   # con un archivo debug.on: anota en log.txt el numero de cada boton
export RUST_BACKTRACE=1

LOGF="$PORT/log.txt"
echo "[launcher] version 5 - $(date)" > "$LOGF"

# SoundFont para la musica MIDI (.mid). Se usa el primer .sf2 que haya; mejor uno ligero (la consola tiene 1 GB de RAM).
SF=""
for f in "$PORT"/soundfont/*.sf2 "$PORT"/soundfont/*.SF2 "$PORT"/*.sf2 "$PORT"/*.SF2 "$PORT"/game/*.sf2 "$PORT"/game/*.SF2; do
  if [ -f "$f" ]; then SF="$f"; break; fi
done
if [ -n "$SF" ]; then
  export OPENGMK_SOUNDFONT="$SF"
  echo "[launcher] soundfont: $SF" >> "$LOGF"
else
  echo "[launcher] SIN soundfont: no hay ningun .sf2 en $PORT/soundfont/ (la musica .mid no sonara)" >> "$LOGF"
fi

GAME="$(ls "$PORT"/game/*.exe 2>/dev/null | head -n 1)"
if [ -z "$GAME" ]; then
  echo "No hay ningun .exe en $PORT/game (copia ahi los archivos del juego)" >> "$LOGF"
  exit 1
fi

chmod +x "$PORT/gm8emulator"

# --- diagnostico de memoria (la consola tiene 1 GB). Desactivado por defecto: crear un archivo mem.on
#     en esta carpeta para que se escriba mem.txt. (Calcular el tamano de la carpeta del juego recorre
#     miles de archivos de la SD y tarda unos 10 s, asi que solo se hace con mem.on.)
MEMON=0
[ -f "$PORT/mem.on" ] && MEMON=1
MEM="$PORT/mem.txt"
if [ "$MEMON" = "1" ]; then
  {
    echo "=== $(date) ==="
    grep -E 'MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree' /proc/meminfo
    echo "carpeta del juego: $(du -sm "$PORT/game" 2>/dev/null | cut -f1) MB"
  } > "$MEM"
else
  MEM="/dev/null"
fi

# --- swap: el juego llega a ~560 MB al cargar y la consola tiene 1 GB, asi que sin swap lo mata el sistema.
#     Se activa solo (768 MB en la SD). Crear un archivo swap.off aqui para desactivarlo.
#     Si el swapfile ya existe, se activa en segundo plano para que la pantalla de carga salga de inmediato:
#     el pico de memoria llega varios segundos despues de arrancar.
enable_swap() {
  T_SWAP="$(date +%s)"
  if swapon "$PORT/swapfile" >/dev/null 2>&1; then
    echo "[launcher] swap activado en $(( $(date +%s) - T_SWAP )) s" >> "$LOGF"
  else
    echo "[launcher] swapon FALLO: sin swap el juego puede cerrarse por falta de memoria" >> "$LOGF"
  fi
}
if [ ! -f "$PORT/swap.off" ] && ! grep -q "$PORT/swapfile" /proc/swaps 2>/dev/null; then
  if [ -f "$PORT/swapfile" ]; then
    enable_swap &
  else
    echo "[launcher] creando swapfile de 768 MB (solo la primera vez, tarda un rato)..." >> "$LOGF"
    dd if=/dev/zero of="$PORT/swapfile" bs=1M count=768 >/dev/null 2>&1
    chmod 600 "$PORT/swapfile"
    mkswap "$PORT/swapfile" >/dev/null 2>&1
    enable_swap
  fi
fi

echo "[launcher] lanzando el emulador - $(date +%T)" >> "$LOGF"
cd "$PORT/game" || exit 1
"$PORT/gm8emulator" "$GAME" >> "$LOGF" 2>&1 &
EMU=$!
if [ "$MEMON" = "1" ]; then
  while kill -0 "$EMU" 2>/dev/null; do
    RSS="$(grep VmRSS /proc/$EMU/status 2>/dev/null | tr -s ' ' | cut -d' ' -f2)"
    AV="$(grep MemAvailable /proc/meminfo | tr -s ' ' | cut -d' ' -f2)"
    SW="$(grep SwapFree /proc/meminfo | tr -s ' ' | cut -d' ' -f2)"
    echo "$(date +%T) emulador_kB=$RSS disponible_kB=$AV swap_libre_kB=$SW" >> "$MEM"
    sleep 5
  done
fi
wait "$EMU"
CODE=$?
echo "[launcher] codigo de salida: $CODE  (137 = cerrado por falta de memoria)" >> "$LOGF"
if [ "$CODE" = "137" ]; then
  dmesg 2>/dev/null | grep -i -E "killed process|out of memory|oom" | tail -5 >> "$LOGF"
fi
