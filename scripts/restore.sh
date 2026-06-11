#!/usr/bin/env bash
# ============================================
# restore.sh — Universal restore for Hermes & OpenClaw
# ============================================
# Restores: skills, memories, config, scripts, persona
# Does NOT restore: .env, auth.json, session data
#
# Usage:
#   ./scripts/restore.sh
#   AGENT_HOME=/custom/path ./scripts/restore.sh
#
# WARNING: Overwrites files in AGENT_HOME.
# Originals backed up to ~/agent-restore-backup-<timestamp>/
# ============================================

set -euo pipefail

# ── Config ──────────────────────────────────
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Load agent detection
source "$REPO_DIR/scripts/detect-env.sh" 2>/dev/null || {
  AGENT_HOME="${AGENT_HOME:-$HOME/.hermes}"
  AGENT_TYPE="${AGENT_TYPE:-hermes}"
  AGENT_NAME="${AGENT_NAME:-Agent}"
}
AGENT_HOME="${AGENT_HOME:-$HOME/.hermes}"

BACKUP_DIR="$HOME/agent-restore-backup-$(date '+%Y%m%d_%H%M%S')"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

echo "============================================"
echo "  $AGENT_NAME Restore"
echo "  Source: $REPO_DIR"
echo "  Target: $AGENT_HOME"
echo "  Backup: $BACKUP_DIR"
echo "  Time:   $TIMESTAMP"
echo "============================================"

# ── Sanity Checks ───────────────────────────
if [ ! -d "$REPO_DIR" ]; then
  echo "[ERROR] Repo directory not found: $REPO_DIR"
  echo "  Run this script from the agent-backup repo."
  exit 1
fi

if [ ! -d "$AGENT_HOME" ]; then
  echo "[INFO] Target $AGENT_HOME does not exist. Creating..."
  mkdir -p "$AGENT_HOME"
fi

# ── Confirm ─────────────────────────────────
echo ""
echo "WARNING: This will OVERWRITE files in $AGENT_HOME"
echo "  Current files will be backed up to: $BACKUP_DIR"
echo ""
read -r -p "Continue? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Restore cancelled."
  exit 0
fi

# ── Backup Current Files ────────────────────
echo ""
echo "[1/7] Backing up current $AGENT_NAME files..."
mkdir -p "$BACKUP_DIR"
for dir in skills scripts memories; do
  if [ -d "$AGENT_HOME/$dir" ]; then
    cp -r "$AGENT_HOME/$dir" "$BACKUP_DIR/$dir" 2>/dev/null || true
    echo "  ✓ $dir backed up"
  fi
done
for f in config.yaml config.yml SOUL.md PERSONALITY.md personality.md; do
  if [ -f "$AGENT_HOME/$f" ]; then
    cp "$AGENT_HOME/$f" "$BACKUP_DIR/$f" 2>/dev/null || true
    echo "  ✓ $f backed up"
  fi
done
echo "  Backup saved to: $BACKUP_DIR"

# ── 2. Restore Skills ───────────────────────
echo ""
echo "[2/7] Restoring skills..."
if [ -d "$REPO_DIR/skills" ]; then
  rm -rf "$AGENT_HOME/skills" 2>/dev/null || true
  cp -r "$REPO_DIR/skills" "$AGENT_HOME/skills"
  SKILL_COUNT=$(find "$AGENT_HOME/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  echo "  ✓ $SKILL_COUNT skills restored"
else
  echo "  ⚡ No skills in backup, skipping"
fi

# ── 3. Restore Scripts ──────────────────────
echo ""
echo "[3/7] Restoring custom scripts..."
if [ -d "$REPO_DIR/scripts" ]; then
  # Remove backup/restore scripts used by this tool (they belong in repo, not agent)
  rm -rf "$AGENT_HOME/scripts" 2>/dev/null || true
  cp -r "$REPO_DIR/scripts" "$AGENT_HOME/scripts"
  # Remove tool scripts that aren't agent scripts
  rm -f "$AGENT_HOME/scripts/backup.sh" "$AGENT_HOME/scripts/restore.sh" 2>/dev/null || true
  rm -f "$AGENT_HOME/scripts/setup.sh" "$AGENT_HOME/scripts/detect-env.sh" 2>/dev/null || true
  SCRIPT_COUNT=$(find "$AGENT_HOME/scripts" -maxdepth 1 -type f | wc -l | tr -d ' ')
  echo "  ✓ $SCRIPT_COUNT scripts restored"
else
  echo "  ⚡ No scripts in backup, skipping"
fi

# ── 4. Restore Memories ─────────────────────
echo ""
echo "[4/7] Restoring memories..."
mkdir -p "$AGENT_HOME/memories"
for f in MEMORY.md USER.md; do
  if [ -f "$REPO_DIR/memories/$f" ]; then
    cp "$REPO_DIR/memories/$f" "$AGENT_HOME/memories/$f"
    echo "  ✓ $f"
  fi
done

# ── 5. Restore Persona ──────────────────────
echo ""
echo "[5/7] Restoring persona..."
for f in SOUL.md PERSONALITY.md personality.md; do
  if [ -f "$REPO_DIR/prompts/$f" ]; then
    cp "$REPO_DIR/prompts/$f" "$AGENT_HOME/$f"
    echo "  ✓ $f"
    break
  fi
done

# ── 6. Restore Config ───────────────────────
echo ""
echo "[6/7] Restoring config..."
for f in config.yaml config.yml; do
  if [ -f "$REPO_DIR/config/$f" ]; then
    cp "$REPO_DIR/config/$f" "$AGENT_HOME/$f"
    echo "  ✓ $f"
    break
  fi
done

echo ""
echo "  ⚡ Secrets NOT restored. You need to re-create:"
echo "     - $AGENT_HOME/.env (API keys)"
echo "     - $AGENT_HOME/auth.json (OAuth tokens)"
echo "     See template/.env.example for reference"

# ── 7. Post-Restore Instructions ────────────
echo ""
echo "[7/7] Summary"
echo "============================================"
echo "  Restore complete!"
echo "============================================"
echo ""
echo "NEXT STEPS:"
echo ""
echo "  1. Re-create your API keys:"
echo "     cp $REPO_DIR/template/.env.example $AGENT_HOME/.env"
echo "     # Edit $AGENT_HOME/.env with your real keys"
echo ""
echo "  2. Test your agent:"
if [ "$AGENT_TYPE" = "hermes" ]; then
  echo "     hermes doctor"
  echo "     hermes"
elif [ "$AGENT_TYPE" = "openclaw" ]; then
  echo "     openclaw --version"
else
  echo "     [Run your agent's CLI to verify]"
fi
echo ""
echo "  3. Old files backed up to: $BACKUP_DIR"
echo "     rm -rf $BACKUP_DIR  (after verification)"
echo ""
