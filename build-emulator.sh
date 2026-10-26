#!/bin/sh
# Se ejecuta DENTRO del contenedor. Clona el repo, aplica trimui.patch, compila gm8emulator para
# aarch64 con SDL2 (feature "trimui") y deja el port listo en /workspace/out.
set -e

# Imagenes antiguas no traen el compilador de C++ para aarch64 (lo necesita imgui): se instala si falta.
if ! command -v aarch64-linux-gnu-g++ >/dev/null 2>&1; then
  echo ">> instalando g++-aarch64-linux-gnu"
  apt-get update -qq
  apt-get install -y --no-install-recommends g++-aarch64-linux-gnu
fi
export CXX_aarch64_unknown_linux_gnu=aarch64-linux-gnu-g++

[ -f /workspace/port/controls.ini ] || { echo "ERROR: falta la carpeta 'port' junto a este script (controls.ini, 'Pokemon Reloaded.sh', game-LEEME.txt)"; exit 1; }

PIN=b4367db3203c2a807b96c7850b2aa9d3c22b1d55   # commit de Klisee/pokemon-reloaded-android sobre el que se hizo el parche
cd /workspace
git config --global --add safe.directory '*'

if [ ! -d trimui-src/.git ]; then
  git clone https://github.com/Klisee/pokemon-reloaded-android.git trimui-src
fi
cd trimui-src
# Siempre se parte del commit limpio y se reaplica el parche (asi un parche nuevo nunca queda a medias)
git reset -q --hard "$PIN"
git clean -fdq
git apply ../trimui.patch
echo ">> parche aplicado"

cd src/OpenGMK
rustup target add aarch64-unknown-linux-gnu     # sobre el toolchain fijado por rust-toolchain.toml
export CARGO_TARGET_DIR=/target                 # volumen de Docker: compilar sobre el disco de Windows es muy lento
# libstdc++ y libgcc estaticos: la consola puede no tenerlos (imgui es C++)
export RUSTFLAGS="-C link-arg=-static-libstdc++ -C link-arg=-static-libgcc -L /usr/lib/aarch64-linux-gnu"

cargo build -p gm8emulator --bin gm8emulator --release \
  --target aarch64-unknown-linux-gnu --no-default-features --features trimui

BIN=/target/aarch64-unknown-linux-gnu/release/gm8emulator
aarch64-linux-gnu-strip "$BIN" -o /tmp/gm8emulator
file /tmp/gm8emulator
echo "== glibc maxima requerida: $(aarch64-linux-gnu-objdump -T /tmp/gm8emulator | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1)"
echo "== librerias dinamicas (DT_NEEDED):"
aarch64-linux-gnu-readelf -d /tmp/gm8emulator | grep NEEDED

# --- empaquetado
OUT=/workspace/out
PORT="$OUT/Data/ports/PokemonReloaded"
rm -rf "$PORT" "$OUT/Roms/PORTS/Pokemon Reloaded.sh"
mkdir -p "$PORT/game" "$PORT/libs" "$OUT/Roms/PORTS"
cp /tmp/gm8emulator "$PORT/gm8emulator"
# libstdc++ y libgcc_s (de gcc 10): la consola puede no tenerlas o traer una version mas vieja
for lib in libstdc++.so.6 libgcc_s.so.1; do
  f="$(find /usr/aarch64-linux-gnu /usr/lib/gcc-cross -name "$lib" 2>/dev/null | head -n 1)"
  [ -n "$f" ] || { echo "ERROR: no encuentro $lib en la imagen"; exit 1; }
  cp -L "$f" "$PORT/libs/$lib"
  echo ">> incluida $lib ($f)"
done
cp /workspace/port/controls.ini "$PORT/controls.ini"
cp /workspace/port/game-LEEME.txt "$PORT/game/LEEME.txt"
cp "/workspace/port/Pokemon Reloaded.sh" "$OUT/Roms/PORTS/Pokemon Reloaded.sh"
chmod +x "$PORT/gm8emulator" "$OUT/Roms/PORTS/Pokemon Reloaded.sh"
echo ">> listo en out/ : copia 'Roms' y 'Data' a la raiz de la SD"
