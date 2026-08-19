# Teleprompter

A tiny, always-on-top macOS teleprompter — a small horizontal strip you drag
right under your laptop camera so you can read a script while appearing to look
into the lens. Runs entirely offline.

![Teleprompter window](https://github.com/user-attachments/assets/cc40314a-448e-4d4f-842e-475b1dbe269b)

- **Frameless, translucent, always-on-top** — floats above Zoom / QuickTime /
  Riverside while you record.
- **Horizontal strip** you can drag anywhere and resize very small.
- **Auto-scroll** with adjustable speed, plus mouse-wheel / arrow-key scrubbing.
- **Instant text-size + speed changes** while you read.
- **Menu-bar controlled** — you start it yourself; it never runs unattended.
- Script and settings are remembered between launches.

## Build

Requires the Swift toolchain (Command Line Tools is enough — no full Xcode):

```sh
./build.sh
```

This compiles the four `.swift` files into a single terminal binary,
`./teleprompter`. There's no `.app` bundle and no dependencies. (SwiftPM isn't
used because its manifest library is broken in CLT-only installs.)

## Run & control

```sh
./teleprompter        # runs it; Ctrl-C to stop
./teleprompter &      # runs it detached
```

Optional alias for `~/.zshrc`:

```sh
alias teleprompter='/path/to/teleprompter/teleprompter'
```

It runs as a **menu-bar app (no Dock icon)**. Click the caption-bubble icon to
**Show/Hide the teleprompter, Edit the script, or Quit**. Force-kill:
`pkill -f /teleprompter`.

## Controls

Every control is both a button (in the side gutters) and a shortcut:

| Key          | Action                     |
|--------------|----------------------------|
| `Space`      | Play / pause scrolling     |
| `R`          | Restart from the top       |
| `+` / `-`    | Speed up / slow down       |
| `]` / `[`    | Bigger / smaller text      |
| `↑` / `↓`    | Nudge scroll up / down     |
| scroll wheel | Scrub through the script    |
| ⌥ + scroll   | Window opacity (see-through) |
| `E`          | Edit / paste your script   |
| `Esc`        | Done editing / hide window |
| `⌘Q`         | Quit                       |

Shortcuts and scroll-scrubbing work while the teleprompter window is focused.
Auto-scroll keeps running after you switch to your recording app — press `Space`
to start it, then click into your recording app.

## Privacy

Fully local — **no network activity of any kind.** The app imports only Apple's
`AppKit`/`SwiftUI` frameworks: no `URLSession`, no sockets, no analytics, no
third-party libraries.

- **Stores:** your script text + settings (font size, speed) in local macOS
  `UserDefaults` (a preferences plist in your home Library). Nothing else is
  written, and nothing leaves the device.
- **Reads:** keystrokes/scroll only while its own window is focused (a local
  event monitor scoped to this app — not a system-wide keylogger).
- **Never touches** the camera, microphone, files, contacts, or location.

Works identically in airplane mode. To wipe a sensitive script, just paste over
it in Edit.
