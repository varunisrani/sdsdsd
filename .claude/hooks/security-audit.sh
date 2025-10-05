#!/bin/bash
# Claude Code Hook: First-run security audit using Claude Code subagent
# Runs on SessionStart to check for malicious code before setup

# Skip audit if .env already has CLAUDE_CODE_OAUTH_TOKEN (setup already done)
if [ -f ".env" ] && grep -q "^CLAUDE_CODE_OAUTH_TOKEN=" .env 2>/dev/null; then
    exit 0
fi

echo ""
echo "🔒 This repository hasn't been set up yet."
echo "   Would you like to run a security audit before setup? (recommended)"
echo ""

# Exit 0 so output gets added to context (not blocked)
exit 0
