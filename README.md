# Pokémon Reloaded para Trimui Smart Pro

Port **no oficial** de *Proyecto Reloaded* (fangame de Pokémon hecho con GameMaker 8) para la **Trimui Smart Pro**,
sobre el emulador de GameMaker [OpenGMK](https://github.com/OpenGMK/OpenGMK).
Se ejecuta de forma nativa en Linux/aarch64 con OpenGL ES y SDL2, sin pasar por PortMaster.

> **Este paquete no incluye el juego.** Necesitas tu propia copia de *Proyecto Reloaded* (el `.exe` y su carpeta `data`).
> No tiene relación con Nintendo, Game Freak ni The Pokémon Company.

## Estado

| | |
|---|---|
| Consola probada | Trimui Smart Pro (PowerVR GE8300, 1 GB de RAM), firmware JEB+ |
| Versión del juego probada | *Proyecto Reloaded The Last Beta 1.9.2.2 Full* |
| Funciona | Vídeo (OpenGL ES 3.2), sonido WAV/MP3/MIDI, controles completos, partidas largas |
| No probado | Trimui Brick y otras consolas, otros firmwares, otras versiones del juego |

Requisito de sistema: glibc 2.30 o superior (el binario se compila contra glibc 2.31).

## Instalación

Copia el contenido de este paquete a la raíz de la tarjeta SD:

```
SDCARD/
├── Roms/PORTS/Pokemon Reloaded.sh          lanzador (aparece en el menú de Ports)
├── Imgs/PORTS/Pokemon Reloaded.png         imagen de la carátula
└── Data/ports/PokemonReloaded/
    ├── gm8emulator                         emulador compilado para aarch64
    ├── libs/                               libstdc++ y libgcc_s (la consola puede no traerlas)
    ├── controls.ini                        controles (editable)
    ├── soundfont/TimGM6mb.sf2              instrumentos para la música MIDI
    └── game/                               <-- copia aquí el juego (.exe y carpeta data)
```

Después abre **Pokemon Reloaded** desde el menú de Ports. El lanzador usa el primer `.exe` que encuentre en `game/`.

La primera ejecución tarda más: crea un archivo de intercambio (swap) de 768 MB en la SD (ver [Memoria](#memoria-y-swap)).

## Controles

Reparto por defecto. Se puede cambiar en `controls.ini` sin recompilar.

| Mando | Tecla | Función en el juego |
|---|---|---|
| Cruceta y palanca izquierda | Flechas | Moverse |
| A, B, X, Y | Z, X, C, V | Acciones (V: bicicleta / ver) |
| L1 | B | Sacar Pokémon |
| R1 | A | Objeto asignado |
| L2 | Espacio | Pokémon |
| R2 | O | Mochila |
| Start | Enter | Menú |
| Menú (botón central) | Esc | Salir |
| Select (toque corto) | M | Mapa |
| Palanca derecha ↑ / ↓ | S / E | Cambio / escapar en combate |
| Palanca derecha ← / → | F / P | Flauta o buscar / porcentaje de captura y menú de entrenador |

**Segunda capa: mantener Select** y pulsar:

| Mando | Tecla |
|---|---|
| Cruceta ↑ → ↓ ← | 1, 2, 3, 4 |
| A, B, X, Y | 5, 6, 7, 8 |
| L1 | 9 |
| R1 | F8 (smartphone) |
| R2 | Q (misiones) |
| Palanca derecha ↑ / ↓ | F12 (Pokédex) / D (dar objeto) |
| Palanca derecha ← / → | L (estilo de menú, ubicaciones en la Pokédex) / K (color de menú) |

El mapa (M) se envía al **soltar** Select, y solo si no se usó ningún otro botón mientras estaba pulsado.

### Personalizar

`controls.ini` explica su formato en los comentarios del propio archivo. En resumen: `b<N>` es el botón N, `a<N>+` / `a<N>-` es el eje N en cada dirección,
`hat-up` etc. es la cruceta, y `shift+...` es la segunda capa. Si el archivo tiene alguna línea válida, **reemplaza por completo** la tabla por defecto;
si lo borras, se usa la tabla incluida en el programa.

Para ver los números que envía tu mando, crea un archivo vacío `debug.on` en `Data/ports/PokemonReloaded/`, juega y revisa `log.txt`
(líneas como `[input] boton 3 abajo` o `[input] eje 4- activo`).

## Memoria y swap

La consola tiene 1 GB de RAM y el juego llega a unos 560 MB durante la carga (luego se estabiliza en torno a 300 MB). Sin swap, el sistema lo mata durante la carga.
Por eso el lanzador crea y activa un `swapfile` de 768 MB en `Data/ports/PokemonReloaded/` la primera vez.

- Para desactivarlo, crea un archivo vacío `swap.off` en esa carpeta.
- El registro de memoria está **desactivado por defecto**. Para activarlo, crea un archivo vacío `mem.on` en esa carpeta: se escribirá `mem.txt` con la memoria usada
  por el emulador, la disponible y el swap libre cada 5 segundos.
- Haya o no registro, `log.txt` termina con el código de salida del juego (137 = cerrado por falta de memoria).

## Otros ajustes

- **Escalado:** el juego pide su propio escalado. Por defecto se mantiene la proporción (`aspect`). Para estirar a pantalla completa, cambia `OPENGMK_SCALING` a `full` en el lanzador.
- **Música MIDI:** se sintetiza con `soundfont/TimGM6mb.sf2` (6 MB, a propósito: el emulador carga el soundfont entero en RAM). Puedes poner otro `.sf2` en `soundfont/`, pero uno grande no cabrá en 1 GB.
- **Diagnóstico:** `log.txt` empieza con la versión del lanzador y el soundfont usado; después viene la salida del emulador y, al final, el código de salida. Con `debug.on` anota los botones pulsados, y con `mem.on` se escribe `mem.txt`.

## Cambios respecto al port Android

El port se basa en [Klisee/pokemon-reloaded-android](https://github.com/Klisee/pokemon-reloaded-android), commit `b4367db3203c2a807b96c7850b2aa9d3c22b1d55` (v0.3.8),
que ya adaptaba OpenGMK a OpenGL ES. Los cambios están en `fuente/trimui.patch`:

| Parte | Cambio |
|---|---|
| `vendor/sdl2lite` (nuevo) | Enlace mínimo a SDL2 cargado con `dlopen`. No hay dependencia en tiempo de enlace: se usa la `libSDL2` de la consola, con su driver de vídeo `mali`. |
| `vendor/ramen` | Nuevo backend SDL2 (`platform/sdl2.rs`, activado con la feature `sdl2`): ventana a pantalla completa, contexto GLES 3.0, eventos, mando. La consola no tiene X11. |
| Mando → teclado | El mando (API de joystick de SDL) genera eventos de teclado: cruceta, botones, ejes, segunda capa con toque corto, y configuración por `controls.ini`. |
| `vendor/udon` | `libsoundio` pasa a ser opcional (feature `soundio`), porque enlaza PulseAudio y JACK, que la consola no tiene. |
| `gm8emulator` `render/opengl/sdl_gl.rs` (nuevo) | Contexto OpenGL ES y carga de funciones con `SDL_GL_GetProcAddress` (las funciones que GLES no tiene se sustituyen por funciones vacías, como en el port Android). |
| `gm8emulator` `game/audio/sdl_audio.rs` (nuevo) | Salida de audio por `SDL_OpenAudioDevice`, con el mismo diseño que el backend AAudio de Android. |
| `gm8emulator` `build.rs`, `Cargo.toml` | Feature `trimui` y cfgs propios (`gles_backend`, `native_audio`, `fixed_screen`, `x11_gl`). El crate `clipboard` pasa a ser opcional (arrastra X11). |
| Pantalla | En `trimui` el tamaño inicial de la ventana es el de la pantalla y no se mueve ni redimensiona. |

Fuera del emulador: lanzador con diagnóstico de memoria y swap, soundfont incluido, y un entorno Docker (Debian 11, glibc 2.31) para compilar de forma reproducible.

## Compilar desde cero

Requisitos: Windows con Docker Desktop y PowerShell. Desde la carpeta `fuente/`:

```powershell
.\build.ps1 image       # construye la imagen de compilación (una vez)
.\build.ps1 probe       # opcional: compila GLProbe (diagnóstico de OpenGL ES) -> out\Apps\GLProbe
.\build.ps1 emulator    # clona el repositorio, aplica trimui.patch, compila y empaqueta -> out\
```

`build-emulator.sh` fija el commit del repositorio original y reaplica siempre el parche desde cero.
El resultado queda en `out\Roms` y `out\Data`, listos para copiar a la SD.

## Limitaciones conocidas

- Carga inicial lenta por el swap en la SD, y poca memoria libre durante la partida.
- La música MIDI usa un soundfont pequeño: la calidad es correcta pero modesta, y la síntesis en tiempo real consume CPU.
- El texto que se escribe con teclado (nombres, etc.) solo funciona con un teclado USB: no hay teclado en pantalla.
- Solo se ha probado una versión del juego en una consola.

## Referencias y licencias

- **OpenGMK** (emulador/runner de GameMaker 8 en Rust): <https://github.com/OpenGMK/OpenGMK>
- **Port Android sobre OpenGMK**, base de este trabajo: <https://github.com/Klisee/pokemon-reloaded-android>
- **SDL2**: <https://www.libsdl.org/>
- **TimGM6mb.sf2** (soundfont): Tim Brechbill y David Bolton, GPL-2. Origen según el paquete de Debian: <https://github.com/musescore/musescore-old/commit/90c33ef9d87b3f5ff92efd3b07d89eb455fb1fef>. Su licencia está en `soundfont/LICENCIA-TimGM6mb.txt`.
- **libstdc++ y libgcc_s** (incluidas en `libs/`): GCC, GPL con excepción de biblioteca en tiempo de ejecución.

El código de OpenGMK y de su port Android se distribuye bajo **GPL-2.0**, y el binario `gm8emulator` de este paquete es una obra derivada.
Por eso se acompaña de una copia de la licencia (`LICENSE-GPL-2.0.txt`) y de las fuentes: el repositorio original (commit indicado arriba)
más `fuente/trimui.patch`, que contiene todas las modificaciones, y los scripts para reproducir la compilación.
El juego *Proyecto Reloaded* no forma parte de este paquete ni está cubierto por esta licencia.
