#!/bin/bash
# gsd-loop.sh - Ralph Wiggum-style loop for GSD

MAX_ITERATIONS=${1:-50}
ITERATION=0

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
  echo "=== GSD Loop Iteration $ITERATION ==="
  
  # Feed GSD the same prompt each time - it reads STATE.md to know where it is
  echo "/gsd:autopilot" | claude --dangerously-skip-permissions
  
  # Check if milestone complete
  if grep -q "status:.*complete" .planning/STATE.md 2>/dev/null; then
    echo "Milestone complete!"
    exit 0
  fi
  
  # Check for blocked state
  if grep -q "BLOCKED" .planning/STATE.md 2>/dev/null; then
    echo "Blocked - human intervention needed"
    exit 1
  fi
  
  ITERATION=$((ITERATION + 1))
  sleep 5
done

echo "Max iterations reached"
