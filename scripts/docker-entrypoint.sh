#!/bin/sh

# Setup authentication for Claude SDK
if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
  echo "Setting up Claude SDK authentication..."
  echo "Token length: ${#CLAUDE_CODE_OAUTH_TOKEN}"

  # Create .claude directory
  mkdir -p ~/.claude
  echo "Created ~/.claude directory"

  # Create .credentials.json with far future expiry (Alpine-compatible)
  EXPIRY_DATE=$(date -u -d "@$(($(date +%s) + 315360000))" +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%S.000Z)
  cat > ~/.claude/.credentials.json << EOF
{
  "claudeAiOauth": {
    "accessToken": "$CLAUDE_CODE_OAUTH_TOKEN",
    "refreshToken": "$CLAUDE_CODE_OAUTH_TOKEN",
    "expiresAt": "$EXPIRY_DATE",
    "scopes": ["read", "write"],
    "subscriptionType": "pro"
  }
}
EOF

  # Create .claude.json
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
    "organizationName": "Claude SDK API"
  },
  "hasCompletedOnboarding": true,
  "lastOnboardingVersion": "1.0.117",
  "subscriptionNoticeCount": 0,
  "hasAvailableSubscription": true
}
EOF

  chmod 600 ~/.claude/.credentials.json
  chmod 600 ~/.claude.json

  echo "Authentication setup complete"
  echo "Checking created files:"
  ls -la ~/.claude/
  ls -la ~/ | grep claude
  echo "Credentials file size: $(stat -c%s ~/.claude/.credentials.json 2>/dev/null || echo 'N/A')"
  echo "Config file size: $(stat -c%s ~/.claude.json 2>/dev/null || echo 'N/A')"
fi

# Start the TypeScript server
echo "Starting TypeScript server with tsx..."
exec tsx server.ts