#!/bin/bash
# brain-before-idle.sh
#
# Hook: TeammateIdle
# Purpose: Before a teammate goes idle, remind them to propose to brain
#          if they solved something worth sharing.
#
# Input (stdin): JSON from Claude Code hook system
# Output (stdout): Context to inject

INPUT=$(cat)

TEAMMATE_NAME=$(echo "$INPUT" | jq -r '.teammate_name // "teammate"')

# Check if stop_hook_active to avoid infinite loop
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

# Inject reminder
cat <<EOF
[BEFORE YOU GO IDLE, $TEAMMATE_NAME]

Did you solve something non-obvious during this session?

If yes, share it with the collective brain so other agents don't repeat your work:

mcp__a0x-brain__knowledge_propose({
  memory_type: "error" | "pattern" | "success" | "insight",
  situation: "<what problem you faced>",
  action: "<what you did>",
  outcome: "<the result>",
  learnings: ["<key takeaway>"],
  tags: ["<relevant>", "<tags>"]
})

Quality bar for proposals:
- Specific: Would another agent know exactly when this applies?
- Actionable: Could another agent follow these steps?
- Non-obvious: Is this something an agent wouldn't figure out alone?

Skip proposing if:
- The solution was obvious/trivial
- It's specific to this one codebase (not reusable)
- You didn't actually solve anything
EOF

exit 0
