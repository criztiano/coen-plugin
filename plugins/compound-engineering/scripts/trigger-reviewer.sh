#!/bin/bash
# Stop hook: Trigger automatic reviewer after doer agent completes
# Usage: trigger-reviewer.sh <reviewer-agent-name> [context]
#
# This script outputs instructions for Claude to spawn the reviewer agent.
# The output is passed back to Claude who will then spawn the reviewer.

REVIEWER="$1"
CONTEXT="${2:-the changes just made}"

if [ -z "$REVIEWER" ]; then
  echo "Error: No reviewer specified" >&2
  exit 1
fi

# Map reviewer names to their descriptions
case "$REVIEWER" in
  "design-implementation-reviewer")
    REVIEW_PROMPT="Review the design implementation. Verify UI matches design intent, check responsive behavior, accessibility, and visual consistency."
    ;;
  "senior-typescript-reviewer")
    REVIEW_PROMPT="Review the TypeScript code. Check type safety, modern patterns, naming conventions, and code quality."
    ;;
  "senior-python-reviewer")
    REVIEW_PROMPT="Review the Python code. Check Pythonic patterns, type hints, naming conventions, and code quality."
    ;;
  "frontend-races-reviewer")
    REVIEW_PROMPT="Review for race conditions and async issues. Check state management, effect dependencies, and concurrent operations."
    ;;
  "security-sentinel")
    REVIEW_PROMPT="Security review. Check for vulnerabilities, injection risks, authentication issues, and data exposure."
    ;;
  "data-integrity-guardian")
    REVIEW_PROMPT="Review data integrity. Check database operations, migrations, and data consistency."
    ;;
  "performance-oracle")
    REVIEW_PROMPT="Performance review. Check for N+1 queries, unnecessary re-renders, memory leaks, and optimization opportunities."
    ;;
  *)
    REVIEW_PROMPT="Review $CONTEXT for quality and correctness."
    ;;
esac

cat << EOF

═══════════════════════════════════════════════════════════════
✓ WORK COMPLETE - AUTO-SPAWNING REVIEWER
═══════════════════════════════════════════════════════════════

Reviewer: $REVIEWER
Context: $CONTEXT

→ INSTRUCTION: Spawn the reviewer agent now:

Task $REVIEWER("$REVIEW_PROMPT

Focus on $CONTEXT. Create P1 todos for critical issues, P2 for important improvements.
After review, summarize findings and continue with next task.")

═══════════════════════════════════════════════════════════════
EOF

exit 0
