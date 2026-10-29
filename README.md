# telegram-claude-cli

A Telegram front-end for the **live Claude Code session** running on your machine. Messages you send on Telegram are injected into the session you are already using in the terminal, and Claude's replies are relayed back to the chat with live streaming.

No terminal scraping, no tmux keystroke injection: it uses Claude Code's local session registry and messaging socket, then tails the session transcript.

## Features

- **Live session binding** — targets the interactive `claude` session on this machine (discovered from `~/.claude/sessions/<pid>.json`), so Telegram and the terminal share one conversation.
- **Streaming replies** — a placeholder message updates with a spinner, typing indicator, and partial text as Claude answers.
- **Projects & sessions** — icon menus to switch project or resume a past conversation; non-live sessions fall back to `claude -p --resume`.
- **File forwarding** — send documents/photos to the bot; choose a project and they are stored in that project's inbox.
- **Compact keyboard** — one ✳️ Claude button expands the icon menu; ✖️ Minimize collapses it.
- **No secrets in the repo** — the bot token and chat id are read from a private config file.

## Requirements

- Python 3.10+ (standard library only)
- [Claude Code](https://claude.com/claude-code) installed as `claude` in your `PATH` (or adjust `CLAUDE` in `bin/tg-bot`)
- A Telegram bot token from [@BotFather](https://t.me/BotFather)
- Linux/macOS with a user systemd instance (for the service; you can also run `tg-bot` manually)

## Quick start

```bash
git clone https://github.com/Ess800/telegram-claude-cli.git
cd telegram-claude-cli
./install.sh
```

Then edit `~/.config/tg-bot/config.env`:

```ini
TG_BOT_TOKEN=123456789:AA...
TG_CHAT_ID=123456789
```

`TG_CHAT_ID` is your numeric Telegram user id. Send a message to the bot and run
`curl -s "https://api.telegram.org/bot<TOKEN>/getUpdates"` to find it, or use
[@userinfobot](https://t.me/userinfobot).

Edit `~/.config/tg-bot/projects.json`:

```json
{
  "version": 1,
  "projects": {
    "default": {"display_name": "Home", "path": "~"},
    "example": {"display_name": "Example", "path": "~/src/example"}
  }
}
```

Start it:

```bash
systemctl --user enable --now telegram-claude-cli
loginctl enable-linger "$USER"   # optional: keep running after logout
journalctl --user -u telegram-claude-cli -f
```

## How it works

1. `tg-bot` periodically discovers the interactive Claude session from
   `~/.claude/sessions/<pid>.json` (requires `entrypoint: "cli"` and a live
   `messagingSocketPath`).
2. A Telegram message is delivered as a user turn over that UNIX socket, using
   the session's `peerToken`.
3. The bot tails the session's JSONL transcript (`~/.claude/projects/<cwd>/<session>.jsonl`)
   and edits one Telegram message with the assistant reply as it appears.
4. If no live session matches the selected project, it runs
   `claude -p --resume <session-id>` (or a new session) and streams the JSON output.

Claude Code must accept cross-session input; set `"crossSessionInbound": "accept"`
in `~/.claude/settings.json` if your build gates it.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `TG_BOT_TOKEN` | — | BotFather token (required) |
| `TG_CHAT_ID` | — | Numeric chat id allowlist (required) |
| `TG_PROJECTS_FILE` | `~/.config/tg-bot/projects.json` | Project list |

State lives in `~/.local/state/tg-bot/` (inbox, last output, offsets).
The bot only accepts messages from `TG_CHAT_ID`.

## Keyboard

The persistent reply keyboard is the main menu:

`🎛 Menu · 💬 Live chat · 🗂 Sessions · 📁 Projects · 🆕 New · 🔄 Refresh · 📋 Last · 📥 Incoming · ✖️ Minimize`

- **Menu** shows project, mode, live session, queue, and inbox status.
- **Sessions / Projects** open icon click menus with `⬅️ Back`.
- **Incoming** shows files/text you sent to the bot.
- **✖️ Minimize** collapses everything to a single **✳️ Claude** button.

## Security

- The bot can inject user turns into your local Claude session. Treat the bot
  token like a shell credential.
- Keep `~/.config/tg-bot/config.env` at mode `600`; it is git-ignored.
- `TG_CHAT_ID` is an allowlist, but token secrecy is what actually protects you.
- The bot does not run terminal commands itself; it talks to the Claude session,
  whose own permission settings decide what tools may run.

## Limitations

- Relies on Claude Code's local session registry and socket protocol, which are
  internal interfaces and may change between versions.
- Telegram limits message edits (roughly one per second per chat), so streaming
  is throttled.
- A message that arrives while Claude is mid-turn is absorbed into the current
  turn rather than starting a new one.
- Long replies are chunked at Telegram's 4096-character limit.

## License

MIT — see [LICENSE](LICENSE).
