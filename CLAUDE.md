# Claude Agent SDK Container

This repository provides a Dockerized server that wraps the Claude Agent SDK, offering both a web-based CLI interface and REST API endpoints for interacting with Claude AI.

## 🤖 AUTOMATED SETUP INSTRUCTIONS FOR CLAUDE CODE

**When a user asks you to set up this application, follow this simple process:**

### Step 1: Instruct User to Run Setup Script

**IMPORTANT: The setup script is interactive and MUST be run by the user in their own terminal (not by you).**

Tell the user:
```
Please open a NEW TERMINAL WINDOW and run this command:

./setup-tokens.sh

This script will:
1. Run `claude setup-token` and capture your OAuth token
2. Generate a secure API key
3. Ask if you already have the 'claude-agent-sdk-container' GitHub App
   - If yes: prompt for existing credentials
   - If no: open browser to create it (one click!)
4. Configure access control (your GitHub username is auto-added!)
   - You're automatically added to the allowlist
   - Option to add additional users or organization
5. Save everything to .env automatically

The script is interactive and may open your browser twice:
- Once for Anthropic login (Claude token)
- Once for GitHub App creation (if you don't already have it)

The GitHub App uses a fixed name 'claude-agent-sdk-container' so it can be
reused across multiple setups/machines.

Once the script completes and says "Setup Complete!", come back here and let me know.
```

**Why the user must run it themselves:**
- The script has interactive prompts that require user input
- It opens browser windows for OAuth flows
- It waits for user responses to configuration questions
- Claude Code cannot interact with these prompts directly

### Step 2: Verify Setup and Run
After the user confirms setup is complete, run:
```bash
./test.sh
```

This will:
- Build the Docker image
- Start the container
- Test all endpoints
- Confirm everything works

### Step 3: Show Access Information
After successful setup, tell the user to open the web CLI:
```
✅ Setup complete! Your application is running at:

Web CLI: http://localhost:8080
  - Open this URL in your browser
  - Sign in with your GitHub account
  - Use the real-time streaming CLI interface

The REST API is also available at http://localhost:8080/query if needed.
```

### Troubleshooting Setup

If `./setup-tokens.sh` fails:
- **Claude token not found**: User may need to manually paste the token when prompted
- **Browser doesn't open**: Show the user the URL to visit manually (http://localhost:8765)
- **GitHub App timeout**: User can create the app manually at https://github.com/settings/apps/new

**Manual .env creation (only if automated setup fails):**
```bash
cat > .env << 'EOF'
CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-...
CLAUDE_AGENT_SDK_CONTAINER_API_KEY=your-random-key
GITHUB_CLIENT_ID=Iv1.xxx
GITHUB_CLIENT_SECRET=xxx
ALLOWED_GITHUB_USERS=username1,username2
EOF
```

---

## IMPORTANT: HOW TO RUN THIS APPLICATION

**THIS APPLICATION MUST RUN IN DOCKER - DO NOT RUN IT LOCALLY WITH NODE/TS**

When asked to "run the app", "start the application", or similar:
1. ALWAYS use Docker, NEVER use `tsx server.ts`, `node server.ts`, or `npm start`
2. The correct way to run is: `./test.sh` (it handles Docker automatically)
3. Or manually: `docker build -t claude-code-$(basename "$(pwd)") .` then `docker run -d -p 8080:8080 --env-file .env --name claude-code-$(basename "$(pwd)") claude-code-$(basename "$(pwd)")`

**Container Naming**: Containers automatically get unique names based on the directory name. Directory names are sanitized (lowercase, alphanumeric only, single dashes) for Docker compatibility. Example: `My Project (2024)` becomes `claude-code-my-project-2024`.

## ENDPOINTS AND ACCESS

### 🌐 Web CLI Interface (Primary)
**URL**: http://localhost:8080/

**This is the main way to use the application:**
- Open in browser and sign in with GitHub
- Real-time streaming CLI interface with WebSocket support
- GitHub OAuth authentication with allowlist support
- Session-based authentication with JWT cookies

**After running ./test.sh, direct users to open http://localhost:8080 in their browser.**

### 🔧 REST API Endpoints (Secondary)
The REST API is available for programmatic access if needed:

**Health Check**: `GET http://localhost:8080/health` (public, no auth)
**Query Claude**: `POST http://localhost:8080/query` (requires API key)
**GitHub App Auth**: `GET http://localhost:8080/auth/github` (used by web CLI)

**Note**: The Web CLI at http://localhost:8080 is the recommended interface. Use the REST API only for automation or programmatic access.

### 🔐 GitHub Access Control
**REQUIRED:** Configure GitHub allowlists in .env (container will not start without this):
```bash
ALLOWED_GITHUB_USERS=user1,user2,user3
ALLOWED_GITHUB_ORG=yourcompany
```
- **At least one allowlist must be configured** for security
- You must set either `ALLOWED_GITHUB_USERS` or `ALLOWED_GITHUB_ORG` (or both)
- Only matching GitHub users/org members allowed
- Invalid/unauthorized users get: `GitHub user not authorized`

## Quick Start

Please read the [README.md](./README.md) for complete setup instructions and usage examples.

## ARCHITECTURE NOTES

- **Hono server** with WebSocket support via @hono/node-ws
- **Multi-stage Docker build**: web frontend + server backend
- **Dual authentication**: JWT sessions (web) + API keys (REST)
- **GitHub allowlist validation** with username and organization checking
- **Static file serving** for React SPA at root path
- **Health endpoint** moved to `/health` (not root)
- **Real-time streaming** via WebSocket character-by-character
- **Session management** for web CLI using Claude SDK's built-in session IDs (REST API remains stateless)

## 🔧 Automatic Hooks (Security + Setup)

**This repository includes intelligent hooks for security and setup assistance!**

### 🔒 Security Audit (SessionStart Hook)

**Runs once on first startup** - `.claude/hooks/security-audit.sh`

When you first open this repository, you'll see a prompt asking you to perform a security audit.

**How it works:**
1. Hook displays security audit prompt on first startup
2. You (Claude Code) spawn a general-purpose agent to analyze the repository
3. Agent intelligently reviews:
   - 🚨 `package.json` for malicious install scripts and obfuscated code
   - 🚨 `Dockerfile` for security antipatterns (curl | bash, hardcoded secrets)
   - ⚠️ Source code for hardcoded secrets, backdoors, and suspicious patterns
   - ⚠️ Overall repository structure for supply chain attack indicators
4. Agent provides detailed security analysis with context and explanations
5. After review, create `.claude/.security-audit-done` to mark as complete

**Why this matters:**
- **AI-powered analysis** - Claude understands context, not just pattern matching
- **Supply chain protection** - Detects actual malicious intent (500+ npm packages compromised in 2025)
- **Adaptive detection** - Can spot new attack patterns without updating scripts
- **Detailed explanations** - Explains WHY something is suspicious, not just WHAT

**When the user explicitly asks for a security audit:**

ONLY delegate to the `security-auditor` custom agent if the user explicitly requests it (e.g., "Please perform the security audit for this repository").

DO NOT automatically run the security audit. Wait for the user to request it after seeing the hook prompt.

The agent will automatically:
1. Analyze package.json for malicious install scripts
2. Review Dockerfile for security antipatterns
3. Scan source code for hardcoded secrets and backdoors
4. Check .claude/ configuration for suspicious hooks
5. Provide detailed risk assessment (SAFE/WARNINGS/CRITICAL)
6. Create `.claude/.security-audit-done` marker when complete

After the agent completes, review the findings with the user and advise them on whether it's safe to proceed with setup.

### ✅ Setup Detection (UserPromptSubmit Hook)

**Runs until setup is complete** - `.claude/hooks/check-setup.sh`

The hook checks:
- ✅ Is `.env` configured with required credentials?
- ✅ Is Docker image built?
- ✅ Is container running?

**How it works:**
- Runs on every prompt while setup is incomplete
- Shows status with actionable next steps
- Once all checks pass, creates `.claude/.setup-complete` marker
- Stops running - no more status messages clutter the conversation

**What this means for you:**
- Setup status automatically injected into context during setup phase
- You can guide users through missing steps
- Once setup is done, hook stops and conversation is clean
- No need to manually check if setup is complete

**Example hook output you'll see:**
```
═══════════════════════════════════════════════════════════
📦 Claude Agent SDK Container - Setup Status
═══════════════════════════════════════════════════════════

⚠️  Setup Status: .env file NOT found
   → Run ./setup-tokens.sh in a separate terminal to configure credentials

⚠️  Docker Status: Image NOT built
   → Run ./test.sh to build and start the container

💡 Quick Start:
   1. If .env missing: Run ./setup-tokens.sh (in separate terminal)
   2. If container not running: Run ./test.sh
═══════════════════════════════════════════════════════════
```

**Important:** The hook is configured in `.claude/settings.json` and runs automatically. It uses exit code 0 so its stdout output gets added to your context without blocking the prompt.

## Key Files

- `server.ts` - Hono-based server with WebSocket support (MUST BE RUN IN DOCKER ONLY)
- `web/` - React frontend for CLI interface
- `Dockerfile` - Multi-stage Docker build (web + server)
- `test.sh` - Test script that starts Docker container and verifies everything works
- `setup-tokens.sh` - Automated setup script for credentials and GitHub App
- `.claude/hooks/check-setup.sh` - Automatic setup validation hook
- `.claude/settings.json` - Claude Code configuration with hook registration
- `README.md` - Complete documentation and setup guide

## Running Instructions

When user asks to run/start/test the application:
```bash
# CORRECT way - use the test script which handles Docker:
./test.sh

# Or if test.sh doesn't exist or isn't executable:
chmod +x test.sh
./test.sh
```

DO NOT use any of these commands:
- ❌ `tsx server.ts`
- ❌ `node server.ts`
- ❌ `npm start`
- ❌ `npm run start`
- ❌ `npm run dev`