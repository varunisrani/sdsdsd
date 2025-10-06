#!/bin/sh

# Setup authentication for GLM-4.6 / Claude SDK
echo "Setting up AI SDK authentication..."

# Determine which authentication method to use
if [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
    echo "Using GLM-4.6 API authentication..."
    echo "Token length: ${#ANTHROPIC_AUTH_TOKEN}"
    API_PROVIDER="GLM-4.6"
    AUTH_TOKEN="$ANTHROPIC_AUTH_TOKEN"
    BASE_URL="$ANTHROPIC_BASE_URL"
elif [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo "Using Claude SDK authentication..."
    echo "Token length: ${#CLAUDE_CODE_OAUTH_TOKEN}"
    API_PROVIDER="Claude"
    AUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN"
    BASE_URL="https://api.anthropic.com"
else
    echo "Warning: No authentication token found. Please set ANTHROPIC_AUTH_TOKEN or CLAUDE_CODE_OAUTH_TOKEN"
    API_PROVIDER="None"
fi

# Create .claude directory
mkdir -p ~/.claude
echo "Created ~/.claude directory"

# Setup environment for Claude SDK compatibility
if [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
    # Set GLM-4.6 environment variables for Claude SDK compatibility
    export ANTHROPIC_API_KEY="$ANTHROPIC_AUTH_TOKEN"
    export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.z.ai/api/anthropic}"

    echo "GLM-4.6 environment configured:"
    echo "  Base URL: $ANTHROPIC_BASE_URL"
    echo "  Model: ${GLM_MODEL:-GLM-4.6}"
fi

# Create compatibility credentials for Claude SDK if using GLM-4.6
if [ -n "$AUTH_TOKEN" ]; then
    EXPIRY_DATE=$(date -u -d "@$(($(date +%s) + 315360000))" +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%S.000Z)

    cat > ~/.claude/.credentials.json << EOF
{
  "claudeAiOauth": {
    "accessToken": "$AUTH_TOKEN",
    "refreshToken": "$AUTH_TOKEN",
    "expiresAt": "$EXPIRY_DATE",
    "scopes": ["read", "write"],
    "subscriptionType": "pro"
  }
}
EOF
fi

# Create Claude SDK configuration with GLM-4.6 support
cat > ~/.claude.json << EOF
{
  "numStartups": 1,
  "installMethod": "unknown",
  "autoUpdates": true,
  "firstStartTime": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
  "userID": "container-user",
  "projects": {
    "/app": {
      "allowedTools": [],
      "history": [],
      "mcpContextUris": [],
      "mcpServers": {},
      "enabledMcpjsonServers": [],
      "disabledMcpjsonServers": [],
      "hasTrustDialogAccepted": true,
      "projectOnboardingSeenCount": 1,
      "hasClaudeMdExternalIncludesApproved": false,
      "hasClaudeMdExternalIncludesWarningShown": false
    }
  },
  "oauthAccount": {
    "accountUuid": "00000000-0000-0000-0000-000000000001",
    "emailAddress": "container@claude-sdk.local",
    "organizationUuid": "00000000-0000-0000-0000-000000000002",
    "organizationRole": "admin",
    "workspaceRole": null,
    "organizationName": "AI SDK API"
  },
  "hasCompletedOnboarding": true,
  "lastOnboardingVersion": "1.0.117",
  "subscriptionNoticeCount": 0,
  "hasAvailableSubscription": true
}
EOF

# Set proper permissions
chmod 600 ~/.claude/.credentials.json 2>/dev/null || true
chmod 600 ~/.claude.json 2>/dev/null || true

echo "Authentication setup complete for $API_PROVIDER"
echo "Checking created files:"
ls -la ~/.claude/ 2>/dev/null || echo "Claude directory not accessible"
ls -la ~/ | grep claude 2>/dev/null || echo "Claude config not found"
echo "Credentials file size: $(stat -c%s ~/.claude/.credentials.json 2>/dev/null || echo 'N/A')"
echo "Config file size: $(stat -c%s ~/.claude.json 2>/dev/null || echo 'N/A')"

# Show configuration summary
echo ""
echo "=== AI SDK Configuration ==="
echo "Provider: $API_PROVIDER"
echo "Model: ${GLM_MODEL:-GLM-4.6}"
if [ -n "$BASE_URL" ]; then
    echo "API Base URL: $BASE_URL"
fi
echo "Token configured: $([ -n "$AUTH_TOKEN" ] && echo "✓" || echo "✗")"
echo "=============================="
echo ""

# Start the TypeScript server
echo "Starting TypeScript server with tsx..."
exec tsx server.ts