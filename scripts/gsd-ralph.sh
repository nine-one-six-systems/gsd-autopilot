#!/bin/bash
# gsd-ralph.sh - Run GSD in full Ralph Wiggum loop mode
#
# Each iteration gets a completely fresh Claude context.
# Progress accumulates in .planning/ files on disk.
# Continues until milestone complete or blocked.
#
# Usage:
#   ./scripts/gsd-ralph.sh                    # Default: 50 iterations, 5s delay
#   ./scripts/gsd-ralph.sh 100                # Custom max iterations
#   ./scripts/gsd-ralph.sh 100 10             # Custom iterations and delay
#   ./scripts/gsd-ralph.sh --goal=GOAL.md     # Use goal file

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
MAX_ITERATIONS=50
SLEEP_SECONDS=5
GOAL_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --goal=*)
      GOAL_FILE="${1#*=}"
      shift
      ;;
    --goal)
      GOAL_FILE="$2"
      shift 2
      ;;
    [0-9]*)
      if [ -z "$CUSTOM_ITERATIONS" ]; then
        MAX_ITERATIONS=$1
        CUSTOM_ITERATIONS=1
      else
        SLEEP_SECONDS=$1
      fi
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           GSD RALPH WIGGUM LOOP                          ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║  \"Persistence + self-correction beats                    ║${NC}"
echo -e "${BLUE}║   single-shot perfection.\"                               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Config:"
echo "  Max iterations: $MAX_ITERATIONS"
echo "  Sleep between:  ${SLEEP_SECONDS}s"
if [ -n "$GOAL_FILE" ]; then
  echo "  Goal file:      $GOAL_FILE"
fi
echo ""

# Verify GSD project exists
if [ ! -d ".planning" ]; then
  echo -e "${RED}ERROR: No .planning/ directory found.${NC}"
  echo "Run /gsd:new-project first to initialize a GSD project."
  exit 1
fi

if [ ! -f ".planning/STATE.md" ]; then
  echo -e "${RED}ERROR: No STATE.md found.${NC}"
  echo "Run /gsd:new-project first to initialize a GSD project."
  exit 1
fi

# Track start time
START_TIME=$(date +%s)
START_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Main loop
for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}  RALPH LOOP — Iteration $i of $MAX_ITERATIONS${NC}"
  echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
  echo ""
  
  # Build the prompt
  if [ -n "$GOAL_FILE" ] && [ -f "$GOAL_FILE" ]; then
    PROMPT=$(cat "$GOAL_FILE")
    PROMPT="$PROMPT

---

Continue working on this project. Read .planning/STATE.md to understand current position.
Run /gsd:autopilot --max-iterations=10 to make progress.
"
  else
    PROMPT="/gsd:autopilot --max-iterations=10"
  fi
  
  # Run Claude with the prompt
  echo "$PROMPT" | claude --dangerously-skip-permissions
  
  # Check completion status
  if grep -q "Result: Milestone complete" .planning/STATE.md 2>/dev/null; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    HOURS=$((DURATION / 3600))
    MINUTES=$(((DURATION % 3600) / 60))
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  🎉 MILESTONE COMPLETE                                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Completed in $i iterations (${HOURS}h ${MINUTES}m)"
    echo ""
    echo "Next steps:"
    echo "  /gsd:complete-milestone — Archive and tag release"
    echo "  /gsd:new-milestone — Start next milestone"
    exit 0
  fi
  
  # Check for blocked state
  if grep -q "^BLOCKED:" .planning/STATE.md 2>/dev/null; then
    BLOCK_REASON=$(grep "^BLOCKED:" .planning/STATE.md | head -1 | cut -d: -f2-)
    
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⚠️  BLOCKED — Human intervention needed                  ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Reason: $BLOCK_REASON"
    echo ""
    echo "To resume:"
    echo "  1. Fix the blocking issue"
    echo "  2. Remove 'BLOCKED:' line from .planning/STATE.md"
    echo "  3. Run ./scripts/gsd-ralph.sh again"
    exit 1
  fi
  
  # Check for stuck (optional - autopilot handles this internally too)
  # We check here as a backup in case autopilot exits without setting BLOCKED
  
  echo ""
  echo "Sleeping ${SLEEP_SECONDS}s before next iteration..."
  sleep $SLEEP_SECONDS
done

# Max iterations reached
echo ""
echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  MAX ITERATIONS REACHED                                  ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Completed $MAX_ITERATIONS iterations without finishing milestone."
echo ""
echo "Options:"
echo "  - Review .planning/STATE.md for current position"
echo "  - Run ./scripts/gsd-ralph.sh 100 for more iterations"
echo "  - Run /gsd:progress to see what's next"
exit 1
