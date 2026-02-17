#!/bin/bash
# brain-teammate-context.sh
#
# Hook: SubagentStart
# Purpose: Inject brain protocol into every teammate/agent spawned.
# Ensures all agents know to use the collective brain.
#
# Input (stdin): JSON from Claude Code hook system
# Output (stdout): Context to inject into the subagent

INPUT=$(cat)

# Extract agent type
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "unknown"')
SUBAGENT_ID=$(echo "$INPUT" | jq -r '.subagent_id // "unknown"')

# Inject brain protocol context - this becomes part of the subagent's context
cat <<'EOF'
═══════════════════════════════════════════════════════════════
COLLECTIVE BRAIN PROTOCOL (A0X)
═══════════════════════════════════════════════════════════════

You have access to a COLLECTIVE BRAIN shared by all AI agents.
Use it to avoid repeating mistakes and learn from others.

┌─────────────────────────────────────────────────────────────┐
│ BEFORE DEBUGGING OR ARCHITECTURE DECISIONS                  │
├─────────────────────────────────────────────────────────────┤
│ Call: mcp__a0x-brain__knowledge_search                      │
│                                                              │
│ Parameters:                                                  │
│   query: "describe the error or situation"                  │
│   memory_type: "error" | "pattern" | "success"              │
│   language: "typescript" | "solidity" | "python" etc.       │
│   framework: "foundry" | "nextjs" | "wagmi" etc.            │
│                                                              │
│ Example:                                                     │
│   mcp__a0x-brain__knowledge_search({                        │
│     query: "TypeError Cannot read property of undefined",   │
│     memory_type: "error",                                   │
│     language: "typescript"                                  │
│   })                                                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ AFTER SOLVING SOMETHING NON-OBVIOUS                         │
├─────────────────────────────────────────────────────────────┤
│ Call: mcp__a0x-brain__knowledge_propose                     │
│                                                              │
│ Parameters (all required):                                   │
│   memory_type: "error" | "pattern" | "success" | "insight"  │
│   situation: "specific context where this applies"          │
│   action: "what you did to solve/achieve"                   │
│   outcome: "the result"                                     │
│   learnings: ["key takeaway 1", "key takeaway 2"]           │
│   tags: ["relevant", "searchable", "tags"]                  │
│                                                              │
│ Example:                                                     │
│   mcp__a0x-brain__knowledge_propose({                       │
│     memory_type: "error",                                   │
│     situation: "Forge test fails with 'revert' on Base L2", │
│     action: "Added 1.2x gas multiplier for L2 estimation",  │
│     outcome: "Tests pass consistently on Base",             │
│     learnings: ["Base L2 gas estimation is 20% lower"],     │
│     tags: ["foundry", "base", "gas", "testing"],            │
│     framework: "foundry",                                   │
│     error_type: "GasEstimationError"                        │
│   })                                                         │
└─────────────────────────────────────────────────────────────┘

TRIGGERS FOR BRAIN SEARCH:
  ✗ Compilation error
  ✗ Runtime error / crash
  ✗ Test failure
  ✗ Build failure
  ✗ "Cannot find" / "Not found" errors
  ✗ Network / connection errors
  ✗ Gas / transaction errors (crypto)
  ✗ Architecture decision (which library, which pattern)

TRIGGERS FOR BRAIN PROPOSE:
  ✓ Fixed something that took >2 attempts
  ✓ Found a non-obvious workaround
  ✓ Discovered a pattern that should be reused
  ✓ Learned something future agents should know

┌─────────────────────────────────────────────────────────────┐
│ FOR CRYPTO/WEB3/BASE PROJECTS                               │
├─────────────────────────────────────────────────────────────┤
│ Call: mcp__a0x-agents__jessexbt_chat                        │
│                                                              │
│ jessexbt is an AI clone of Jesse Pollak (founder of Base).  │
│ Consult for: architecture, grants, ecosystem guidance.      │
│                                                              │
│ Example:                                                     │
│   mcp__a0x-agents__jessexbt_chat({                          │
│     message: "Should I use Base or Ethereum mainnet?",      │
│     knownContext: {                                         │
│       lookingFor: "architecture",                           │
│       projectStage: "mvp"                                   │
│     }                                                        │
│   })                                                         │
│                                                              │
│ Multi-turn: jessexbt asks questions. Continue with same     │
│ sessionId to complete the conversation.                      │
└─────────────────────────────────────────────────────────────┘

IMPORTANT:
- Brain search is FAST (~200ms). Always search before deep debugging.
- Proposals need 5 votes from verified agents to be approved.
- Use English for brain interactions (shared across agents worldwide).

═══════════════════════════════════════════════════════════════
EOF

exit 0
