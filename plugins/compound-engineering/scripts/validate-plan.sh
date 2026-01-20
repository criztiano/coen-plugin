#!/bin/bash
# PostToolUse hook: Validate plan files against quality checklist
# Triggers on Write to plans/*.md
#
# Exit codes:
#   0 = pass (with optional warnings)
#   2 = block (must fix before proceeding)
#
# Harness Engineering principle: "Bad research = whole thing is hosed"
# This hook ensures plans are grounded in verified research before proceeding.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

# Only trigger for Write tool on plans/ directory
if [[ "$TOOL_NAME" != "Write" ]] || [[ ! "$FILE_PATH" =~ plans/.*\.md$ ]]; then
  exit 0
fi

# Read the plan content
if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

CONTENT=$(cat "$FILE_PATH")
ERRORS=()
WARNINGS=()

# ═══════════════════════════════════════════════════════════════════
# VALIDATION CHECKLIST
# ═══════════════════════════════════════════════════════════════════

# 1. MUST HAVE: File references with line numbers (research grounding)
#    Pattern: path/to/file.ext:123 or path/to/file.ext:123-456
if ! echo "$CONTENT" | grep -qE '[a-zA-Z0-9_/.-]+\.[a-z]+:[0-9]+'; then
  ERRORS+=("MISSING: File references with line numbers (e.g., src/auth.ts:42)")
  ERRORS+=("   -> Research must identify specific code locations")
fi

# 2. MUST HAVE: Acceptance Criteria section
if ! echo "$CONTENT" | grep -qiE '^##.*Acceptance Criteria|^##.*Acceptance'; then
  ERRORS+=("MISSING: Acceptance Criteria section")
  ERRORS+=("   -> Plan must define what 'done' looks like")
fi

# 3. SHOULD HAVE: At least one code block (implementation grounding)
if ! echo "$CONTENT" | grep -qE '```[a-z]*'; then
  WARNINGS+=("NO CODE BLOCKS: Consider adding example code snippets")
  WARNINGS+=("   -> Harness principle: 'Plan so clear the dumbest model won't screw it up'")
fi

# 4. SHOULD HAVE: References section
if ! echo "$CONTENT" | grep -qiE '^##.*Reference|^##.*Research'; then
  WARNINGS+=("MISSING: References section")
  WARNINGS+=("   -> Link to docs, PRs, or issues that informed this plan")
fi

# 5. SHOULD HAVE: Technical Approach or Proposed Solution
if ! echo "$CONTENT" | grep -qiE '^##.*Technical|^##.*Approach|^##.*Solution|^##.*Implementation'; then
  WARNINGS+=("MISSING: Technical Approach section")
  WARNINGS+=("   -> How will this be implemented?")
fi

# 6. CHECK: Vague language (signs of weak research)
VAGUE_PATTERNS=(
  "somewhere in"
  "probably in"
  "might be"
  "should work"
  "similar to existing"
  "like the existing"
)
for pattern in "${VAGUE_PATTERNS[@]}"; do
  if echo "$CONTENT" | grep -qi "$pattern"; then
    WARNINGS+=("VAGUE LANGUAGE: Found '$pattern'")
    WARNINGS+=("   -> Replace with specific file paths and verified facts")
    break  # Only report once
  fi
done

# 7. QUALITY: Check for actual before/after code (Harness-style)
HAS_BEFORE_AFTER=false
if echo "$CONTENT" | grep -qiE '(before|after|current|proposed|existing|new).*:'; then
  if echo "$CONTENT" | grep -qE '```'; then
    HAS_BEFORE_AFTER=true
  fi
fi
if [[ "$HAS_BEFORE_AFTER" == "false" ]]; then
  # Only add this as a minor suggestion, not for every plan
  if echo "$CONTENT" | grep -qiE 'refactor|change|update|modify|fix'; then
    WARNINGS+=("CONSIDER: Add before/after code examples for changes")
  fi
fi

# 8. CHECK: MVP or Implementation section for concrete steps
if ! echo "$CONTENT" | grep -qiE '^##.*MVP|^###.*Phase|^###.*Step|^##.*Implementation.*Plan'; then
  WARNINGS+=("CONSIDER: Add MVP section or implementation phases")
  WARNINGS+=("   -> Break down into concrete, executable steps")
fi

# ═══════════════════════════════════════════════════════════════════
# OUTPUT RESULTS
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "========================================================================"
echo "PLAN VALIDATION: $(basename "$FILE_PATH")"
echo "========================================================================"

# Report errors (blocking)
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo ""
  echo "BLOCKING ISSUES (must fix):"
  for err in "${ERRORS[@]}"; do
    echo "  X $err"
  done
fi

# Report warnings (advisory)
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo ""
  echo "SUGGESTIONS (recommended):"
  for warn in "${WARNINGS[@]}"; do
    echo "  ! $warn"
  done
fi

# Summary
echo ""
if [[ ${#ERRORS[@]} -eq 0 ]] && [[ ${#WARNINGS[@]} -eq 0 ]]; then
  echo "PLAN VALIDATED: All checks passed"
  echo ""
  exit 0
elif [[ ${#ERRORS[@]} -eq 0 ]]; then
  echo "PLAN ACCEPTABLE: ${#WARNINGS[@]} suggestion(s) for improvement"
  echo "   -> Proceed to /deepen-plan to address suggestions, or continue to /workflows:work"
  echo ""
  exit 0
else
  echo "PLAN INCOMPLETE: ${#ERRORS[@]} blocking issue(s) must be fixed"
  echo ""
  echo "ACTION REQUIRED:"
  echo "  1. Add specific file:line references from research (e.g., src/services/auth.ts:42)"
  echo "  2. Ensure Acceptance Criteria section exists with checkboxes"
  echo "  3. Re-run /workflows:plan or edit the plan manually"
  echo ""
  echo "WHY THIS MATTERS:"
  echo "  Plans without grounded research lead to wrong implementations."
  echo "  'Bad research = whole thing is hosed' - Harness Engineering"
  echo ""
  exit 2  # Block - plan is not ready
fi
