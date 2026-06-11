#!/usr/bin/env bash
# ============================================
# setup.sh — One-click setup for agent-backup
# ============================================
# Run this on any machine with Hermes or OpenClaw:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/zhangyucheng0111/agent-backup/main/scripts/setup.sh)
#
# What it does:
#   1. Detects Hermes / OpenClaw installation
#   2. Prompts for GitHub username (creates token if needed)
#   3. Creates a private GitHub repo
#   4. Sets up SSH key for auth
#   5. Runs first backup
#   6. (Optional) Configures cron for auto-backup
# ============================================

set -euo pipefail

# ── Colors ──────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║        agent-backup — Setup Wizard       ║"
echo "║  One-command backup for AI agents         ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ── Step 1: Detect Agent ────────────────────
echo ""
echo -e "${YELLOW}[1/6] Detecting your AI agent...${NC}"

# Source detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-env.sh" 2>/dev/null || {
  # Fallback
  for dir in "$HOME/.hermes" "$HOME/.openclaw"; do
    if [ -d "$dir" ]; then
      AGENT_HOME="$dir"
      AGENT_TYPE="$(basename "$dir")"
      break
    fi
  done
}

if [ -z "${AGENT_HOME:-}" ]; then
  echo -e "${RED}✗ No agent installation found.${NC}"
  echo "  Looked in: ~/.hermes, ~/.openclaw"
  echo "  You can still set up the backup tool manually."
  echo "  Install Hermes first: curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash"
  exit 1
fi

echo -e "${GREEN}✓ Found: $AGENT_HOME${NC}"
echo "  Type: ${AGENT_TYPE:-unknown}"

# ── Step 2: GitHub Setup ────────────────────
echo ""
echo -e "${YELLOW}[2/6] GitHub authentication...${NC}"

# Check if git is configured
GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -z "$GIT_NAME" ]; then
  read -r -p "  Enter your GitHub username: " GH_USER
  read -r -p "  Enter your email: " GH_EMAIL
  git config --global user.name "$GH_USER"
  git config --global user.email "$GH_EMAIL"
else
  echo -e "${GREEN}✓ Git configured: $GIT_NAME <$GIT_EMAIL>${NC}"
  GH_USER="$GIT_NAME"
fi

# Check for GITHUB_TOKEN
GH_TOKEN=""
if [ -f "$AGENT_HOME/.env" ]; then
  GH_TOKEN=*** "^GITHUB_TOKEN=*** "$AGENT_HOME/.env" | head -1 | cut -d= -f2- 2>/dev/null || true)
fi

if [ -z "$GH_TOKEN" ]; then
  echo ""
  echo -e "${YELLOW}  You need a GitHub Personal Access Token with 'repo' scope.${NC}"
  echo "  1. Create one at: https://github.com/settings/tokens/new"
  echo "     - Note: agent-backup"
  echo "     - Scopes: repo (full control)"
  echo "     - Expiration: No expiration"
  echo ""
  read -r -p "  2. Paste your token here: " GH_TOKEN
  
  if [ -z "$GH_TOKEN" ]; then
    echo -e "${RED}✗ Token required. Aborting.${NC}"
    exit 1
  fi

  # Save to .env
  echo "" >> "$AGENT_HOME/.env"
  echo "# GitHub - for agent-backup" >> "$AGENT_HOME/.env"
  echo "GITHUB_TOKEN=*** >> "$AGENT_HOME/.env"
  echo -e "${GREEN}✓ Token saved to $AGENT_HOME/.env${NC}"
fi

# Verify token
echo ""
echo "  Verifying token..."
TOKEN_CHECK=$(curl -s -H "Authorization: token $GH_TOKEN" https://api.github.com/user 2>/dev/null)
GH_USERNAME=$(echo "$TOKEN_CHECK" | python3 -c "import sys,json; print(json.load(sys.stdin).get('login',''))" 2>/dev/null)
if [ -n "$GH_USERNAME" ]; then
  echo -e "${GREEN}✓ Authenticated as: $GH_USERNAME${NC}"
else
  echo -e "${RED}✗ Token invalid. Check your token and try again.${NC}"
  exit 1
fi

# ── Step 3: Create GitHub Repo ──────────────
echo ""
echo -e "${YELLOW}[3/6] Creating private GitHub repository...${NC}"

REPO_NAME="agent-backup"
CREATE_REPO=$(curl -s -X POST \
  -H "Authorization: token $GH_TOKEN" \
  https://api.github.com/user/repos \
  -d "{\"name\":\"$REPO_NAME\",\"private\":true,\"description\":\"Backup for my AI agent (Hermes/OpenClaw) - skills, memories, config, scripts\",\"auto_init\":false}")

REPO_ID=$(echo "$CREATE_REPO" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
if [ -n "$REPO_ID" ]; then
  echo -e "${GREEN}✓ Repo created: https://github.com/$GH_USERNAME/$REPO_NAME${NC}"
else
  # Maybe it already exists
  echo -e "${YELLOW}  Repo may already exist. Continuing...${NC}"
fi

# ── Step 4: SSH Key Setup ───────────────────
echo ""
echo -e "${YELLOW}[4/6] Setting up SSH key...${NC}"

SSH_KEY="$HOME/.ssh/id_ed25519_agent_backup"
if [ ! -f "$SSH_KEY" ]; then
  ssh-keygen -t ed25519 -C "agent-backup@$GH_USERNAME" -f "$SSH_KEY" -N "" -q
  echo -e "${GREEN}✓ SSH key generated${NC}"
else
  echo -e "${GREEN}✓ SSH key already exists${NC}"
fi

PUBKEY=*** "$SSH_KEY.pub")

# Try to add via API
ADD_KEY=$(curl -s -X POST \
  -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/keys \
  -d "{\"title\":\"agent-backup-$(hostname -s 2>/dev/null || echo 'unknown')\",\"key\":\"$PUBKEY\"}")

ADD_STATUS=$(echo "$ADD_KEY" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r.get('id','') or r.get('message',''))" 2>/dev/null)
if echo "$ADD_STATUS" | grep -qE '^[0-9]+$'; then
  echo -e "${GREEN}✓ SSH key added to GitHub${NC}"
else
  echo -e "${YELLOW}  SSH key may already exist on GitHub: $ADD_STATUS${NC}"
  echo "  If you need to add it manually:"
  echo "  1. Go to https://github.com/settings/keys"
  echo "  2. Click 'New SSH Key'"
  echo "  3. Paste this key:"
  echo "  $PUBKEY"
fi

# ── Step 5: Clone & First Backup ────────────
echo ""
echo -e "${YELLOW}[5/6] Cloning repository and running first backup...${NC}"

cd "$HOME"
if [ -d "$REPO_NAME" ]; then
  echo "  Directory $HOME/$REPO_NAME already exists, skipping clone"
  cd "$REPO_NAME"
  git remote set-url origin "git@github.com:$GH_USERNAME/$REPO_NAME.git" 2>/dev/null || true
else
  git clone "git@github.com:$GH_USERNAME/$REPO_NAME.git"
  cd "$REPO_NAME"
fi

# Copy scripts and templates from setup script location
if [ "$SCRIPT_DIR" != "$PWD/scripts" ]; then
  cp -r "$SCRIPT_DIR"/*.sh "$PWD/scripts/" 2>/dev/null || true
  cp -r "$(dirname "$SCRIPT_DIR")/template" "$PWD/" 2>/dev/null || true
  cp -r "$(dirname "$SCRIPT_DIR")/.gitignore" "$PWD/" 2>/dev/null || true
fi

# Configure SSH remote if needed
git remote set-url origin "git@github.com:$GH_USERNAME/$REPO_NAME.git" 2>/dev/null || true

# Run first backup
echo ""
echo "  Running first backup..."
bash scripts/backup.sh

echo ""
echo -e "${GREEN}✓ First backup complete!${NC}"

# ── Step 6: Cron Setup (Optional) ───────────
echo ""
echo -e "${YELLOW}[6/6] Automatic backups (optional)${NC}"
echo ""
read -r -p "  Set up automatic backups twice a week? [Y/n] " SETUP_CRON

if [[ ! "$SETUP_CRON" =~ ^[Nn]$ ]]; then
  CRON_SCHEDULE="0 9 * * 1,4"
  CRON_JOB="$CRON_SCHEDULE cd $HOME/$REPO_NAME && bash scripts/backup.sh >> $HOME/$REPO_NAME/backup.log 2>&1"
  
  # Check if already in crontab
  if crontab -l 2>/dev/null | grep -q "$REPO_NAME/scripts/backup.sh"; then
    echo -e "${GREEN}✓ Cron job already configured${NC}"
  else
    (crontab -l 2>/dev/null || true; echo "$CRON_JOB") | crontab -
    echo -e "${GREEN}✓ Cron job added: Mon & Thu at 9:00 AM${NC}"
  fi
fi

# ── Done ────────────────────────────────────
echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════╗"
echo "║           Setup Complete! 🎉             ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "  Repository: git@github.com:$GH_USERNAME/$REPO_NAME.git"
echo "  Web:        https://github.com/$GH_USERNAME/$REPO_NAME"
echo ""
echo "  To run backup manually:"
echo "    cd ~/$REPO_NAME && bash scripts/backup.sh"
echo ""
echo "  To restore on a new machine:"
echo "    git clone git@github.com:$GH_USERNAME/$REPO_NAME.git"
echo "    cd $REPO_NAME && bash scripts/restore.sh"
echo ""
echo "  To change cron schedule:"
echo "    crontab -e"
echo ""
