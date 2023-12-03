#!/bin/sh
echo -ne '\033c\033]0;golf_cards_godot\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/golf_cards_godot.x86_64" "$@"
