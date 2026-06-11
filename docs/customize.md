# Customizing Your Backup

## Adding/Removing Backup Items

Edit `scripts/backup.sh` to customize what gets backed up.

### Add a new directory to backup

Find the section near the top of backup.sh:

```bash
# ── 1. Skills ───────────────────────────────
```

Add a new section:

```bash
# ── X. Custom Data ──────────────────────────
echo ""
echo "[X] Backing up custom data..."
if [ -d "$AGENT_HOME/custom_dir" ]; then
  rm -rf "$REPO_DIR/custom"
  cp -r "$AGENT_HOME/custom_dir" "$REPO_DIR/custom"
  echo "  ✓ custom_dir backed up"
fi
```

### Exclude specific subdirectories

When backing up skills, some internal state files are excluded:

```bash
rm -rf "$REPO_DIR/skills/.curator_backups" 2>/dev/null || true
```

You can add more exclusions in the same pattern.

## Using Multiple GitHub Repos

If you want separate repos for different purposes:

```bash
# Create another backup repo
mkdir ~/agent-backup-work
cd ~/agent-backup-work
git init
git remote add origin git@github.com:YOU/agent-backup-work.git

# Copy only backup.sh (the rest of the tool is reusable)
cp ~/agent-backup/scripts/backup.sh scripts/
cp ~/agent-backup/scripts/detect-env.sh scripts/
```

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `AGENT_HOME` | Force agent home directory | Auto-detected |
| `AGENT_TYPE` | Force agent type (hermes/openclaw) | Auto-detected |
| `GITHUB_TOKEN` | For HTTPS push auth | Read from .env |

Example:

```bash
AGENT_HOME=/custom/path/.hermes bash scripts/backup.sh
```
