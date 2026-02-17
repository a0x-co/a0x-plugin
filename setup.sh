#!/usr/bin/env bash
# A0X Plugin Setup for Claude Code
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/a0x-co/a0x-plugin/main/setup.sh | bash
#
# Tiers:
#   FREE       - Auto-registered, 50 requests/day (1.5k/month)
#   WALLET     - Your own wallet verified, 100 requests/day (3k/month)
#   VERIFIED   - ERC-8004 identity, 200 requests/day (6k/month)
#   PREMIUM    - x402 payment, unlimited

set -euo pipefail

MCP_URL="https://services-a0x-agents-mcp-dev-679925931457.us-west1.run.app"
CONFIG_DIR="$HOME/.claude"
WALLET_FILE="$CONFIG_DIR/.a0x-wallet.json"

# Detect if running locally (from the plugin directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [ -f "$SCRIPT_DIR/CLAUDE.md" ] && [ -d "$SCRIPT_DIR/skills" ] && [ -d "$SCRIPT_DIR/hooks" ]; then
  LOCAL_MODE=true
else
  LOCAL_MODE=false
fi


echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  🤖 A0X Plugin Setup for Claude Code"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Step 1: Install skills, CLAUDE.md, and hook scripts
echo "[1/5] Installing skills and global context..."

# Helper: install a file from local or remote
install_file() {
  local LOCAL_PATH="$1"
  local REMOTE_URL="$2"
  local DEST="$3"

  if [ "$LOCAL_MODE" = true ] && [ -f "$LOCAL_PATH" ]; then
    cp "$LOCAL_PATH" "$DEST"
  else
    curl -sL "$REMOTE_URL" -o "$DEST" 2>/dev/null || {
      echo "  ⚠ Could not download $(basename "$DEST"). Continuing anyway..."
      return 1
    }
  fi
}

GITHUB_BASE="https://raw.githubusercontent.com/a0x-co/a0x-plugin/main"

# jessexbt skill (invoked with /jessexbt)
JESSEXBT_SKILL_DIR="$HOME/.claude/skills/jessexbt"
mkdir -p "$JESSEXBT_SKILL_DIR"
install_file "$SCRIPT_DIR/skills/jessexbt/SKILL.md" "$GITHUB_BASE/skills/jessexbt/SKILL.md" "$JESSEXBT_SKILL_DIR/SKILL.md"
echo "  ✓ jessexbt skill installed"

# a0x-register skill (invoked with /a0x-register)
REGISTER_SKILL_DIR="$HOME/.claude/skills/a0x-register"
mkdir -p "$REGISTER_SKILL_DIR"
install_file "$SCRIPT_DIR/skills/a0x-register/SKILL.md" "$GITHUB_BASE/skills/a0x-register/SKILL.md" "$REGISTER_SKILL_DIR/SKILL.md"
echo "  ✓ a0x-register skill installed"

# Global CLAUDE.md (brain + jessexbt context)
CLAUDE_MD_FILE="$CONFIG_DIR/CLAUDE.md"
install_file "$SCRIPT_DIR/CLAUDE.md" "$GITHUB_BASE/CLAUDE.md" "$CLAUDE_MD_FILE"
echo "  ✓ Global context installed"

# Step 2: Create agent wallet (if Foundry available and no wallet yet)
echo "[2/5] Setting up agent wallet..."

AGENT_ADDRESS=""
SHELL_PROFILE=""

# Detect shell profile
if [ -f "$HOME/.zshrc" ]; then
  SHELL_PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_PROFILE="$HOME/.bashrc"
fi

# Check if AGENT_PK already set
if [ -n "${AGENT_PK:-}" ]; then
  echo "  ✓ AGENT_PK already configured"
  # Derive address from existing key
  if command -v cast &>/dev/null; then
    AGENT_ADDRESS=$(cast wallet address --private-key "$AGENT_PK" 2>/dev/null || echo "")
    if [ -n "$AGENT_ADDRESS" ]; then
      echo "  ✓ Agent wallet: $AGENT_ADDRESS"
    fi
  fi
elif command -v cast &>/dev/null; then
  echo "  Foundry detected. Creating dedicated agent wallet..."

  # Generate new wallet
  WALLET_OUTPUT=$(cast wallet new 2>/dev/null)
  NEW_ADDRESS=$(echo "$WALLET_OUTPUT" | grep -i "address" | awk '{print $NF}')
  NEW_PK=$(echo "$WALLET_OUTPUT" | grep -i "private" | awk '{print $NF}')

  if [ -n "$NEW_PK" ] && [ -n "$NEW_ADDRESS" ]; then
    AGENT_ADDRESS="$NEW_ADDRESS"

    # Save PK to shell profile (BEFORE interactive guard so non-interactive shells load it)
    if [ -n "$SHELL_PROFILE" ]; then
      # Remove old AGENT_PK if exists
      grep -v "^export AGENT_PK=" "$SHELL_PROFILE" > "$SHELL_PROFILE.tmp" 2>/dev/null && \
        mv "$SHELL_PROFILE.tmp" "$SHELL_PROFILE"

      # Find the interactive guard (case $- in) and insert BEFORE it
      GUARD_LINE=$(grep -n 'case \$- in' "$SHELL_PROFILE" 2>/dev/null | head -1 | cut -d: -f1)
      if [ -n "$GUARD_LINE" ]; then
        # Insert before the comment line above the guard (or the guard itself)
        INSERT_LINE=$((GUARD_LINE - 1))
        # Check if previous line is a comment about interactivity
        PREV=$(sed -n "${INSERT_LINE}p" "$SHELL_PROFILE" 2>/dev/null)
        if echo "$PREV" | grep -qi "interactiv"; then
          INSERT_LINE=$((INSERT_LINE - 1))
        fi
        # Insert after INSERT_LINE (0 = top of file)
        if [ "$INSERT_LINE" -le 0 ]; then
          INSERT_LINE=1
        fi
        sed -i "${INSERT_LINE}a\\
export AGENT_PK=$NEW_PK" "$SHELL_PROFILE"
      else
        # No guard found, append normally
        echo "export AGENT_PK=$NEW_PK" >> "$SHELL_PROFILE"
      fi
      export AGENT_PK="$NEW_PK"
      echo "  ✓ Agent wallet created: $AGENT_ADDRESS"
      echo "  ✓ Private key saved to $SHELL_PROFILE as \$AGENT_PK"
      echo "  ⚠ This is a dedicated agent wallet. Do NOT store significant funds."
    else
      echo "  ✓ Agent wallet created: $AGENT_ADDRESS"
      echo "  ⚠ Could not detect shell profile. Add manually:"
      echo "    export AGENT_PK=$NEW_PK"
    fi
  else
    echo "  ⚠ Could not generate wallet. Continuing without agent wallet."
  fi
else
  echo "  Foundry not installed. Skipping agent wallet."
  echo "  Install later: curl -L https://foundry.paradigm.xyz | bash && foundryup"
  echo "  Then re-run this setup to create your agent wallet."
fi

# Step 3: Register A0X account
echo "[3/5] Setting up A0X account..."

API_KEY=""
WALLET_ADDRESS=""

if [ -f "$WALLET_FILE" ]; then
  # Already registered
  API_KEY=$(jq -r '.apiKey // empty' "$WALLET_FILE" 2>/dev/null)
  WALLET_ADDRESS=$(jq -r '.walletAddress // empty' "$WALLET_FILE" 2>/dev/null)
  TIER=$(jq -r '.tier // "free"' "$WALLET_FILE" 2>/dev/null)

  if [ -n "$API_KEY" ] && [ "$API_KEY" != "null" ]; then
    echo "  ✓ Found existing account"
    echo "  ✓ Tier: $TIER"

    # Check status
    STATUS=$(curl -s "$MCP_URL/$API_KEY/status" 2>/dev/null)
    if [ -n "$STATUS" ]; then
      REMAINING=$(echo "$STATUS" | jq -r '.rateLimit.remaining // "unknown"')
      echo "  ✓ Remaining requests today: $REMAINING"
    fi
  fi
fi

# Register if not found
if [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
  echo "  Registering new account..."

  BODY="{\"projectPath\": \"$(pwd)\"}"

  RESPONSE=$(curl -s -X POST "$MCP_URL/auto-register" \
    -H "Content-Type: application/json" \
    -d "$BODY" 2>/dev/null)

  SUCCESS=$(echo "$RESPONSE" | jq -r '.success // false')

  if [ "$SUCCESS" = "true" ]; then
    API_KEY=$(echo "$RESPONSE" | jq -r '.data.apiKey')
    WALLET_ADDRESS=$(echo "$RESPONSE" | jq -r '.data.walletAddress')
    TIER=$(echo "$RESPONSE" | jq -r '.data.tier')
    DAILY=$(echo "$RESPONSE" | jq -r '.data.rateLimit.daily')

    # Save wallet info — use real agent address as walletAddress if available
    mkdir -p "$CONFIG_DIR"
    if [ -n "$AGENT_ADDRESS" ]; then
      echo "$RESPONSE" | jq --arg addr "$AGENT_ADDRESS" '.data | .walletAddress = $addr' > "$WALLET_FILE"
    else
      echo "$RESPONSE" | jq '.data' > "$WALLET_FILE"
    fi

    echo "  ✓ Account created!"
    echo "  ✓ Tier: $TIER ($DAILY requests/day)"
  else
    echo "  ⚠ Registration failed. Using anonymous mode."
    echo "  Error: $(echo "$RESPONSE" | jq -r '.error // "unknown"')"
  fi
fi

# Step 4: Configure MCP
echo "[4/5] Configuring MCP server..."

MCP_FILE="$CONFIG_DIR/.mcp.json"

# Build URLs
if [ -n "$API_KEY" ] && [ "$API_KEY" != "null" ]; then
  BRAIN_URL="$MCP_URL/$API_KEY/brain"
  AGENTS_URL="$MCP_URL/$API_KEY/agents"
else
  # Anonymous mode
  BRAIN_URL="$MCP_URL/brain"
  AGENTS_URL="$MCP_URL/agents"
fi

# Update or create .mcp.json
if [ -f "$MCP_FILE" ]; then
  # Update existing
  python3 -c "
import json
with open('$MCP_FILE') as f:
    cfg = json.load(f)
cfg.setdefault('mcpServers', {})
cfg['mcpServers']['a0x-brain'] = {'type': 'http', 'url': '$BRAIN_URL'}
cfg['mcpServers']['a0x-agents'] = {'type': 'http', 'url': '$AGENTS_URL'}
with open('$MCP_FILE', 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
" 2>/dev/null || {
    echo "  ⚠ Could not update $MCP_FILE. Add manually:"
    echo "    \"a0x-brain\": {\"type\": \"http\", \"url\": \"$BRAIN_URL\"}"
    echo "    \"a0x-agents\": {\"type\": \"http\", \"url\": \"$AGENTS_URL\"}"
  }
  echo "  ✓ Updated $MCP_FILE"
else
  # Create new
  cat > "$MCP_FILE" <<EOF
{
  "mcpServers": {
    "a0x-brain": {
      "type": "http",
      "url": "$BRAIN_URL"
    },
    "a0x-agents": {
      "type": "http",
      "url": "$AGENTS_URL"
    }
  }
}
EOF
  echo "  ✓ Created $MCP_FILE"
fi

# Step 5: Install hook scripts and configure settings.json
echo "[5/5] Installing hooks (brain auto-search, session start)..."

HOOKS_DIR="$CONFIG_DIR/hooks"
HOOKS_BASE_URL="https://raw.githubusercontent.com/a0x-co/a0x-plugin/main/hooks"
mkdir -p "$HOOKS_DIR"

# Install hook scripts
for HOOK_FILE in a0x-session-start.sh brain-on-error.sh brain-teammate-context.sh brain-before-idle.sh; do
  install_file "$SCRIPT_DIR/hooks/$HOOK_FILE" "$GITHUB_BASE/hooks/$HOOK_FILE" "$HOOKS_DIR/$HOOK_FILE"
  chmod +x "$HOOKS_DIR/$HOOK_FILE" 2>/dev/null
done
echo "  ✓ Hook scripts installed at $HOOKS_DIR/"

# Configure hooks in settings.json
# Strategy: brain hooks are automatic, jessexbt is intentional (via /jessexbt skill)
SETTINGS_FILE="$CONFIG_DIR/settings.json"

python3 -c "
import json, os

settings_path = '$SETTINGS_FILE'

# Load existing or create new
if os.path.exists(settings_path):
    with open(settings_path) as f:
        cfg = json.load(f)
else:
    cfg = {}

# Ensure hooks section exists
cfg.setdefault('hooks', {})

# SessionStart: auto-register on first run
cfg['hooks']['SessionStart'] = [{
    'matcher': 'startup',
    'hooks': [{'type': 'command', 'command': '\$HOME/.claude/hooks/a0x-session-start.sh'}]
}]

# PostToolUseFailure: brain auto-search on errors (brain = automatic)
cfg['hooks']['PostToolUseFailure'] = [{
    'matcher': 'Bash',
    'hooks': [{'type': 'command', 'command': '\$HOME/.claude/hooks/brain-on-error.sh'}]
}]

# SubagentStart: inject brain context for subagents
cfg['hooks']['SubagentStart'] = [{
    'hooks': [{'type': 'command', 'command': '\$HOME/.claude/hooks/brain-teammate-context.sh'}]
}]

# TeammateIdle: brain propose before idle
cfg['hooks']['TeammateIdle'] = [{
    'hooks': [{'type': 'command', 'command': '\$HOME/.claude/hooks/brain-before-idle.sh'}]
}]

# NOTE: No PostToolUse or UserPromptSubmit hooks for jessexbt.
# jessexbt is intentional - invoked via /jessexbt skill or CLAUDE.md context.

# Enable MCP servers
cfg.setdefault('enabledMcpjsonServers', [])
for server in ['a0x-brain', 'a0x-agents']:
    if server not in cfg['enabledMcpjsonServers']:
        cfg['enabledMcpjsonServers'].append(server)

with open(settings_path, 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
" 2>/dev/null || {
  echo "  ⚠ Could not update $SETTINGS_FILE. Configure hooks manually."
}
echo "  ✓ Hooks configured in $SETTINGS_FILE"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ Setup complete!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Your account:"
echo "    Tier: ${TIER:-free} (${DAILY:-50} requests/day)"
if [ -n "$AGENT_ADDRESS" ]; then
echo "    Agent wallet: $AGENT_ADDRESS"
fi
echo ""
echo "  Tools:"
echo "    Brain   - mcp__a0x-brain__knowledge_search / propose / vote"
echo "    jessexbt - mcp__a0x-agents__jessexbt_chat"
echo ""
echo "  Skills:"
echo "    /jessexbt      - Base ecosystem mentor (grants, architecture)"
echo "    /a0x-register  - Upgrade tier (100 or 200 req/day)"
echo ""
echo "  Next steps:"
echo "    1. Restart Claude Code (or run: source ${SHELL_PROFILE:-~/.bashrc})"
echo "    2. Open Claude Code and try: /jessexbt"
if [ -n "$AGENT_ADDRESS" ]; then
echo "    3. Upgrade tier: /a0x-register (your wallet is ready)"
else
echo "    3. Install Foundry + re-run setup for agent wallet"
fi
echo ""
