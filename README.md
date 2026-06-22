# vim with a hat

<img width="1000" alt="Screenshot 2026-06-22 at 11 33 28" src="https://github.com/user-attachments/assets/6930dfee-e0d8-4550-ab26-36eb073f6c46" />

A tiny native macOS GUI hat for `vim`/`nvim`. Run `vh <file>` and a real native window pops open with your editor inside it; close it with `:q` and the window goes away. That's the whole idea — a "quick open" you can fire at a file and dismiss, without launching a full terminal app.

It is deliberately low-footprint: a single ~2 MB Mach-O binary that links only system frameworks and the OS-provided Swift runtime. No Electron, no Chromium, no bundled Node — nothing that balloons into a megalodon. Terminal emulation is provided by [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm), compiled statically into the binary. My motivation here was to simply have a way to pipe vim through a GUI so I can run shell outputs from Ghostty.

## Build & install

Requires the Swift toolchain (ships with Xcode) and `nvim` or `vim` on `PATH`.

```sh
make install            # builds release, installs `vh` to ~/.local/bin
# or pick a prefix:
make install PREFIX=/usr/local
```

Make sure the install dir is on your `PATH`, then:

```sh
vh notes.md                 # open a file
vh src/main.swift README.md # open several
vh                          # scratch buffer
vh --font-size 15 ~/.zshrc  # bump the font
```

## How it works

`vh` boots a minimal `NSApplication`, puts a `SwiftTerm` terminal view in a single window, and spawns your editor in a PTY with the file paths as arguments. It inherits your environment and working directory (so relative paths and your editor config just work), forces `TERM=xterm-256color` + `COLORTERM=truecolor`, mirrors the window title from the editor, and exits with the editor's own exit code when it quits.

## Options

| Flag | Description |
| --- | --- |
| `--editor <path>` | Editor binary to run. Default: `$VH_EDITOR`, then `nvim`, then `vim`. |
| `--font-size <pt>` | Terminal font size in points (default `13`). |
| `-h`, `--help` | Show help. |
| `-v`, `--version` | Show version. |

Shell aliases (like `vim` → `nvim`) don't apply to spawned processes, so `vh` resolves a real executable on `PATH` itself.

## Development

```sh
make build                          # debug build
make run ARGS="README.md"           # build + run
make clean
```
