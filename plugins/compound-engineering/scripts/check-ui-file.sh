#!/bin/bash
# PostToolUse hook: Check if edited file is UI-related
# If so, flag that browser testing is mandatory
# Exit 0 always (advisory, doesn't block)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# UI-related file patterns
UI_PATTERNS=(
  "\.tsx$"
  "\.jsx$"
  "\.css$"
  "\.scss$"
  "/components/"
  "/pages/"
  "/app/"
  "/views/"
  "/layouts/"
  "/templates/"
  "/styles/"
  "form"
  "input"
  "validation"
  "/store/"
  "/context/"
  "/hooks/use"
  "tailwind\.config"
  "theme\."
)

# Check if file matches any UI pattern
for pattern in "${UI_PATTERNS[@]}"; do
  if echo "$FILE_PATH" | grep -qiE "$pattern"; then
    echo "⚠️  UI FILE MODIFIED: $FILE_PATH"
    echo "   → Browser testing is MANDATORY before PR creation"
    echo "   → Run /test-browser after review completes"
    exit 0
  fi
done

# Not a UI file, no message needed
exit 0
