# Claude Agent SDK Container

This repository provides a Dockerized server that wraps the Claude Agent SDK, offering both a web-based CLI interface and REST API endpoints for interacting with Claude AI.

## IMPORTANT: HOW TO RUN THIS APPLICATION

**THIS APPLICATION MUST RUN IN DOCKER - DO NOT RUN IT LOCALLY WITH NODE/TS**

When asked to "run the app", "start the application", or similar:
1. ALWAYS use Docker, NEVER use `tsx server.ts`, `node server.ts`, or `npm start`
2. The correct way to run is: `./test.sh` (it handles Docker automatically)
3. Or manually: `docker build -t claude-code-$(basename "$(pwd)") .` then `docker run -d -p 8080:8080 --env-file .env --name claude-code-$(basename "$(pwd)") claude-code-$(basename "$(pwd)")`

**Container Naming**: Containers automatically get unique names based on the directory name (e.g., `claude-code-my-project`) to prevent conflicts across multiple deployments.

## ENDPOINTS AND ACCESS

### 🌐 Web CLI Interface
**URL**: http://localhost:8080/ (root path serves React SPA)
- GitHub OAuth authentication with allowlist support
- Real-time WebSocket streaming at /ws
- JWT session cookies for authentication

### 🔧 REST API Endpoints
**Health Check**: `GET http://localhost:8080/health` (public, no auth)
**Query Claude**: `POST http://localhost:8080/query` (requires API key if configured)
**GitHub App Auth**: `GET http://localhost:8080/auth/github` (web CLI authentication)

```bash
# CORRECT - Use separate commands, NOT command substitution in Bash tool:

# First, get the API key:
grep CLAUDE_AGENT_SDK_CONTAINER_API_KEY .env | cut -d '=' -f2

# Then use the actual key value in curl (replace YOUR_ACTUAL_KEY):
curl -X POST http://localhost:8080/query -H "Content-Type: application/json" -H "X-API-Key: YOUR_ACTUAL_KEY" -d '{"prompt": "Your question here"}'

# To extract just the response text:
curl -X POST http://localhost:8080/query -H "Content-Type: application/json" -H "X-API-Key: YOUR_ACTUAL_KEY" -d '{"prompt": "Your question here"}' -s | jq -r '.response'
```

**IMPORTANT BASH TOOL RULES:**
- **DO NOT use command substitution** like `$(command)` or backticks in Bash tool
- **DO NOT use multi-line commands** with backslashes
- **Use separate Bash calls** for each command
- **Always use single quotes** around JSON to prevent shell interpretation

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

## Key Files

- `server.ts` - Hono-based server with WebSocket support (MUST BE RUN IN DOCKER ONLY)
- `web/` - React frontend for CLI interface
- `Dockerfile` - Multi-stage Docker build (web + server)
- `test.sh` - Test script that starts Docker container and verifies everything works
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