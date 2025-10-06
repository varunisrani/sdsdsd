#!/bin/bash

# Test script for Claude Agent SDK Container
# This helps verify everything is working correctly

set -e

echo "Testing Claude Agent SDK Container..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    echo "Create .env file first: cp .env.example .env"
    exit 1
fi

# Load env vars safely
set -a
source .env
set +a

# Check if tokens are set (GLM-4.6 or Claude)
if [ -z "$ANTHROPIC_AUTH_TOKEN" ] && [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo "Error: ANTHROPIC_AUTH_TOKEN or CLAUDE_CODE_OAUTH_TOKEN not set in .env"
    exit 1
fi

# Determine which AI provider is configured
if [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
    AI_PROVIDER="GLM-4.6"
    echo "Using GLM-4.6 AI provider"
else
    AI_PROVIDER="Claude"
    echo "Using Claude AI provider"
fi

echo "Environment loaded"

if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker."
    exit 1
fi

# Get container name from directory (sanitize: lowercase, alphanumeric only, single dashes)
DIR_NAME=$(basename "$(pwd)")
DIR_NAME_SAFE=$(echo "$DIR_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/-\+/-/g; s/^-//; s/-$//')
CONTAINER_NAME="claude-code-${DIR_NAME_SAFE}"
IMAGE_NAME="claude-code-${DIR_NAME_SAFE}"

if ! docker images | grep -q "$IMAGE_NAME"; then
    echo "Building Docker image..."
    docker build -t "$IMAGE_NAME" . || exit 1
fi

if ! docker ps | grep -q "$CONTAINER_NAME"; then
    docker ps -a | grep -q "$CONTAINER_NAME" && docker rm "$CONTAINER_NAME" > /dev/null 2>&1
    echo "Starting container..."
    docker run -d --name "$CONTAINER_NAME" -p 8080:8080 --env-file .env "$IMAGE_NAME" || exit 1
    sleep 3
fi

echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/health 2>/dev/null || echo "FAILED")

if [[ "$HEALTH_RESPONSE" == "FAILED" ]]; then
    echo "Health check failed"
    exit 1
fi

if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
    echo "Health check passed - $AI_PROVIDER is responding"
else
    echo "Health check unhealthy - check AI provider token"
    echo "Provider: $AI_PROVIDER"
fi

echo "Testing query endpoint..."
if [ -n "$CLAUDE_AGENT_SDK_CONTAINER_API_KEY" ]; then
    QUERY_RESPONSE=$(curl -s -X POST http://localhost:8080/query \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $CLAUDE_AGENT_SDK_CONTAINER_API_KEY" \
        -d '{"prompt": "Say hello in 3 words"}' 2>/dev/null || echo "FAILED")
else
    QUERY_RESPONSE=$(curl -s -X POST http://localhost:8080/query \
        -H "Content-Type: application/json" \
        -d '{"prompt": "Say hello in 3 words"}' 2>/dev/null || echo "FAILED")
fi

if [[ "$QUERY_RESPONSE" == "FAILED" ]]; then
    echo "Query failed"
    exit 1
elif echo "$QUERY_RESPONSE" | grep -q '"success":true'; then
    echo "Query successful"
else
    echo "Query failed: $QUERY_RESPONSE"
    exit 1
fi

echo "All tests passed!"
echo "🎉 $AI_PROVIDER container is running successfully!"
echo "Web CLI: http://localhost:8080"
echo "API: POST http://localhost:8080/query"
echo ""
echo "💡 Note: You're using $AI_PROVIDER as the AI provider"