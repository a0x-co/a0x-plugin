#!/usr/bin/env bash
# A0X Plugin Setup for Claude Code
# Usage: curl -sL https://raw.githubusercontent.com/a0x-co/a0x-plugin/main/setup.sh | bash
#   or:  curl -sL https://raw.githubusercontent.com/a0x-co/a0x-plugin/main/setup.sh | bash -s -- --token <JWT>

set -euo pipefail

MCP_URL="https://mcp-agents.a0x.co/mcp"
SKILL_URL="https://raw.githubusercontent.com/a0x-co/a0x-plugin/main/skills/a0x-agents/SKILL.md"
SKILL_DIR="$HOME/.claude/skills/a0x-agents"

# Parse args
TOKEN=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --token) TOKEN="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo ""
echo "  A0X Plugin Setup for Claude Code"
echo "  ================================="
echo ""

# Step 1: Install skill
echo "[1/2] Installing skill (behavioral rules)..."
mkdir -p "$SKILL_DIR"
curl -sL "$SKILL_URL" -o "$SKILL_DIR/SKILL.md"
echo "  ✓ Skill installed at $SKILL_DIR/SKILL.md"

# Step 2: Add MCP server to .mcp.json
echo "[2/2] Configuring MCP server (tools)..."

# Build the MCP URL with optional token
if [ -n "$TOKEN" ]; then
  FULL_URL="${MCP_URL}?token=${TOKEN}"
else
  # Check env var
  if [ -n "${A0X_TOKEN:-}" ]; then
    FULL_URL="${MCP_URL}?token=${A0X_TOKEN}"
    echo "  Using token from \$A0X_TOKEN"
  else
    FULL_URL="$MCP_URL"
    echo "  No token provided — anonymous mode (3 search/day, 5 chat/day)"
    echo "  To upgrade: re-run with --token <JWT> after registering"
  fi
fi

# Find or create .mcp.json (prefer project root, fallback to home)
MCP_FILE=""
if [ -f ".mcp.json" ]; then
  MCP_FILE=".mcp.json"
elif [ -f "$HOME/.mcp.json" ]; then
  MCP_FILE="$HOME/.mcp.json"
else
  # Create in current directory if it's a git repo, otherwise in home
  if [ -d ".git" ]; then
    MCP_FILE=".mcp.json"
  else
    MCP_FILE="$HOME/.mcp.json"
  fi
fi

# Add a0x server to .mcp.json
if [ -f "$MCP_FILE" ]; then
  # File exists — check if a0x is already there
  if grep -q '"a0x"' "$MCP_FILE" 2>/dev/null; then
    # Update existing a0x entry
    # Use a temp file approach for portability
    python3 -c "
import json, sys
with open('$MCP_FILE') as f:
    cfg = json.load(f)
cfg.setdefault('mcpServers', {})['a0x'] = {'type': 'http', 'url': '$FULL_URL'}
with open('$MCP_FILE', 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
" 2>/dev/null || {
      echo "  ⚠ Could not update $MCP_FILE automatically."
      echo "  Add this manually to your .mcp.json:"
      echo "    \"a0x\": { \"type\": \"http\", \"url\": \"$FULL_URL\" }"
    }
    echo "  ✓ Updated a0x in $MCP_FILE"
  else
    # Add a0x to existing file
    python3 -c "
import json
with open('$MCP_FILE') as f:
    cfg = json.load(f)
cfg.setdefault('mcpServers', {})['a0x'] = {'type': 'http', 'url': '$FULL_URL'}
with open('$MCP_FILE', 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
" 2>/dev/null || {
      echo "  ⚠ Could not update $MCP_FILE automatically."
      echo "  Add this to your .mcp.json mcpServers:"
      echo "    \"a0x\": { \"type\": \"http\", \"url\": \"$FULL_URL\" }"
    }
    echo "  ✓ Added a0x to $MCP_FILE"
  fi
else
  # Create new .mcp.json
  cat > "$MCP_FILE" << MCPEOF
{
  "mcpServers": {
    "a0x": {
      "type": "http",
      "url": "$FULL_URL"
    }
  }
}
MCPEOF
  echo "  ✓ Created $MCP_FILE"
fi

echo ""
echo "  ✅ Setup complete!"
echo ""
echo "  Next steps:"
echo "  1. Restart Claude Code"
echo "  2. Type /a0x-agents to activate the skill"
echo "  3. Ask: \"what a0x tools do you have?\" to verify"
echo ""

if [ "$FULL_URL" = "$MCP_URL" ]; then
  echo "  ─── Want higher limits? Register with ERC-8004 ───"
  echo "  See: https://github.com/a0x-co/a0x-plugin#authentication-erc-8004"
  echo ""
fi
