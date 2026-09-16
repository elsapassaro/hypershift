#!/usr/bin/env bash
# Wrapper kept for docs / muscle memory (./patterns.sh make install).
exec "$(cd "$(dirname "$0")" && pwd)/pattern.sh" "$@"
