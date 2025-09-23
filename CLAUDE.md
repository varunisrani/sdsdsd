# Claude Code SDK Container

This repository provides a Dockerized server that wraps the Claude Code SDK, offering both a web-based CLI interface and REST API endpoints for interacting with Claude AI.

## IMPORTANT: HOW TO RUN THIS APPLICATION

**THIS APPLICATION MUST RUN IN DOCKER - DO NOT RUN IT LOCALLY WITH NODE/TS**

When asked to "run the app", "start the application", or similar:
1. ALWAYS use Docker, NEVER use `tsx server.ts`, `node server.ts`, or `npm start`
2. The correct way to run is: `./test.sh` (it handles Docker automatically)
3. Or manually: `docker build -t claude-code-sdk .` then `docker run -d -p 8080:8080 --env-file .env claude-code-sdk`

## TWO WAYS TO USE CLAUDE

### 1. 🌐 Web CLI Interface (NEW!)
Visit http://localhost:8080 in your browser:
- Enter your email address
- Receive a magic link via email (using Resend)
- Click the link to authenticate
- Use the interactive CLI with real-time streaming responses

### 2. 🔧 REST API (Original)
Use curl or any HTTP client to query Claude programmatically:

```bash
# Get the API key from the .env file first:
API_KEY=$(grep CLAUDE_CODE_SDK_CONTAINER_API_KEY .env | cut -d '=' -f2)

# CORRECT - Single line without backslashes:
curl -X POST http://localhost:8080/query -H "Content-Type: application/json" -H "X-API-Key: $API_KEY" -d '{"prompt": "Your question here"}'

# To extract just the response text:
curl -X POST http://localhost:8080/query -H "Content-Type: application/json" -H "X-API-Key: $API_KEY" -d '{"prompt": "Your question here"}' -s | jq -r '.response'
```

**DO NOT use multi-line curl commands with backslashes** - they cause issues with the Bash tool.

## Quick Start

Please read the [README.md](./README.md) for complete setup instructions and usage examples.

## What This Does

- Containerizes the Claude Code SDK for deployment anywhere Docker runs
- Provides a web-based CLI interface with email magic link authentication
- Provides REST API endpoints for health checks and querying Claude
- Handles dual authentication: magic links for web CLI, API keys for REST API
- Enables Claude AI access via interactive web interface or programmatic HTTP calls
- Real-time streaming responses via WebSocket for CLI interface

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