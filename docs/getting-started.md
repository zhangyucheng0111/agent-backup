# Getting Started Guide

## Prerequisites

- [Git](https://git-scm.com/downloads) installed
- [GitHub](https://github.com) account
- GitHub Personal Access Token with **repo** scope
  ([create one](https://github.com/settings/tokens/new))
- Your agent (Hermes or OpenClaw) already installed

## Option 1: One-Click Setup (Recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zhangyucheng0111/agent-backup/main/scripts/setup.sh)
```

The script guides you through everything interactively.

## Option 2: Manual Setup

### 1. Clone the tool

```bash
git clone git@github.com:zhangyucheng0111/agent-backup.git
cd agent-backup
```

### 2. Run a backup

```bash
bash scripts/backup.sh
```

The script detects your agent installation automatically.

### 3. Verify your backup on GitHub

Go to https://github.com/YOUR_USERNAME/agent-backup and check that files are there.

## Setting Up Auto-Backup

### Via cron (recommended)

```bash
crontab -e
```

Add one of these lines:

```bash
# Twice a week (Mon & Thu at 9 AM)
0 9 * * 1,4 cd /path/to/agent-backup && bash scripts/backup.sh >> backup.log 2>&1

# Daily at 9 AM
0 9 * * * cd /path/to/agent-backup && bash scripts/backup.sh >> backup.log 2>&1

# Every 6 hours
0 */6 * * * cd /path/to/agent-backup && bash scripts/backup.sh >> backup.log 2>&1
```

### Via Hermes Cron (if using Hermes Agent)

```bash
hermes cron create "0 9 * * 1,4" --prompt "cd ~/agent-backup && bash scripts/backup.sh"
```

## Restoring on a New Machine

1. Install your agent (Hermes or OpenClaw)
2. Clone your backup repo:
   ```bash
   git clone git@github.com:YOUR_USERNAME/agent-backup.git
   ```
3. Run restore:
   ```bash
   cd agent-backup && bash scripts/restore.sh
   ```
4. Re-create your `.env` with API keys:
   ```bash
   cp template/.env.example ~/.hermes/.env
   ```
   Then edit with your real keys.
5. (If using Hermes) Run `hermes doctor` to verify.
