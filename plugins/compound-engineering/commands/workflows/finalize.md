---
name: workflows:finalize
description: Final checks and PR creation after incremental reviews have been done
argument-hint: "[PR number, branch name, or 'current']"
---

# Finalize Command

<command_purpose>Light-weight final review focusing on cross-cutting concerns, browser testing, and PR creation. Use after work with incremental doer→reviewer cycles.</command_purpose>

## When to Use

Use `/workflows:finalize` instead of `/workflows:review` when:
- Doer agents (design-iterator, figma-design-sync, etc.) already triggered their reviewers
- Code changes were reviewed incrementally during work
- You only need cross-cutting checks (security, architecture) + PR creation

Use `/workflows:review` when:
- No incremental reviews were done
- You want a full multi-agent review from scratch

## Workflow Position

```
Plan → Work (with auto-reviewers) → Finalize → Compound
                    ↑                    ↑
           Incremental reviews    Cross-cutting only
```

## Main Tasks

### 1. Setup

<task_list>
- [ ] Determine target: PR number, branch name, or current branch
- [ ] Ensure we're on the correct branch
- [ ] Fetch PR metadata if applicable
</task_list>

### 2. Cross-Cutting Reviews (Parallel)

Run only the cross-cutting agents that need the full picture:

```bash
# Launch in parallel
Task security-sentinel("Review all changes for security vulnerabilities, injection risks, authentication issues, data exposure.")

Task architecture-strategist("Review architectural decisions, component boundaries, dependency directions, and overall design coherence.")
```

These agents check concerns that span multiple files and need the complete context.

**Skip:** Language-specific reviewers (already ran incrementally)

### 3. Synthesize Outstanding Findings

<synthesis>

After cross-cutting reviews complete:

1. Collect findings from security-sentinel and architecture-strategist
2. Check `todos/` directory for any pending items from incremental reviews
3. Categorize by severity:
   - 🔴 **P1 (Critical)**: Security vulnerabilities, data corruption risks, breaking changes
   - 🟡 **P2 (Important)**: Architectural concerns, significant issues
   - 🔵 **P3 (Nice-to-have)**: Minor improvements

</synthesis>

### 4. Auto-Resolve P1/P2 Findings

If any P1 or P2 findings exist:

```bash
# Resolve P1s first (in parallel)
Task("Fix P1 finding: [description]. Read the todo file and implement the fix.")

# Then P2s (in parallel)
Task("Fix P2 finding: [description]. Read the todo file and implement the fix.")
```

Mark todos complete after fixing:
```bash
mv todos/001-pending-p1-*.md todos/001-complete-p1-*.md
```

### 5. Browser Testing

<detect_testing_requirement>

**Check for UI-affecting files:**

```bash
git diff --name-only origin/main...HEAD | grep -E '\.(tsx|jsx|css|scss)$|components/|pages/|app/|views/|layouts/|styles/' | head -5
```

| Result | Action |
|--------|--------|
| UI files found | **MANDATORY** - run `/test-browser` |
| Only API/config | **OPTIONAL** - offer testing |
| Only docs/CI/tests | **SKIP** |

</detect_testing_requirement>

#### If MANDATORY:

```markdown
**🔍 UI changes detected - running browser tests**
```

```bash
Task general-purpose("Run /test-browser. Test affected pages, check console errors, fix any failures.")
```

**Do NOT proceed to PR creation until browser tests pass.**

### 6. Commit, Push, and Create PR

Once all findings resolved and tests pass:

**Step 1: Commit**
```bash
git add .
git commit -m "$(cat <<'EOF'
feat: [Description]

- [Main changes]
- Resolved finalize findings

Cross-cutting review: security ✓, architecture ✓
EOF
)"
```

**Step 2: Push**
```bash
git push -u origin [branch-name]
```

**Step 3: Create PR**
```bash
gh pr create --title "feat: [Description]" --body "$(cat <<'EOF'
## Summary
- [What was built]

## Reviews Completed
- [X] Incremental reviews (during work)
- [X] Security review (finalize)
- [X] Architecture review (finalize)
- [X] Browser tests pass

## P3 Findings (Optional)
- [ ] [Any deferred improvements]
EOF
)"
```

## Summary Output

```markdown
## ✅ Finalize Complete

**Branch:** [branch-name]

### Cross-Cutting Reviews:
- 🔒 Security: [PASS/findings]
- 🏗️ Architecture: [PASS/findings]

### Findings Resolved:
- P1: [count] fixed
- P2: [count] fixed
- P3: [count] deferred

### Browser Tests: [PASS/SKIP]

### PR Created: #[number]
URL: [PR URL]
```

## Comparison with /workflows:review

| Aspect | /workflows:finalize | /workflows:review |
|--------|---------------------|-------------------|
| **When to use** | After incremental reviews | Full review from scratch |
| **Agents** | 2 (security, architecture) | 4-6 (all reviewers) |
| **Token usage** | Lower | Higher |
| **Finds issues** | Cross-cutting only | All issues |
| **Best for** | Work with auto-reviewers | Work without auto-reviewers |
