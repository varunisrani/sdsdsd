#!/bin/bash

# Test script for Claude Code SDK Container
# This helps verify everything is working correctly

set -e

echo "🔍 Claude Code SDK Container Test Script"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ ERROR: .env file not found${NC}"
    echo "Please create .env file first:"
    echo "  cp .env.example .env"
    echo "  # Then edit .env with your actual tokens (no quotes!)"
    exit 1
fi

# Load env vars safely
set -a
source .env
set +a

# Check if tokens are set
if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo -e "${RED}❌ ERROR: CLAUDE_CODE_OAUTH_TOKEN not set in .env${NC}"
    exit 1
fi

if [ -z "$CLAUDE_CODE_SDK_CONTAINER_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  WARNING: CLAUDE_CODE_SDK_CONTAINER_API_KEY not set - API will be public${NC}"
fi

echo "✅ Environment variables loaded"
echo ""

# First check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker is not running.${NC}"

    # Try to start Docker Desktop on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Attempting to start Docker Desktop..."
        open -a Docker 2>/dev/null || echo -e "${YELLOW}Could not auto-start Docker Desktop${NC}"

        # Wait for Docker to start
        echo "Waiting for Docker to start (up to 30 seconds)..."
        for i in {1..30}; do
            if docker info > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Docker started successfully${NC}"
                break
            fi
            sleep 1
        done
    fi

    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running. Please start Docker manually.${NC}"
        exit 1
    fi
fi

# Check if image exists, build if not
if ! docker images | grep -q "claude-code-sdk"; then
    echo -e "${YELLOW}⚠️  Docker image not found. Building now...${NC}"
    if docker build -t claude-code-sdk .; then
        echo -e "${GREEN}✅ Docker image built successfully${NC}"
    else
        echo -e "${RED}❌ Failed to build Docker image${NC}"
        exit 1
    fi
fi

# Check if container is running
echo "Checking container status..."
if docker ps | grep -q claude-code-sdk-container; then
    echo -e "${GREEN}✅ Container is running${NC}"
else
    # Remove old container if it exists but is stopped
    if docker ps -a | grep -q claude-code-sdk-container; then
        echo "Removing stopped container..."
        docker rm claude-code-sdk-container > /dev/null 2>&1
    fi

    echo -e "${YELLOW}⚠️  Container not running. Starting it now...${NC}"
    if docker run -d --name claude-code-sdk-container -p 8080:8080 --env-file .env claude-code-sdk; then
        echo "Waiting for container to start..."
        sleep 3

        # Verify it's still running
        if ! docker ps | grep -q claude-code-sdk-container; then
            echo -e "${RED}❌ Container stopped unexpectedly. Checking logs:${NC}"
            docker logs claude-code-sdk-container
            exit 1
        fi
    else
        echo -e "${RED}❌ Failed to start container${NC}"
        exit 1
    fi
fi
echo ""

# Test health endpoint
echo "Testing health endpoint (no auth required)..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/ 2>/dev/null || echo "FAILED")

if [[ "$HEALTH_RESPONSE" == "FAILED" ]]; then
    echo -e "${RED}❌ Health check failed - is port 8080 in use?${NC}"
    echo "Debug: Check container logs with: docker logs claude-code-sdk-container"
    exit 1
fi

if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
    echo -e "${GREEN}✅ Health check passed${NC}"
    echo "Response: $HEALTH_RESPONSE"
else
    echo -e "${YELLOW}⚠️  Health check returned unhealthy${NC}"
    echo "Response: $HEALTH_RESPONSE"
    echo "Check your CLAUDE_CODE_OAUTH_TOKEN"
fi
echo ""

# Test query endpoint
echo "Testing query endpoint (requires API key)..."
if [ -n "$CLAUDE_CODE_SDK_CONTAINER_API_KEY" ]; then
    QUERY_RESPONSE=$(curl -s -X POST http://localhost:8080/query \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $CLAUDE_CODE_SDK_CONTAINER_API_KEY" \
        -d '{"prompt": "Say hello in 3 words"}' 2>/dev/null || echo "FAILED")
else
    QUERY_RESPONSE=$(curl -s -X POST http://localhost:8080/query \
        -H "Content-Type: application/json" \
        -d '{"prompt": "Say hello in 3 words"}' 2>/dev/null || echo "FAILED")
fi

if [[ "$QUERY_RESPONSE" == "FAILED" ]]; then
    echo -e "${RED}❌ Query failed - connection error${NC}"
    exit 1
elif echo "$QUERY_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Query successful!${NC}"
    echo "Response excerpt: $(echo "$QUERY_RESPONSE" | head -c 200)..."
elif echo "$QUERY_RESPONSE" | grep -q "Unauthorized"; then
    echo -e "${RED}❌ Authentication failed - check your API key${NC}"
    echo "Response: $QUERY_RESPONSE"
    exit 1
else
    echo -e "${RED}❌ Query failed${NC}"
    echo "Response: $QUERY_RESPONSE"
    exit 1
fi
echo ""

echo "========================================"
echo -e "${GREEN}🎉 All tests passed! Container is working correctly.${NC}"
echo ""
echo "Try it out by asking Claude to hit the SDK endpoint with a question:"
echo ""
echo "Example: \"How far is it from Sydney to London?\""
echo ""
echo "This will use the Claude Code SDK running in Docker (not Claude Code on your local machine)"
echo "to make an API call to Claude and return the response."
echo ""
if [ -n "$CLAUDE_CODE_SDK_CONTAINER_API_KEY" ]; then
    echo "curl -X POST http://localhost:8080/query \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -H \"X-API-Key: YOUR_API_KEY_HERE\" \\"
    echo "  -d '{\"prompt\": \"How far is it from Sydney to London?\"}'"
else
    echo "curl -X POST http://localhost:8080/query \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '{\"prompt\": \"How far is it from Sydney to London?\"}'"
fi
echo ""
echo "To update to the latest version of Claude Code SDK, run:"
echo "  ./update.sh"