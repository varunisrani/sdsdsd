# Claude Code SDK Container

This repository provides a Dockerized API server that wraps the Claude Code SDK, allowing you to interact with Claude AI through HTTP endpoints instead of requiring local CLI installation.

## IMPORTANT: HOW TO RUN THIS APPLICATION

**THIS APPLICATION MUST RUN IN DOCKER - DO NOT RUN IT LOCALLY WITH NODE**

When asked to "run the app", "start the application", or similar:
1. ALWAYS use Docker, NEVER use `node src/index.mjs` or `npm start`
2. The correct way to run is: `./test.sh` (it handles Docker automatically)
3. Or manually: `docker build -t claude-code-sdk .` then `docker run -d -p 8080:8080 --env-file .env claude-code-sdk`

## HOW TO QUERY THE API ENDPOINT

When calling the containerized Claude SDK API, use this exact format to avoid curl issues:

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
- Provides REST API endpoints for health checks and querying Claude
- Handles authentication via OAuth tokens and optional API key protection
- Enables Claude AI access from any programming language or platform via HTTP

## Key Files

- `src/index.mjs` - Express.js API server (MUST BE RUN IN DOCKER ONLY)
- `Dockerfile` - Multi-stage Docker build configuration
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
- ❌ `node src/index.mjs`
- ❌ `npm start`
- ❌ `npm run start`
- ❌ `cd src && npm start`