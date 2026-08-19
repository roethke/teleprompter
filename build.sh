#!/bin/bash
# Compiles Teleprompter into a plain terminal binary at ./teleprompter.
# No .app bundle — you launch it from the terminal and control it from the
# menu bar item (or Ctrl-C / the menu's Quit).
set -euo pipefail
cd "$(dirname "$0")"

echo "Compiling…"
swiftc -O -o teleprompter \
  Sources/Teleprompter/PrompterModel.swift \
  Sources/Teleprompter/AppDelegate.swift \
  Sources/Teleprompter/ContentView.swift \
  Sources/Teleprompter/main.swift

# Ad-hoc signature so macOS is happy to run it locally.
codesign --force --sign - teleprompter >/dev/null 2>&1 || true

echo "Built ./teleprompter"
echo
echo "Run it:        ./teleprompter        (Ctrl-C to stop, or use the menu bar icon)"
echo "Run detached:  ./teleprompter &"
echo
echo "Optional alias (add to ~/.zshrc):"
echo "  alias teleprompter='$(pwd)/teleprompter'"
