#!/usr/bin/env bash
# Status line — single line shown at the bottom of Claude Code.
# Format: branch [↑a ↓b] [+S ~M ?U]
cat >/dev/null  # discard stdin JSON

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -z "$BRANCH" ] && { echo "no-git"; exit 0; }

OUT="$BRANCH"

UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
if [ -n "$UPSTREAM" ]; then
    A=$(git rev-list --count '@{u}..HEAD' 2>/dev/null)
    B=$(git rev-list --count 'HEAD..@{u}' 2>/dev/null)
    [ "${A:-0}" != "0" ] && OUT="$OUT ↑$A"
    [ "${B:-0}" != "0" ] && OUT="$OUT ↓$B"
fi

S=$(git diff --staged --name-only 2>/dev/null | grep -c .)
M=$(git diff --name-only 2>/dev/null | grep -c .)
U=$(git ls-files --others --exclude-standard 2>/dev/null | grep -c .)

STATUS=""
[ "$S" != "0" ] && STATUS="$STATUS +$S"
[ "$M" != "0" ] && STATUS="$STATUS ~$M"
[ "$U" != "0" ] && STATUS="$STATUS ?$U"
[ -n "$STATUS" ] && OUT="$OUT |$STATUS"

echo "$OUT"
