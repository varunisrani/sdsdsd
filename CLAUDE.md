# Claude Code SDK Container

This repository provides a Dockerized server that wraps the Claude Code SDK, offering both a web-based CLI interface and REST API endpoints for interacting with Claude AI.

## IMPORTANT: HOW TO RUN THIS APPLICATION

**THIS APPLICATION MUST RUN IN DOCKER - DO NOT RUN IT LOCALLY WITH NODE/TS**

When asked to "run the app", "start the application", or similar:
1. ALWAYS use Docker, NEVER use `tsx server.ts`, `node server.ts`, or `npm start`
2. The correct way to run is: `./test.sh` (it handles Docker automatically)
3. Or manually: `docker build -t claude-code-sdk .` then `docker run -d -p 8080:8080 --env-file .env claude-code-sdk`

## ENDPOINTS AND ACCESS

### 🌐 Web CLI Interface
**URL**: http://localhost:8080/ (root path serves React SPA)
- Magic link email authentication with allowlist support
- Real-time WebSocket streaming at /ws
- JWT session cookies for authentication

### 🔧 REST API Endpoints
**Health Check**: `GET http://localhost:8080/health` (public, no auth)
**Query Claude**: `POST http://localhost:8080/query` (requires API key if configured)

```bash
# Get the API key from the .env file first:
API_KEY=$(grep CLAUDE_CODE_SDK_CONTAINER_API_KEY .env | cut -d '=' -f2)

# CORRECT - Single line without backslashes:
curl -X POST http://localhost:8080/query -H "Content-Type: application/json" -H "X-API-Key: $API_KEY" -d '{"prompt": "Your question here"}'

# To extract just the response text:
curl -X POST http://localhost:8080/query -H "Content-Type: application/json" -H "X-API-Key: $API_KEY" -d '{"prompt": "Your question here"}' -s | jq -r '.response'
```

**DO NOT use multi-line curl commands with backslashes** - they cause issues with the Bash tool.

### 🔐 Email Access Control
Configure email allowlists in .env:
```bash
ALLOWED_EMAILS=user1@company.com,user2@company.com
ALLOWED_DOMAINS=company.com,partner.org
```
- If neither is set: any valid email can access web CLI
- If either is set: only matching emails/domains allowed
- Invalid/unauthorized emails get: `{"error":"Email address not allowed"}`

## Quick Start

Please read the [README.md](./README.md) for complete setup instructions and usage examples.

## ARCHITECTURE NOTES

- **Hono server** with WebSocket support via @hono/node-ws
- **Multi-stage Docker build**: web frontend + server backend
- **Dual authentication**: JWT sessions (web) + API keys (REST)
- **Email allowlist validation** with regex format checking
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