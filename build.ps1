# PowerShell (Windows + Docker Desktop). Ejecutar desde esta carpeta.
#   .\build.ps1 image     construye la imagen completa (una vez)
#   .\build.ps1 gpp       solo anade g++ a una imagen ya construida (rapido, evita recrearla)
#   .\build.ps1 probe     compila GLProbe  -> out\Apps\GLProbe
#   .\build.ps1 emulator  compila el emulador y empaqueta el port -> out\Roms y out\Data
param([ValidateSet("image","gpp","emulator","probe")]$Task = "probe")
switch ($Task) {
  "image"    { docker build --no-cache -t trimui-rust . }
  "gpp"      { docker build -t trimui-rust -f Dockerfile.gpp . }
  "probe"    { docker run --rm -v "${PWD}:/workspace" trimui-rust sh /workspace/probe/package.sh }
  "emulator" {
    docker run --rm -v "${PWD}:/workspace" `
      -v trimui-cargo:/opt/cargo/registry -v trimui-rustup:/opt/rustup -v trimui-target:/target `
      trimui-rust sh /workspace/build-emulator.sh
  }
}
