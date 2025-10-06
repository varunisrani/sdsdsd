#!/bin/sh

echo "🚀 Starting GLM-4.6 Container with Authentication Setup..."

# Show environment variables for debugging
echo "Environment variables:"
echo "ANTHROPIC_AUTH_TOKEN present: $(if [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then echo "✓"; else echo "✗"; fi)"
echo "ANTHROPIC_BASE_URL: ${ANTHROPIC_BASE_URL:-'not set'}"
echo "CLAUDE_CODE_OAUTH_TOKEN present: $(if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then echo "✓"; else echo "✗"; fi)"

# Setup Claude SDK environment for GLM-4.6 compatibility
if [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
    echo "🔧 Setting up GLM-4.6 authentication..."

    # Method 1: Set ANTHROPIC_API_KEY (new format)
    export ANTHROPIC_API_KEY="$ANTHROPIC_AUTH_TOKEN"

    # Method 2: Set CLAUDE_API_KEY (alternative)
    export CLAUDE_API_KEY="$ANTHROPIC_AUTH_TOKEN"

    # Method 3: Keep legacy token
    export CLAUDE_CODE_OAUTH_TOKEN="$ANTHROPIC_AUTH_TOKEN"

    # Method 4: Set base URL
    if [ -n "$ANTHROPIC_BASE_URL" ]; then
        export ANTHROPIC_BASE_URL="$ANTHROPIC_BASE_URL"
    else
        export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
    fi

    echo "✅ Authentication setup complete"
    echo "   API Key: ${ANTHROPIC_AUTH_TOKEN:0:20}..."
    echo "   Base URL: $ANTHROPIC_BASE_URL"

    # Create Claude credentials file
    mkdir -p ~/.claude
    cat > ~/.claude/.credentials.json << EOF
{
  "claudeAiOauth": {
    "accessToken": "$ANTHROPIC_AUTH_TOKEN",
    "refreshToken": "$ANTHROPIC_AUTH_TOKEN",
    "expiresAt": "2099-12-31T23:59:59.000Z",
    "scopes": ["read", "write"],
    "subscriptionType": "pro"
  }
}
EOF

    # Create Claude config file
    cat > ~/.claude.json << EOF
{
  "numStartups": 1,
  "installMethod": "docker",
  "autoUpdates": true,
  "firstStartTime": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
  "userID": "render-user",
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
    "emailAddress": "render@glm-sdk.local",
    "organizationUuid": "00000000-0000-0000-0000-000000000002",
    "organizationRole": "admin",
    "workspaceRole": null,
    "organizationName": "GLM-4.6 SDK"
  },
  "hasCompletedOnboarding": true,
  "lastOnboardingVersion": "1.0.117",
  "subscriptionNoticeCount": 0,
  "hasAvailableSubscription": true
}
EOF

    chmod 600 ~/.claude/.credentials.json 2>/dev/null || true
    chmod 600 ~/.claude.json 2>/dev/null || true

    echo "📁 Claude SDK credentials created"
else
    echo "❌ No ANTHROPIC_AUTH_TOKEN found!"
    exit 1
fi

echo ""
echo "🔍 Final environment setup:"
echo "ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:0:20}..."
echo "CLAUDE_API_KEY: ${CLAUDE_API_KEY:0:20}..."
echo "CLAUDE_CODE_OAUTH_TOKEN: ${CLAUDE_CODE_OAUTH_TOKEN:0:20}..."
echo "ANTHROPIC_BASE_URL: $ANTHROPIC_BASE_URL"
echo ""

echo "🚀 Starting GLM-4.6 server..."
exec tsx server.ts