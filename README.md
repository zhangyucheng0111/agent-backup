# agent-backup 🛡️

> **One-command backup for Hermes Agent & OpenClaw** — skills, memories, config, scripts, persona.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Platform: macOS · Linux](https://img.shields.io/badge/Platform-macOS%20%C2%B7%20Linux-blue)

**🌐 Language / 语言: [English](README.md) | [中文](README.zh.md)**

---

Works with **Hermes Agent** and **OpenClaw**.

---

## ✨ Features

- ✅ **Universal detection** — auto-detects Hermes (`~/.hermes/`) and OpenClaw (`~/.openclaw/`)
- ✅ **Skills & scripts** — backs up all your SKILL.md files and custom Python/shell scripts
- ✅ **Memory & persona** — preserves long-term memory, user profile, and agent personality
- ✅ **Config (sanitized)** — saves your configuration with secrets stripped
- ✅ **Cron schedule** — captures task schedule (metadata only, no secrets)
- ✅ **No secrets leaked** — `.gitignore` blocks `.env`, `auth.json`, session data, logs, cache
- ✅ **One-command restore** — `restore.sh` places everything back in the right location
- ✅ **Auto-backup** (optional) — cron job runs Monday & Thursday at 9 AM
- ✅ **One-line setup** — run `setup.sh` and answer 2 questions

---

## 🚀 Quick Start

### One-command setup (new user)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zhangyucheng0111/agent-backup/main/scripts/setup.sh)
```

The script will:
1. Detect your agent (Hermes or OpenClaw)
2. Ask for your GitHub username and token
3. Create a **private** GitHub repo (`agent-backup`)
4. Set up SSH key for push
5. Run the first backup
6. (Optional) Configure auto-backup twice a week

> **Prerequisites:** [Git](https://git-scm.com/), a [GitHub](https://github.com) account, and a
> Personal Access Token with `repo` scope ([create one](https://github.com/settings/tokens/new)).
> Your agent (Hermes or OpenClaw) must already be installed.

### Manual setup

```bash
# Clone the repo
git clone git@github.com:zhangyucheng0111/agent-backup.git
cd agent-backup

# Run first backup
bash scripts/backup.sh

# (Optional) Set up auto-backup twice a week
crontab -e
# Add: 0 9 * * 1,4 cd /path/to/agent-backup && bash scripts/backup.sh >> backup.log 2>&1
```

### Restore on a new machine

```bash
# 1. Install your agent first (Hermes or OpenClaw)

# 2. Clone your backup repo
git clone git@github.com:YOUR_USERNAME/agent-backup.git
cd agent-backup

# 3. Restore everything
bash scripts/restore.sh

# 4. Re-create your API keys
cp template/.env.example ~/.hermes/.env
# Edit ~/.hermes/.env with your real keys
```

---

## 📦 Backup Contents

| What | Source | Destination in repo |
|------|--------|-------------------|
| Skills (SKILL.md) | `$AGENT_HOME/skills/` | `skills/` |
| Custom scripts | `$AGENT_HOME/scripts/*.py` `*.sh` | `scripts/` |
| Long-term memory | `$AGENT_HOME/memories/MEMORY.md` | `memories/MEMORY.md` |
| User profile | `$AGENT_HOME/memories/USER.md` | `memories/USER.md` |
| Agent persona | `$AGENT_HOME/SOUL.md` | `prompts/SOUL.md` |
| Config (sanitized) | `$AGENT_HOME/config.yaml` | `config/config.yaml` |
| Cron schedule (ref) | `$AGENT_HOME/cron/jobs.json` | `archive/cron-jobs-reference.txt` |

### What is NOT backed up

| File/Dir | Reason |
|----------|--------|
| `.env` | API keys, tokens, passwords |
| `auth.json` | OAuth tokens |
| `channel_directory.json` | Platform connection info |
| `state.db` / `sessions/` | Conversation history |
| `cron/jobs.json` (raw) | May contain tokens in prompts |
| `logs/` | Log files |
| `hermes-agent/` / `openclaw/` | Source code (re-installable) |
| `lsp/`, `node/` | Binary dependencies |
| All caches | Temporary data |

> These patterns are in `.gitignore` — they can never be accidentally committed.

---

## 📁 Repository Structure

```
agent-backup/
├── README.md                    # This file
├── README.zh.md                 # 中文版
├── LICENSE                      # MIT
├── .gitignore                   # Sensitive file exclusions
├── scripts/
│   ├── setup.sh                 # ★ One-click setup wizard
│   ├── backup.sh                # Auto-backup: copy → commit → push
│   ├── restore.sh               # Restore: extract → place back
│   └── detect-env.sh            # Auto-detect Hermes or OpenClaw
├── template/
│   └── .env.example             # API key template
└── docs/
    ├── getting-started.md       # Detailed setup guide
    ├── customize.md             # Customizing backup content
    └── troubleshooting.md       # Common issues
```

---

## 🔐 Security

- **Your API keys are NEVER uploaded** — `.gitignore` blocks `.env` and all credential files
- **Private repo** — your data is only accessible to you
- **SSH key authentication** — no password reuse
- **Token only in `.env`** — never embedded in scripts or git history
- **Sanitized config** — backup script warns if it finds embedded secrets in config.yaml

### What you need to re-configure on a new machine

- LLM Provider API keys (DeepSeek, OpenAI, Anthropic, etc.)
- Platform bot tokens (Telegram, Discord, Feishu, etc.)
- GITHUB_TOKEN

---

## 🧪 Compatibility

| Agent | Status | Tested on |
|-------|--------|-----------|
| **Hermes Agent** | ✅ Full support | macOS 12.7, Linux |
| **OpenClaw** | ✅ Full support | macOS, Linux |
| Windows (WSL2) | ⚡ Should work | Untested |

---

## 📝 License

MIT — free to use, modify, and distribute.

---

## 🙏 Credits

Built for the [Hermes Agent](https://hermes-agent.nousresearch.com) and OpenClaw communities.
