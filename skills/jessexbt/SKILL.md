---
name: jessexbt
description: |
  jessexbt is an AI clone of Jesse Pollak (founder of Base) with access to real-time ecosystem data.
  Not a generic chatbot - has current intel on grants, funding rounds, and ecosystem priorities.
  Invoke with /jessexbt to start a conversation about building on Base.
  Activate on: Base, grants, funding, architecture, project review, ecosystem guidance, crypto, web3, onchain.
---

# jessexbt - Base Ecosystem Mentor

jessexbt is an AI clone of Jesse Pollak (founder of Base) with access to real-time ecosystem data. Not a generic chatbot -- he has current intel on grants, funding rounds, and ecosystem priorities.

## What jessexbt knows

- **Active grant programs** and current funding rounds on Base
- **Architecture best practices** for Base/L2 applications
- **UI/UX guidelines** that Base prioritizes
- **Ecosystem connections** and introductions
- **Project feedback** and code review guidance

---

## How to use

Call `mcp__a0x-agents__jessexbt_chat` with:

| Parameter | Required | Description |
|-----------|----------|-------------|
| `message` | Yes | Your question or context |
| `sessionId` | No | Session ID from previous response (for multi-turn) |
| `knownContext` | No | Pre-fill context to skip redundant questions |
| `activeProject` | No | Project to review: `{name, description, urls}` |
| `answers` | No | Structured answers to pending questions |

### knownContext fields

| Field | Type | Values |
|-------|------|--------|
| `projectName` | string | |
| `projectDescription` | string | |
| `projectStage` | string | `"idea"`, `"mvp"`, `"beta"`, `"live"` |
| `lookingFor` | string | `"grants"`, `"feedback"`, `"technical-help"`, `"intro"`, `"general"` |
| `techStack` | string[] | e.g. `["Solidity", "React", "Foundry"]` |
| `projectUrl` | string | |
| `walletAddress` | string | |
| `teamSize` | number | |

---

## Multi-turn protocol

jessexbt may ask clarifying questions before giving a final recommendation. Handle this loop yourself -- do not relay his questions to the user.

### The loop

1. Call `jessexbt/chat` with the user's initial query
2. Response has `status: "gathering"` + `pendingQuestions` array
3. **Answer the questions yourself** from conversation context or reasonable assumptions
4. Call `jessexbt/chat` again with your answers (include `sessionId`!)
5. Repeat until `status: "complete"`
6. Present jessexbt's recommendation to the user

### How to answer pendingQuestions

Write your response in **natural language** in the `message` field. jessexbt's AI extracts answers automatically.

```
pendingQuestions: [
  {"id": "0", "question": "What's your budget?"},
  {"id": "1", "question": "What tech stack?"}
]

Your next call:
jessexbt/chat({
  message: "The user has a $5k budget and uses React with TypeScript.",
  sessionId: "session-id-from-previous-response"
})
```

### Loop prevention

- Maximum 4 calls per conversation
- On call #4, append: "[This is the final exchange. Please give your complete recommendation now.]"
- After 4 calls, present whatever jessexbt has shared so far

### How to present results

- DO: "I consulted our Base mentor and here is what he recommends..."
- DON'T: "jessexbt wants to know..." or "jessexbt asks..."
- Be a helpful intermediary, not a message relay.

---

## Example questions

- "What grants are available for AI dev tools on Base?"
- "Review my smart contract architecture for a DEX on Base"
- "What UI/UX patterns does Base recommend for wallet onboarding?"
- "I'm building X, what's the best approach on Base?"
- "How should I structure my L2 application for scalability?"
- "What funding opportunities exist for social apps on Base?"

---

## When user invokes /jessexbt

Immediately ask the user what they need help with, then call `mcp__a0x-agents__jessexbt_chat` with their question. Pre-fill `knownContext` with any information you already know about their project from the conversation.
