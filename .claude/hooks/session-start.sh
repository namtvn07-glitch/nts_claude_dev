#!/bin/bash
# SessionStart hook — coder workflow.
# Shows git state + recent commits + active session state (if any).

echo "=== NTS Foundation ==="

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$BRANCH" ]; then
    echo "Branch: $BRANCH"

    # Ahead/behind upstream (if tracked)
    UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    if [ -n "$UPSTREAM" ]; then
        AHEAD=$(git rev-list --count '@{u}..HEAD' 2>/dev/null)
        BEHIND=$(git rev-list --count 'HEAD..@{u}' 2>/dev/null)
        [ "${AHEAD:-0}" != "0" ]  && echo "  ↑ $AHEAD ahead of $UPSTREAM"
        [ "${BEHIND:-0}" != "0" ] && echo "  ↓ $BEHIND behind $UPSTREAM"
    fi

    echo ""
    echo "Recent commits:"
    git log --oneline -5 2>/dev/null | while read -r line; do
        echo "  $line"
    done
fi

# Working tree summary
STAGED=$(git diff --staged --name-only 2>/dev/null | grep -c .)
MODIFIED=$(git diff --name-only 2>/dev/null | grep -c .)
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | grep -c .)
if [ "$STAGED" != "0" ] || [ "$MODIFIED" != "0" ] || [ "$UNTRACKED" != "0" ]; then
    echo ""
    echo "Working tree: ${STAGED} staged, ${MODIFIED} modified, ${UNTRACKED} untracked"
fi

# Active session state (recovery checkpoint for long tasks)
STATE_FILE="production/session-state/active.md"
if [ -f "$STATE_FILE" ]; then
    echo ""
    echo "=== ACTIVE SESSION STATE DETECTED ==="
    echo "Read $STATE_FILE for full context."
    echo ""
    echo "Last 20 lines:"
    tail -20 "$STATE_FILE" 2>/dev/null
    TOTAL_LINES=$(wc -l < "$STATE_FILE" 2>/dev/null | tr -d ' ')
    if [ "${TOTAL_LINES:-0}" -gt 20 ] 2>/dev/null; then
        echo "  ... (${TOTAL_LINES} total lines)"
    fi
    echo "=== END SESSION STATE PREVIEW ==="
fi

echo "==================================="
exit 0
