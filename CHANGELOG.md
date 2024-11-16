## Puzzle Vibes up

(Features available with latest build from source)

#### Notable changes

...

## Puzzle Vibes 0.8.5
*16 Nov 2024*

#### Notable changes

Start using a change log.

* Add support for `wasm32_emscripten` build target making it possible to target the Web via `emscripten`/`emcc`
* Record, load, show and save best solve times for puzzle images
* Add 3 new default puzzle images

#### BUGS reported upstream

* V https://github.com/vlang/v/issues/22873

#### Breaking changes

...

#### Commits

* game: add 3 new builtin puzzle images
* all: record, save, load and show best solve times
* all, wasm32_emscripten: fix saving settings, experimental fullscreen switch
* all, wasm32_emscripten: saving settings, use `shy.paths`, add experimental fullscreen switch
* app: remove old commented code
* app: support "pixel art" image filtering (`.nearest`) via file name prefix `pixelated_`
* button: allow for wider text on back button
* data: add debug output when loading image db entries
* app: make a few `wasm32_emscripten` tweaks
* all: do not use closures, make `wasm32_emscripten` compatible
