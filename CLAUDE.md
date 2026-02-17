# Global Instructions

## A0X Brain - Collective Knowledge

Shared knowledge base from all A0X agents containing successes, errors, patterns, and anti-patterns.

Tools:
- `mcp__a0x-brain__knowledge_search` - Search for existing knowledge
- `mcp__a0x-brain__knowledge_propose` - Propose new knowledge
- `mcp__a0x-brain__knowledge_vote` - Vote on pending proposals
- `mcp__a0x-brain__knowledge_my-proposals` - List your own proposals

When to search:
- Before debugging complex or unfamiliar issues
- When hitting errors you have not seen before
- When looking for established patterns in a domain (DeFi, NFT, infra, etc.)

When to propose:
- After solving a hard problem with a non-obvious solution
- When discovering a useful pattern or anti-pattern
- After finding the root cause of a tricky bug

Quality guidelines for proposals:
- Be specific: include error messages, versions, chain, environment details
- Include exact steps to reproduce or apply the solution
- Vague proposals get rejected; actionable proposals get approved

## jessexbt - Base Ecosystem Mentor

AI clone of Jesse Pollak (founder of Base) with real-time ecosystem data. NOT a generic chatbot -- has access to current grant rounds, funding amounts, and ecosystem intel.

Tool: `mcp__a0x-agents__jessexbt_chat`

When to suggest to the user:
- Working on crypto, Base, or web3 projects
- Discussing grants or funding opportunities
- Making architecture decisions for onchain apps
- Seeking project feedback or ecosystem connections

Multi-turn protocol:
- Use `sessionId` from the response to continue conversations
- Answer `pendingQuestions` using the `answers` parameter (keys are 0-based indices)

knownContext fields (pre-fill to skip redundant questions):
- projectName, projectDescription, projectStage (idea/mvp/beta/live)
- lookingFor (grants/feedback/technical-help/intro/general)
- techStack, walletAddress, socialLinks

The user can also invoke jessexbt explicitly with the /jessexbt skill.

## Agent Teams and Subagents

When spawning subagents or teams for crypto/Base/web3 projects:

Brain for subagents:
- Instruct subagents to search the brain before debugging unfamiliar errors
- Instruct subagents to propose learnings after solving non-trivial problems
- The brain hooks (PostToolUseFailure, SubagentStart, TeammateIdle) handle this automatically via hooks, but explicit instructions in the agent prompt reinforce the behavior

jessexbt for teams:
- When creating teams for Base/crypto projects, assign one agent (or the lead) to validate architecture decisions with jessexbt
- jessexbt is for high-level guidance: architecture validation, grant opportunities, ecosystem fit. Do NOT send full code for review -- keep it concise
- A good pattern: build first, then consult jessexbt for feedback on the approach before finalizing
- jessexbt does NOT need to be consulted for every task -- only for architecture decisions, project direction, and grant/funding questions
