#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

install -Dm755 "$ROOT/bin/tg" "$HOME/.local/bin/tg"
install -Dm755 "$ROOT/bin/tg-bot" "$HOME/.local/bin/tg-bot"
install -Dm644 "$ROOT/systemd/telegram-claude-cli.service" \
  "$HOME/.config/systemd/user/telegram-claude-cli.service"

mkdir -p "$HOME/.config/tg-bot" "$HOME/.local/state/tg-bot"

if [ ! -f "$HOME/.config/tg-bot/config.env" ]; then
  install -m600 "$ROOT/examples/config.env.example" "$HOME/.config/tg-bot/config.env"
  echo "Created ~/.config/tg-bot/config.env — add your bot token and chat id."
fi

if [ ! -f "$HOME/.config/tg-bot/projects.json" ]; then
  install -m644 "$ROOT/examples/projects.json.example" "$HOME/.config/tg-bot/projects.json"
  echo "Created ~/.config/tg-bot/projects.json — edit your projects."
fi

systemctl --user daemon-reload
echo "Next: edit the config, then run: systemctl --user enable --now telegram-claude-cli"
