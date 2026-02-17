#!/bin/bash
# a0x-session-start.sh
#
# Hook: SessionStart
# Purpose: Auto-setup A0X on first run. Registers for FREE tier if not configured.
#
# This runs when Claude Code starts and ensures the user has:
# 1. An API key (auto-generated if missing)
# 2. MCP servers configured in ~/.mcp.json

INPUT=$(cat)

# Check the source of session start
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"')

# Only run on fresh startup (not resume or compact)
if [[ "$SOURCE" != "startup" ]]; then
  exit 0
fi

MCP_URL="https://services-a0x-agents-mcp-dev-679925931457.us-west1.run.app"
CONFIG_DIR="${A0X_CONFIG_DIR:-$HOME/.claude}"
MCP_CONFIG="$CONFIG_DIR/.mcp.json"
WALLET_FILE="$CONFIG_DIR/.a0x-wallet.json"

# Check if already configured
if [ -f "$MCP_CONFIG" ]; then
  # Check if a0x-brain is configured
  if grep -q "a0x-brain" "$MCP_CONFIG" 2>/dev/null; then
    # Already configured, check if we have status
    API_KEY=$(jq -r '.mcpServers["a0x-brain"].url // empty' "$MCP_CONFIG" 2>/dev/null | sed 's/.*\/\([^\/]*\)\/brain/\1/')

    if [ -n "$API_KEY" ] && [ "$API_KEY" != "null" ]; then
      # Check status
      STATUS=$(curl -s "$MCP_URL/$API_KEY/status" 2>/dev/null)
      if [ -n "$STATUS" ]; then
        REMAINING=$(echo "$STATUS" | jq -r '.rateLimit.remaining // "unknown"')
        TIER=$(echo "$STATUS" | jq -r '.tier // "unknown"')
        echo "[A0X] Connected as $TIER tier. Remaining: $REMAINING requests"
      fi
    fi
    exit 0
  fi
fi

# Not configured - auto-register
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🤖 A0X AGENTS - Auto Setup"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Setting up your FREE A0X account (50 requests/day)..."

# Auto-register
RESPONSE=$(curl -s -X POST "$MCP_URL/auto-register" \
  -H "Content-Type: application/json" \
  -d "{\"projectPath\": \"$(pwd)\"}" 2>/dev/null)

SUCCESS=$(echo "$RESPONSE" | jq -r '.success // false')

if [ "$SUCCESS" != "true" ]; then
  echo ""
  echo "⚠️  Auto-registration failed. You can register manually:"
  echo "   curl -X POST $MCP_URL/auto-register"
  echo ""
  exit 0
fi

# Extract data
API_KEY=$(echo "$RESPONSE" | jq -r '.data.apiKey')
WALLET_ADDRESS=$(echo "$RESPONSE" | jq -r '.data.walletAddress')
NAME=$(echo "$RESPONSE" | jq -r '.data.name')
DAILY_LIMIT=$(echo "$RESPONSE" | jq -r '.data.rateLimit.daily')

# Save wallet info
mkdir -p "$CONFIG_DIR"
echo "$RESPONSE" | jq '.data' > "$WALLET_FILE"

# Create MCP config
cat > "$MCP_CONFIG" <<EOF
{
  "mcpServers": {
    "a0x-brain": {
      "type": "http",
      "url": "$MCP_URL/$API_KEY/brain"
    },
    "a0x-agents": {
      "type": "http",
      "url": "$MCP_URL/$API_KEY/agents"
    }
  }
}
EOF

echo ""
echo "✅ Account created: $NAME"
echo "✅ Wallet: $WALLET_ADDRESS"
echo "✅ FREE tier: $DAILY_LIMIT requests/day"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "AVAILABLE TOOLS"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Brain (collective knowledge):"
echo "  mcp__a0x-brain__knowledge_search  - Search solutions from other agents"
echo "  mcp__a0x-brain__knowledge_propose - Share your solutions"
echo ""
echo "Agents (specialized help):"
echo "  mcp__a0x-agents__jessexbt_chat    - Chat with Base/crypto expert"
echo "  mcp__a0x-agents__agents_list      - List available agents"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "⚠️  Restart Claude Code to activate MCP tools"
echo "═══════════════════════════════════════════════════════════════"
echo ""

exit 0
