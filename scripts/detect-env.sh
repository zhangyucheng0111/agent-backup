#!/usr/bin/env bash
# ============================================
# detect-env.sh — Auto-detect Hermes or OpenClaw
# ============================================
# Detects which AI agent is installed and sets
# AGENT_HOME, AGENT_TYPE, and AGENT_NAME.
#
# Usage:
#   source scripts/detect-env.sh    # loads variables
#   scripts/detect-env.sh --print   # prints detected path
# ============================================

detect_agent() {
  local CANDIDATES=(
    "$HOME/.hermes"
    "$HOME/.openclaw"
    "$HOME/.config/hermes"
    "$HOME/.config/openclaw"
    "$HERMES_HOME"
    "$OPENCLAW_HOME"
  )

  # Check env vars first
  if [ -n "$HERMES_HOME" ] && [ -d "$HERMES_HOME" ]; then
    AGENT_HOME="$HERMES_HOME"
    AGENT_TYPE="hermes"
    AGENT_NAME="Hermes Agent"
    return 0
  fi

  if [ -n "$OPENCLAW_HOME" ] && [ -d "$OPENCLAW_HOME" ]; then
    AGENT_HOME="$OPENCLAW_HOME"
    AGENT_TYPE="openclaw"
    AGENT_NAME="OpenClaw"
    return 0
  fi

  # Check common paths
  for path in "${CANDIDATES[@]}"; do
    if [ -n "$path" ] && [ -d "$path" ]; then
      # Determine type
      if echo "$path" | grep -qi "hermes"; then
        AGENT_TYPE="hermes"
        AGENT_NAME="Hermes Agent"
      elif echo "$path" | grep -qi "openclaw"; then
        AGENT_TYPE="openclaw"
        AGENT_NAME="OpenClaw"
      else
        AGENT_TYPE="unknown"
        AGENT_NAME="Unknown"
      fi
      AGENT_HOME="$path"
      return 0
    fi
  done

  return 1
}

# ── Export if sourced, print if executed ──
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  # Being sourced: export variables
  if detect_agent; then
    export AGENT_HOME AGENT_TYPE AGENT_NAME
  else
    echo "[detect-env] ⚠ No agent installation found." >&2
    echo "[detect-env]   Looked in: ~/.hermes, ~/.openclaw, \$HERMES_HOME, \$OPENCLAW_HOME" >&2
    return 1
  fi
else
  # Being executed: print result
  if detect_agent; then
    echo "AGENT_HOME=$AGENT_HOME"
    echo "AGENT_TYPE=$AGENT_TYPE"
    echo "AGENT_NAME=$AGENT_NAME"
  else
    echo "AGENT_HOME="
    echo "AGENT_TYPE="
    echo "AGENT_NAME="
    exit 1
  fi
fi
