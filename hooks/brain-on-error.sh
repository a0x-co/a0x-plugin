#!/bin/bash
# brain-on-error.sh
#
# Hook: PostToolUseFailure
# Purpose: When an agent hits a wall (error), search the brain for solutions.
# Generic version - detects 30+ languages and frameworks.
#
# Input (stdin): JSON from Claude Code hook system
# Output (stdout): Context injection suggesting brain search

set -e

INPUT=$(cat)

# Extract fields from hook input
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
ERROR_OUTPUT=$(echo "$INPUT" | jq -r '.tool_result // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Only process Bash errors
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

# Skip non-error outputs
if [[ "$ERROR_OUTPUT" == *"Permission denied"* ]] || \
   [[ "$ERROR_OUTPUT" == *"cancelled"* ]] || \
   [[ "$ERROR_OUTPUT" == *"interrupted"* ]]; then
  exit 0
fi

#═══════════════════════════════════════════════════════════════
# ERROR TYPE DETECTION
#═══════════════════════════════════════════════════════════════

ERROR_TYPE=""

# JavaScript/TypeScript errors
if [[ "$ERROR_OUTPUT" == *"TypeError"* ]]; then
  ERROR_TYPE="TypeError"
elif [[ "$ERROR_OUTPUT" == *"ReferenceError"* ]]; then
  ERROR_TYPE="ReferenceError"
elif [[ "$ERROR_OUTPUT" == *"SyntaxError"* ]]; then
  ERROR_TYPE="SyntaxError"
elif [[ "$ERROR_OUTPUT" == *"RangeError"* ]]; then
  ERROR_TYPE="RangeError"
elif [[ "$ERROR_OUTPUT" == *"Cannot find module"* ]]; then
  ERROR_TYPE="ModuleNotFoundError"
elif [[ "$ERROR_OUTPUT" == *"Module not found"* ]]; then
  ERROR_TYPE="ModuleNotFoundError"
elif [[ "$ERROR_OUTPUT" == *"error TS"* ]] || [[ "$ERROR_OUTPUT" == *"Compilation error"* ]]; then
  ERROR_TYPE="CompilationError"

# Python errors
elif [[ "$ERROR_OUTPUT" == *"NameError"* ]]; then
  ERROR_TYPE="NameError"
elif [[ "$ERROR_OUTPUT" == *"ValueError"* ]]; then
  ERROR_TYPE="ValueError"
elif [[ "$ERROR_OUTPUT" == *"KeyError"* ]]; then
  ERROR_TYPE="KeyError"
elif [[ "$ERROR_OUTPUT" == *"ImportError"* ]] || [[ "$ERROR_OUTPUT" == *"ModuleNotFoundError"* ]] && [[ "$COMMAND" == *"python"* ]]; then
  ERROR_TYPE="ImportError"
elif [[ "$ERROR_OUTPUT" == *"AttributeError"* ]]; then
  ERROR_TYPE="AttributeError"
elif [[ "$ERROR_OUTPUT" == *"IndentationError"* ]]; then
  ERROR_TYPE="IndentationError"
elif [[ "$ERROR_OUTPUT" == *"RuntimeError"* ]]; then
  ERROR_TYPE="RuntimeError"
elif [[ "$ERROR_OUTPUT" == *"StopIteration"* ]]; then
  ERROR_TYPE="StopIteration"
elif [[ "$ERROR_OUTPUT" == *"ZeroDivisionError"* ]]; then
  ERROR_TYPE="ZeroDivisionError"
elif [[ "$ERROR_OUTPUT" == *"FileNotFoundError"* ]] && [[ "$COMMAND" == *"python"* ]]; then
  ERROR_TYPE="FileNotFoundError"
elif [[ "$ERROR_OUTPUT" == *"PermissionError"* ]]; then
  ERROR_TYPE="PermissionError"

# C/C++ errors
elif [[ "$ERROR_OUTPUT" == *"segmentation fault"* ]] || [[ "$ERROR_OUTPUT" == *"Segmentation fault"* ]] || [[ "$ERROR_OUTPUT" == *"SIGSEGV"* ]]; then
  ERROR_TYPE="SegmentationFault"
elif [[ "$ERROR_OUTPUT" == *"undefined reference"* ]]; then
  ERROR_TYPE="LinkerError"
elif [[ "$ERROR_OUTPUT" == *"cannot find -l"* ]]; then
  ERROR_TYPE="LibraryNotFoundError"
elif [[ "$ERROR_OUTPUT" == *"fatal error:"* ]]; then
  ERROR_TYPE="CompilationError"
elif [[ "$ERROR_OUTPUT" == *"bus error"* ]]; then
  ERROR_TYPE="BusError"
elif [[ "$ERROR_OUTPUT" == *"stack smashing"* ]]; then
  ERROR_TYPE="StackOverflow"

# Rust errors
elif [[ "$ERROR_OUTPUT" == *"cannot find"* ]] && [[ "$ERROR_OUTPUT" == *"in this scope"* ]]; then
  ERROR_TYPE="ScopeError"
elif [[ "$ERROR_OUTPUT" == *"borrow checker"* ]] || [[ "$ERROR_OUTPUT" == *"cannot borrow"* ]]; then
  ERROR_TYPE="BorrowCheckerError"
elif [[ "$ERROR_OUTPUT" == *"lifetime"* ]] && [[ "$ERROR_OUTPUT" == *"error"* ]]; then
  ERROR_TYPE="LifetimeError"
elif [[ "$ERROR_OUTPUT" == *"cargo"* ]] && [[ "$ERROR_OUTPUT" == *"error"* ]]; then
  ERROR_TYPE="CargoError"

# Go errors
elif [[ "$ERROR_OUTPUT" == *"undefined:"* ]]; then
  ERROR_TYPE="UndefinedError"
elif [[ "$ERROR_OUTPUT" == *"cannot refer to unexported"* ]]; then
  ERROR_TYPE="UnexportedError"
elif [[ "$ERROR_OUTPUT" == *"imported but not used"* ]]; then
  ERROR_TYPE="UnusedImportError"

# Solidity/Foundry/Hardhat errors
elif [[ "$ERROR_OUTPUT" == *"revert"* ]]; then
  ERROR_TYPE="RevertError"
elif [[ "$ERROR_OUTPUT" == *"execution failed"* ]]; then
  ERROR_TYPE="ExecutionError"
elif [[ "$ERROR_OUTPUT" == *"out of gas"* ]] || [[ "$ERROR_OUTPUT" == *"gas"* ]]; then
  ERROR_TYPE="GasError"

# Cadence (Flow) errors
elif [[ "$FILE_PATH" == *".cdc"* ]] && [[ "$ERROR_OUTPUT" == *"error"* ]]; then
  ERROR_TYPE="CadenceError"
elif [[ "$ERROR_OUTPUT" == *"type mismatch"* ]] && [[ "$COMMAND" == *"flow"* ]]; then
  ERROR_TYPE="CadenceTypeMismatch"

# Move (Aptos/Sui) errors
elif [[ "$FILE_PATH" == *".move"* ]] && [[ "$ERROR_OUTPUT" == *"error"* ]]; then
  ERROR_TYPE="MoveError"

# Network/System errors
elif [[ "$ERROR_OUTPUT" == *"ENOENT"* ]]; then
  ERROR_TYPE="FileNotFoundError"
elif [[ "$ERROR_OUTPUT" == *"ECONNREFUSED"* ]] || [[ "$ERROR_OUTPUT" == *"ECONNRESET"* ]]; then
  ERROR_TYPE="NetworkError"
elif [[ "$ERROR_OUTPUT" == *"ETIMEDOUT"* ]] || [[ "$ERROR_OUTPUT" == *"timeout"* ]]; then
  ERROR_TYPE="TimeoutError"
elif [[ "$ERROR_OUTPUT" == *"ENOTFOUND"* ]]; then
  ERROR_TYPE="DNSError"

# Build/Package errors
elif [[ "$ERROR_OUTPUT" == *"build failed"* ]]; then
  ERROR_TYPE="BuildError"
elif [[ "$ERROR_OUTPUT" == *"npm ERR!"* ]]; then
  ERROR_TYPE="NpmError"
elif [[ "$ERROR_OUTPUT" == *"yarn error"* ]]; then
  ERROR_TYPE="YarnError"

# Test failures
elif [[ "$ERROR_OUTPUT" == *"FAIL"* ]] || [[ "$ERROR_OUTPUT" == *"test failed"* ]]; then
  ERROR_TYPE="TestFailure"
elif [[ "$ERROR_OUTPUT" == *"AssertionError"* ]]; then
  ERROR_TYPE="AssertionError"
fi

#═══════════════════════════════════════════════════════════════
# LANGUAGE DETECTION
#═══════════════════════════════════════════════════════════════

LANGUAGE=""
FRAMEWORK=""

# Detect from file extension
case "$FILE_PATH" in
  *.ts|*.tsx)           LANGUAGE="typescript" ;;
  *.js|*.jsx|*.mjs)     LANGUAGE="javascript" ;;
  *.py)                 LANGUAGE="python" ;;
  *.c)                  LANGUAGE="c" ;;
  *.cpp|*.cc|*.cxx|*.hpp) LANGUAGE="cpp" ;;
  *.rs)                 LANGUAGE="rust" ;;
  *.go)                 LANGUAGE="go" ;;
  *.sol)                LANGUAGE="solidity" ;;
  *.cdc)                LANGUAGE="cadence" ;;
  *.move)               LANGUAGE="move" ;;
  *.java)               LANGUAGE="java" ;;
  *.kt|*.kts)           LANGUAGE="kotlin" ;;
  *.rb)                 LANGUAGE="ruby" ;;
  *.php)                LANGUAGE="php" ;;
  *.swift)              LANGUAGE="swift" ;;
  *.scala|*.sc)         LANGUAGE="scala" ;;
  *.ex|*.exs)           LANGUAGE="elixir" ;;
  *.erl)                LANGUAGE="erlang" ;;
  *.hs)                 LANGUAGE="haskell" ;;
  *.clj|*.cljs)         LANGUAGE="clojure" ;;
  *.lua)                LANGUAGE="lua" ;;
  *.r|*.R)              LANGUAGE="r" ;;
  *.sql)                LANGUAGE="sql" ;;
  *.sh)                 LANGUAGE="bash" ;;
  Makefile|*.mk)        LANGUAGE="make" ;;
  Dockerfile)           LANGUAGE="dockerfile" ;;
esac

# Detect from command (override if more specific)
case "$COMMAND" in
  *node*|*npm*|*npx*)   LANGUAGE="${LANGUAGE:-javascript}" ;;
  *typescript*|*tsc*)   LANGUAGE="typescript" ;;
  *python*|*pip*|*pytest*|*uvicorn*) LANGUAGE="${LANGUAGE:-python}" ;;
  *gcc*|*clang*|*make*) LANGUAGE="${LANGUAGE:-c}" ;;
  *g++*|*clang++*)      LANGUAGE="${LANGUAGE:-cpp}" ;;
  *cargo*|*rustc*)      LANGUAGE="${LANGUAGE:-rust}" ;;
  *go\ *)               LANGUAGE="${LANGUAGE:-go}" ;;
  *forge*|*foundry*)    LANGUAGE="${LANGUAGE:-solidity}"; FRAMEWORK="${FRAMEBACK:-foundry}" ;;
  *hardhat*)            LANGUAGE="${LANGUAGE:-solidity}"; FRAMEWORK="${FRAMEBACK:-hardhat}" ;;
  *flow*)               LANGUAGE="${LANGUAGE:-cadence}" ;;
  *aptos*|*sui*)        LANGUAGE="${LANGUAGE:-move}" ;;
  *javac*|*java*|*mvn*) LANGUAGE="${LANGUAGE:-java}" ;;
  *ruby*|*rails*)       LANGUAGE="${LANGUAGE:-ruby}" ;;
esac

#═══════════════════════════════════════════════════════════════
# FRAMEWORK DETECTION
#═══════════════════════════════════════════════════════════════

if [[ -z "$FRAMEWORK" ]]; then
  case "$COMMAND" in
    *next*)       FRAMEWORK="nextjs" ;;
    *react*|*vite*) FRAMEWORK="react" ;;
    *vue*|*nuxt*) FRAMEWORK="vue" ;;
    *svelte*)     FRAMEWORK="svelte" ;;
    *angular*)    FRAMEWORK="angular" ;;
    *express*)    FRAMEWORK="express" ;;
    *nestjs*)     FRAMEWORK="nestjs" ;;
    *django*)     FRAMEWORK="django" ;;
    *flask*)      FRAMEWORK="flask" ;;
    *fastapi*)    FRAMEWORK="fastapi" ;;
    *pytest*)     FRAMEWORK="pytest" ;;
    *rails*)      FRAMEWORK="rails" ;;
    *wagmi*)      FRAMEWORK="wagmi" ;;
    *viem*)       FRAMEWORK="viem" ;;
    *ethers*)     FRAMEWORK="ethers" ;;
  esac
fi

#═══════════════════════════════════════════════════════════════
# BUILD SEARCH QUERY
#═══════════════════════════════════════════════════════════════

QUERY=""
[[ -n "$ERROR_TYPE" ]] && QUERY="$ERROR_TYPE"
[[ -n "$COMMAND" ]] && QUERY="$QUERY $(echo "$COMMAND" | awk '{print $1}')"

# Add error snippet
ERROR_SNIPPET=$(echo "$ERROR_OUTPUT" | grep -v "^$" | head -3 | tr '\n' ' ' | cut -c1-150)
QUERY="$QUERY $ERROR_SNIPPET"

# Clean up
QUERY=$(echo "$QUERY" | tr -s ' ' | sed 's/^ *//;s/ *$//')

#═══════════════════════════════════════════════════════════════
# OUTPUT
#═══════════════════════════════════════════════════════════════

cat <<EOF
═══════════════════════════════════════════════════════════════
🧠 BRAIN PROTOCOL - ERROR DETECTED
═══════════════════════════════════════════════════════════════

Before debugging, SEARCH THE COLLECTIVE BRAIN.
Another agent may have already solved this.

1️⃣  SEARCH:
    mcp__a0x-brain__knowledge_search({
      query: "$QUERY",
      memory_type: "error"$(
        if [[ -n "$LANGUAGE" ]]; then echo ","; echo "      language: \"$LANGUAGE\""; fi
        if [[ -n "$FRAMEWORK" ]]; then echo ","; echo "      framework: \"$FRAMEWORK\""; fi
      )
    })

2️⃣  IF FOUND: Apply the learnings.

3️⃣  IF NOT FOUND: After solving, PROPOSE:
    mcp__a0x-brain__knowledge_propose({
      memory_type: "error",
      situation: "<context>",
      action: "<fix>",
      outcome: "<result>",
      learnings: ["<takeaway>"],
      tags: ["$(if [[ -n "$LANGUAGE" ]]; then echo "$LANGUAGE, "; fi)debugging"]$(
        if [[ -n "$ERROR_TYPE" ]]; then echo ""; echo "      error_type: \"$ERROR_TYPE\""; fi
      )
    })

───────────────────────────────────────────────────────────────
Detected: $ERROR_TYPE | $LANGUAGE | $FRAMEWORK
File: ${FILE_PATH:-N/A}
───────────────────────────────────────────────────────────────
EOF

exit 0
