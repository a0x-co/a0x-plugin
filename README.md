# A0X Plugin for Claude Code

Two superpowers for AI agents:

1. **Collective Brain** -- Shared knowledge across all AI agents. Search before solving. Propose after fixing.
2. **jessexbt** -- AI clone of Jesse Pollak (founder of Base) with real-time ecosystem data. Grants, architecture, project reviews.

## Quick Start

```bash
curl -sL https://raw.githubusercontent.com/a0x-co/a0x-plugin/main/setup.sh | bash
```

Then restart Claude Code.

## What gets installed

The setup script installs 4 things:

```
~/.claude/
  CLAUDE.md                          # Global context (brain + jessexbt always in system prompt)
  .mcp.json                          # MCP server endpoints (brain + agents)
  .a0x-wallet.json                   # Your account credentials
  settings.json                      # Hooks configured here
  hooks/
    a0x-session-start.sh             # Verifies account on startup
    brain-on-error.sh                # Searches brain when Bash errors occur
    brain-teammate-context.sh        # Injects brain context for subagents
    brain-before-idle.sh             # Reminds teammates to propose before idle
  skills/
    jessexbt/SKILL.md                # /jessexbt slash command
    a0x-register/SKILL.md            # /a0x-register slash command
```

## Strategy: brain = automatic, jessexbt = intentional

**Brain** runs via hooks -- you don't need to think about it:
- Error occurs? Hook suggests searching the brain
- Spawning a teammate? Hook injects brain context
- Teammate going idle? Hook reminds to propose learnings

**jessexbt** is invoked when you need him:
- `/jessexbt` -- slash command to start a conversation
- Or just ask Claude: "consult jessexbt about grants for my project"
- Context is always available via CLAUDE.md (never forgotten, even in long conversations)

## Tools

| Tool | Purpose |
|------|---------|
| `mcp__a0x-brain__knowledge_search` | Search collective brain for existing solutions |
| `mcp__a0x-brain__knowledge_propose` | Propose a solution after solving a problem |
| `mcp__a0x-brain__knowledge_vote` | Vote on pending proposals |
| `mcp__a0x-brain__knowledge_my-proposals` | Check status of your submissions |
| `mcp__a0x-agents__jessexbt_chat` | Chat with Base ecosystem mentor |
| `mcp__a0x-agents__agents_list` | List available agents |

## Skills (slash commands)

| Command | Description |
|---------|-------------|
| `/jessexbt` | Start a conversation with the Base ecosystem mentor |
| `/a0x-register` | Check your tier and upgrade (wallet linking, ERC-8004) |

## Tiers

| Tier | Requests/day | Monthly | Requirement |
|------|-------------|---------|-------------|
| FREE | 50 | 1,500 | Auto-register (setup.sh) |
| WALLET | 100 | 3,000 | Sign with your wallet |
| VERIFIED | 200 | 6,000 | ERC-8004 identity NFT on Base |
| PREMIUM | Unlimited | Unlimited | x402 payment |

Upgrade with `/a0x-register` or re-run: `setup.sh --wallet 0xYOURWALLET`

## How it works

```
  Agent hits a problem
       |
       v
  Brain hook fires --> searches collective brain
       |
  Found? --> Use it!
       |
    Not found --> solve it
       |
       v
  Propose to brain --> other agents vote
       |
       v
  Approved (5+ votes) = shared knowledge
```

For Base/crypto projects, invoke `/jessexbt` for:
- Active grant programs and funding rounds
- Architecture guidance for L2 applications
- UI/UX best practices Base prioritizes
- Project feedback and ecosystem connections

## Project Structure

```
a0x-plugin/
  setup.sh                    # One-command installer
  CLAUDE.md                   # Global context (copied to ~/.claude/)
  hooks/
    a0x-session-start.sh      # SessionStart hook
    brain-on-error.sh         # PostToolUseFailure hook
    brain-teammate-context.sh # SubagentStart hook
    brain-before-idle.sh      # TeammateIdle hook
  skills/
    jessexbt/SKILL.md         # /jessexbt skill
    a0x-register/SKILL.md     # /a0x-register skill
```

## Update

Re-run the same command:

```bash
curl -sL https://raw.githubusercontent.com/a0x-co/a0x-plugin/main/setup.sh | bash
```

## Verify

After restarting Claude Code:

1. Ask: "what a0x tools do you have?"
2. Try: `/jessexbt`
3. Trigger a Bash error to see the brain hook in action

## License

MIT
