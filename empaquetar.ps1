# Crea dist\PokemonReloaded-Trimui.zip listo para compartir.
# Antes: .\build.ps1 emulator   (genera out\ con el binario, libs y el lanzador)
$ErrorActionPreference = "Stop"
$name = "PokemonReloaded-Trimui"
$port = Join-Path $PWD "out\Data\ports\PokemonReloaded"
$sh   = Join-Path $PWD "out\Roms\PORTS\Pokemon Reloaded.sh"
$cover= Join-Path $PWD "out\Imgs\PORTS\"

foreach ($f in @("$port\gm8emulator", "$port\libs\libstdc++.so.6", "$port\libs\libgcc_s.so.1", $sh)) {
  if (-not (Test-Path $f)) { throw "Falta $f. Ejecuta primero .\build.ps1 emulator" }
}

$dist = Join-Path $PWD "dist\$name"
if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Force -Path "$dist\Roms\PORTS", "$dist\Data\ports\PokemonReloaded", "$dist\fuente" | Out-Null

# --- el port (lo que va a la SD)
Copy-Item "$port\*" "$dist\Data\ports\PokemonReloaded" -Recurse -Force
Copy-Item $sh "$dist\Roms\PORTS\" -Force
# La carpeta port\ es la referencia: sus lanzador, controles y soundfont pisan lo que haya en out\
Copy-Item "port\Pokemon Reloaded.sh" "$dist\Roms\PORTS\" -Force
Copy-Item "port\controls.ini" "$dist\Data\ports\PokemonReloaded\" -Force
Copy-Item "port\soundfont" "$dist\Data\ports\PokemonReloaded\" -Recurse -Force
# por si el juego, el swap o los diagnosticos de tus pruebas estan en out\
foreach ($junk in @("swapfile", "swap.on", "swap.off", "debug.on", "mem.on", "log.txt", "mem.txt")) {
  Remove-Item "$dist\Data\ports\PokemonReloaded\$junk" -Force -ErrorAction SilentlyContinue
}
# la carpeta game\ va vacia, solo con las instrucciones
$game = "$dist\Data\ports\PokemonReloaded\game"
if (Test-Path $game) { Remove-Item $game -Recurse -Force }
New-Item -ItemType Directory -Force -Path $game | Out-Null
Copy-Item "port\game-LEEME.txt" "$game\LEEME.txt" -Force

# --- documentacion y licencia
Copy-Item README.md, LICENSE-GPL-2.0.txt $dist -Force

# --- Carátula
Copy-Item "port\Pokemon Reloaded.png" "$cover\Pokemon Reloaded.png" -Recurse -Force

# --- fuente (parche + scripts para reproducir la compilacion)
foreach ($f in @("trimui.patch", "Dockerfile", "Dockerfile.gpp", "build.ps1", "build-emulator.sh")) {
  Copy-Item $f "$dist\fuente\" -Force
}
Copy-Item port  "$dist\fuente\port"  -Recurse -Force

# --- zip
$zip = Join-Path $PWD "dist\$name.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path "$dist\*" -DestinationPath $zip
Write-Host "Listo: $zip"
Write-Host "Comprueba que dentro NO estan los archivos del juego ni log.txt / mem.txt / swapfile."
