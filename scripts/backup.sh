#!/usr/bin/env bash
# ============================================
# backup.sh — Universal backup for Hermes & OpenClaw
# ============================================
# Backs up: skills, memories, config (sanitized),
# custom scripts, persona (SOUL.md).
# Skips: .env, auth.json, session data, logs, cache.
#
# Usage:
#   ./scripts/backup.sh
#   AGENT_HOME=/custom/path ./scripts/backup.sh
#
# Requirements: git, SSH key or GITHUB_TOKEN in .env
# ============================================

set -euo pipefail

# ── Config ──────────────────────────────────
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# Load agent detection
source "$REPO_DIR/scripts/detect-env.sh" 2>/dev/null || {
  AGENT_HOME="${AGENT_HOME:-$HOME/.hermes}"
  AGENT_TYPE="${AGENT_TYPE:-hermes}"
  AGENT_NAME="${AGENT_NAME:-Agent}"
}
AGENT_HOME="${AGENT_HOME:-$HOME/.hermes}"

echo "============================================"
echo "  $AGENT_NAME Backup"
echo "  Source: $AGENT_HOME"
echo "  Repo:   $REPO_DIR"
echo "  Time:   $TIMESTAMP"
echo "============================================"

# ── Sanity Checks ───────────────────────────
if [ ! -d "$AGENT_HOME" ]; then
  echo "[ERROR] $AGENT_NAME home not found: $AGENT_HOME"
  exit 1
fi

if ! command -v git &>/dev/null; then
  echo "[ERROR] git not found. Please install git first."
  exit 1
fi

# ── 1. Skills ───────────────────────────────
echo ""
echo "[1/6] Backing up skills..."
if [ -d "$AGENT_HOME/skills" ]; then
  rm -rf "$REPO_DIR/skills"
  cp -r "$AGENT_HOME/skills" "$REPO_DIR/skills"
  # Remove curator/state internal files
  rm -rf "$REPO_DIR/skills/.curator_backups" 2>/dev/null || true
  rm -rf "$REPO_DIR/skills/.curator_state" 2>/dev/null || true
  rm -f "$REPO_DIR/skills/.usage.json" 2>/dev/null || true
  rm -f "$REPO_DIR/skills/.bundled_manifest" 2>/dev/null || true
  SKILL_COUNT=$(find "$REPO_DIR/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  echo "  ✓ $SKILL_COUNT skills backed up"
else
  echo "  ⚡ No skills directory found, skipping"
fi

# ── 2. Custom Scripts ───────────────────────
echo ""
echo "[2/6] Backing up custom scripts..."
if [ -d "$AGENT_HOME/scripts" ]; then
  rm -rf "$REPO_DIR/scripts"
  mkdir -p "$REPO_DIR/scripts"
  find "$AGENT_HOME/scripts" -maxdepth 1 -type f \( -name "*.py" -o -name "*.sh" \) \
    -exec cp {} "$REPO_DIR/scripts/" \; 2>/dev/null || true
  SCRIPT_COUNT=$(find "$REPO_DIR/scripts" -maxdepth 1 -type f | wc -l | tr -d ' ')
  echo "  ✓ $SCRIPT_COUNT scripts backed up"
else
  echo "  ⚡ No custom scripts found, skipping"
fi

# ── 3. Memories ─────────────────────────────
echo ""
echo "[3/6] Backing up memories..."
mkdir -p "$REPO_DIR/memories"
for f in MEMORY.md USER.md; do
  if [ -f "$AGENT_HOME/memories/$f" ]; then
    cp "$AGENT_HOME/memories/$f" "$REPO_DIR/memories/$f"
    echo "  ✓ $f"
  else
    echo "  ⚡ $f not found, skipping"
  fi
done

# ── 4. Persona ──────────────────────────────
echo ""
echo "[4/6] Backing up persona..."
mkdir -p "$REPO_DIR/prompts"
for f in SOUL.md PERSONALITY.md personality.md; do
  if [ -f "$AGENT_HOME/$f" ]; then
    cp "$AGENT_HOME/$f" "$REPO_DIR/prompts/$f"
    echo "  ✓ $f"
    break
  fi
done

# ── 5. Config (sanitized) ───────────────────
echo ""
echo "[5/6] Backing up config..."
mkdir -p "$REPO_DIR/config"
for f in config.yaml config.yml; do
  if [ -f "$AGENT_HOME/$f" ]; then
    cp "$AGENT_HOME/$f" "$REPO_DIR/config/$f"
    echo "  ✓ $f"
    break
  fi
done

# Check for embedded secrets in config
if grep -q 'api_key:\s*[^'\'']' "$REPO_DIR/config/config.yaml" 2>/dev/null; then
  echo "  ⚠ WARNING: config.yaml may contain embedded secrets!"
  echo "    Check api_key fields before committing."
fi

# ── 6. Cron reference (metadata only) ───────
echo ""
echo "[6/6] Backing up cron schedule (metadata only)..."
mkdir -p "$REPO_DIR/archive"
if [ -f "$AGENT_HOME/cron/jobs.json" ]; then
  python3 -c "
import json, sys
try:
    with open('$AGENT_HOME/cron/jobs.json') as f:
        data = json.load(f)
    jobs = data.get('jobs', []) if isinstance(data, dict) else data
    for j in jobs:
        name = j.get('name', j.get('id', '?'))
        sched = j.get('schedule', {})
        if isinstance(sched, dict):
            disp = sched.get('display', sched.get('expr', '?'))
        else:
            disp = j.get('schedule_display', '?')
        print(f'  - {name} ({disp})')
except Exception:
    print('  Could not parse cron jobs')
" > "$REPO_DIR/archive/cron-jobs-reference.txt" 2>/dev/null
  echo "  ✓ Cron schedule saved (no secrets)"
else
  echo "  ⚡ No cron jobs found, skipping"
fi

# ── 7. Git Commit & Push ────────────────────
echo ""
echo "[7] Committing and pushing to GitHub..."
cd "$REPO_DIR"

# Check for changes
HAS_CHANGES=false
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  HAS_CHANGES=true
fi
# Also check for untracked files
if [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
  HAS_CHANGES=true
fi

if [ "$HAS_CHANGES" = true ]; then
  git add -A 2>/dev/null || true
  git commit -m "Auto-backup $TIMESTAMP" 2>/dev/null || echo "  ℹ Nothing new to commit"
  echo "  ✓ Committed"
else
  echo "  ℹ No changes to commit"
fi

# Push
if git remote get-url origin &>/dev/null; then
  REMOTE_URL=$(git remote get-url origin)
  if echo "$REMOTE_URL" | grep -q "^git@"; then
    # SSH — attempt push
    git push origin main 2>&1 || {
      echo "  ⚠ Push failed. Check SSH key or network."
      echo "  Backup saved locally. Push later: cd $REPO_DIR && git push"
    }
    echo "  ✓ Pushed to origin/main"
  else
    # HTTPS — try token from .env
    if [ -f "$AGENT_HOME/.env" ]; then
      GH_TOKEN=$(grep "^GITHUB_TOKEN=*** "$AGENT_HOME/.env" | head -1 | cut -d= -f2- 2>/dev/null || echo "")
      if [ -n "$GH_TOKEN" ]; then
        PUSH_URL="https://$(echo "$REMOTE_URL" | sed 's|https://||' | sed "s|github.com|${GH_TOKEN}@github.com|")"
        git push "$PUSH_URL" main 2>&1 || {
          echo "  ⚠ Push failed (network?). Backup saved locally."
        }
      else
        git push origin main 2>&1 || echo "  ⚠ Push failed"
      fi
    else
      git push origin main 2>&1 || echo "  ⚠ Push failed"
    fi
  fi
else
  echo "  ⚡ No remote configured. To push later:"
  echo "    git remote add origin https://github.com/YOUR_USER/agent-backup.git"
  echo "    git push -u origin main"
fi

echo ""
echo "============================================"
echo "  Backup complete!"
echo "============================================"
