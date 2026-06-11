# Troubleshooting

## "No agent installation found"

**Cause:** Neither `~/.hermes/` nor `~/.openclaw/` exists.

**Fix:** Install your agent first:
- Hermes: `curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash`
- OpenClaw: Follow OpenClaw's installation guide

Or set `AGENT_HOME` manually:
```bash
AGENT_HOME=/path/to/agent bash scripts/backup.sh
```

## "Permission denied (publickey)" on push

**Cause:** SSH key not added to GitHub.

**Fix:** Add your SSH key:
1. Copy your public key: `cat ~/.ssh/id_ed25519*.pub`
2. Go to https://github.com/settings/keys
3. Click "New SSH Key", paste, and save.

## "Could not read Username for 'https://github.com'"

**Cause:** Using HTTPS remote without a token.

**Fix 1:** Switch to SSH:
```bash
git remote set-url origin git@github.com:YOUR_USERNAME/agent-backup.git
```

**Fix 2:** Add GITHUB_TOKEN to your `.env` file:
```bash
echo "GITHUB_TOKEN=ghp_yo...n" >> ~/.hermes/.env
```

## "RPC failed; HTTP 400"

**Cause:** Network firewall blocking GitHub (common in China).

**Fix:** Use SSH instead of HTTPS, or connect via a proxy/VPN.

## "Nothing to back up" after first run

**Cause:** No changes since last backup. This is normal — run `backup.sh` again after you add new skills or scripts.

## Restore script says files are missing

**Cause:** The backup repo doesn't contain the expected directories.

**Fix:** Make sure you ran `backup.sh` at least once successfully before trying to restore.

## "command not found: python3"

**Cause:** Python 3 is not installed.

**Fix:** Install Python 3:
```bash
# macOS
brew install python

# Linux (Ubuntu/Debian)
sudo apt install python3

# Linux (CentOS/RHEL)
sudo yum install python3
```

## "No remote configured"

**Cause:** The backup repo doesn't have a GitHub remote set.

**Fix:** Add your remote:
```bash
git remote add origin git@github.com:YOUR_USERNAME/agent-backup.git
```
