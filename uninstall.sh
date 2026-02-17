#!/usr/bin/env bash
# A0X Plugin Uninstall
#
# Usage:
#   bash uninstall.sh
#   curl -sL https://raw.githubusercontent.com/a0x-co/a0x-plugin/main/uninstall.sh | bash

set -euo pipefail

CONFIG_DIR="$HOME/.claude"
WALLET_FILE="$CONFIG_DIR/.a0x-wallet.json"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  A0X Plugin Uninstall"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Backup wallet
if [ -f "$WALLET_FILE" ]; then
  BACKUP="$HOME/.a0x-wallet-backup.json"
  cp "$WALLET_FILE" "$BACKUP"
  echo "  ✓ Wallet backed up to $BACKUP"
fi

# Remove skills
rm -rf "$CONFIG_DIR/skills/jessexbt" 2>/dev/null && echo "  ✓ Removed /jessexbt skill"
rm -rf "$CONFIG_DIR/skills/a0x-register" 2>/dev/null && echo "  ✓ Removed /a0x-register skill"
rm -rf "$CONFIG_DIR/skills/a0x-agents" 2>/dev/null && echo "  ✓ Removed /a0x-agents skill (legacy)"

# Remove hooks
rm -f "$CONFIG_DIR/hooks/a0x-session-start.sh" 2>/dev/null
rm -f "$CONFIG_DIR/hooks/brain-on-error.sh" 2>/dev/null
rm -f "$CONFIG_DIR/hooks/brain-teammate-context.sh" 2>/dev/null
rm -f "$CONFIG_DIR/hooks/brain-before-idle.sh" 2>/dev/null
rm -f "$CONFIG_DIR/hooks/jessexbt-on-crypto.sh" 2>/dev/null
rm -f "$CONFIG_DIR/hooks/a0x-setup.sh" 2>/dev/null
echo "  ✓ Removed hook scripts"

# Remove CLAUDE.md
rm -f "$CONFIG_DIR/CLAUDE.md" 2>/dev/null && echo "  ✓ Removed CLAUDE.md"

# Remove MCP config
rm -f "$CONFIG_DIR/.mcp.json" 2>/dev/null && echo "  ✓ Removed .mcp.json"

# Remove wallet
rm -f "$WALLET_FILE" 2>/dev/null && echo "  ✓ Removed .a0x-wallet.json"

# Clean settings.json (remove hooks and enabledMcpjsonServers)
SETTINGS_FILE="$CONFIG_DIR/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  python3 -c "
import json

with open('$SETTINGS_FILE') as f:
    cfg = json.load(f)

# Remove a0x hooks
for hook_type in ['SessionStart', 'PostToolUseFailure', 'SubagentStart', 'TeammateIdle', 'PostToolUse', 'UserPromptSubmit']:
    if hook_type in cfg.get('hooks', {}):
        entries = cfg['hooks'][hook_type]
        cfg['hooks'][hook_type] = [e for e in entries if not any('a0x' in h.get('command','') or 'brain' in h.get('command','') or 'jessexbt' in h.get('command','') for h in e.get('hooks',[]))]
        if not cfg['hooks'][hook_type]:
            del cfg['hooks'][hook_type]

if not cfg.get('hooks'):
    cfg.pop('hooks', None)

# Remove a0x MCP servers
if 'enabledMcpjsonServers' in cfg:
    cfg['enabledMcpjsonServers'] = [s for s in cfg['enabledMcpjsonServers'] if 'a0x' not in s]
    if not cfg['enabledMcpjsonServers']:
        cfg.pop('enabledMcpjsonServers', None)

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
" 2>/dev/null && echo "  ✓ Cleaned settings.json"
fi

echo ""
echo "  ✅ A0X plugin uninstalled."
echo ""
echo "  Your wallet was backed up to: $HOME/.a0x-wallet-backup.json"
echo "  Your \$AGENT_PK is still in your shell profile (~/.bashrc or ~/.zshrc)."
echo "  Remove it manually if you no longer need it."
echo ""
echo "  Restart Claude Code to apply changes."
echo ""
