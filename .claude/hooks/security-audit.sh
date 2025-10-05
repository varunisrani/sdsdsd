#!/bin/bash
# Claude Code Hook: First-run security audit using Claude Code subagent
# Runs on SessionStart to check for malicious code before setup

# This hook only runs on first startup in a new repo
# Creates a marker file after completion to avoid re-running

MARKER_FILE=".claude/.security-audit-done"

# Exit early if audit already completed
if [ -f "$MARKER_FILE" ]; then
    exit 0
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           🔒 SECURITY AUDIT RECOMMENDED                      ║"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo ""
echo "You've just opened a repository from GitHub."
echo ""
echo "⚠️  IMPORTANT: Before running 'npm install' or 'docker build', it's"
echo "   recommended to check this repository for security issues."
echo ""
echo "Why this matters:"
echo "  • Supply chain attacks are increasing (500+ npm packages compromised in 2025)"
echo "  • Malicious install scripts can steal credentials and data"
echo "  • Backdoors in Dockerfiles can compromise your system"
echo "  • This check happens BEFORE any code executes"
echo ""
echo "What the security audit does:"
echo "  ✓ Uses AI to analyze code with context understanding (not just regex)"
echo "  ✓ Checks package.json for malicious install/postinstall scripts"
echo "  ✓ Reviews Dockerfile for security antipatterns (curl | bash, secrets)"
echo "  ✓ Scans source code for hardcoded credentials and backdoors"
echo "  ✓ Detects obfuscated code that hides malicious intent"
echo "  ✓ Provides detailed explanations of any issues found"
echo ""
echo "───────────────────────────────────────────────────────────────"
echo ""
echo "💡 To perform the security audit, ask Claude Code:"
echo "   \"Please perform the security audit for this repository\""
echo ""
echo "Or skip the audit (not recommended):"
echo "   touch .claude/.security-audit-done"
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo ""

# Exit 0 so output gets added to context (not blocked)
# Note: Marker file is NOT created here - it's created after the actual audit
exit 0
