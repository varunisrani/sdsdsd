#!/bin/bash

# Update script for Claude Code SDK Container
# Updates the SDK to latest version and rebuilds container

set -e

echo "🔄 Claude Code SDK Container Update Script"
echo "==========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check current version
echo "Checking current Claude Code SDK version..."
CURRENT_VERSION=$(grep '"@anthropic-ai/claude-code"' package.json | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
echo -e "Current version: ${BLUE}$CURRENT_VERSION${NC}"
echo ""

# Get container name from directory
CONTAINER_NAME="claude-code-$(basename "$(pwd)")"
IMAGE_NAME="claude-code-$(basename "$(pwd)")"

# Check if container exists
CONTAINER_EXISTS=$(docker ps -a --format "table {{.Names}}" | grep -c "$CONTAINER_NAME" || true)
CONTAINER_RUNNING=$(docker ps --format "table {{.Names}}" | grep -c "$CONTAINER_NAME" || true)

# Update packages
echo "Fetching latest version from npm..."
LATEST_VERSION=$(npm view @anthropic-ai/claude-code version 2>/dev/null || echo "")

if [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}❌ Could not fetch latest version from npm${NC}"
    exit 1
fi

echo -e "Latest version: ${GREEN}$LATEST_VERSION${NC}"
echo ""

# Check if update is needed
if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo -e "${GREEN}✅ Already on latest version!${NC}"
    echo ""
    read -p "Do you want to rebuild anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting without changes."
        exit 0
    fi
else
    echo -e "${YELLOW}📦 Update available: $CURRENT_VERSION → $LATEST_VERSION${NC}"
    echo ""
fi

# Update package
echo "Updating Claude Code SDK..."
npm update @anthropic-ai/claude-code
echo -e "${GREEN}✅ Package updated${NC}"
echo ""

# Build new image
echo "Building new Docker image..."
docker build -t "$IMAGE_NAME" . || {
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
}
echo -e "${GREEN}✅ Docker image built${NC}"
echo ""

# Handle existing container
if [ "$CONTAINER_RUNNING" -eq 1 ]; then
    echo "Stopping running container..."
    docker stop "$CONTAINER_NAME"
    echo -e "${GREEN}✅ Container stopped${NC}"
fi

if [ "$CONTAINER_EXISTS" -eq 1 ]; then
    echo "Removing old container..."
    docker rm "$CONTAINER_NAME"
    echo -e "${GREEN}✅ Old container removed${NC}"
fi
echo ""

# Start new container
echo "Starting new container..."
if [ -f .env ]; then
    docker run -d --name "$CONTAINER_NAME" -p 8080:8080 --env-file .env "$IMAGE_NAME"
    echo -e "${GREEN}✅ Container started with .env file${NC}"
else
    echo -e "${YELLOW}⚠️  No .env file found, starting with environment variables${NC}"
    docker run -d --name "$CONTAINER_NAME" -p 8080:8080 "$IMAGE_NAME"
fi
echo ""

# Wait for container to be ready
echo "Waiting for container to be ready..."
sleep 3

# Test health endpoint
echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/health 2>/dev/null || echo "FAILED")

if [[ "$HEALTH_RESPONSE" == "FAILED" ]]; then
    echo -e "${RED}❌ Health check failed${NC}"
    echo "Check logs with: docker logs $CONTAINER_NAME"
    exit 1
elif echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
    echo -e "${GREEN}✅ Container is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Container started but may not be healthy${NC}"
    echo "Response: $HEALTH_RESPONSE"
fi
echo ""

# Show final status
NEW_VERSION=$(grep '"@anthropic-ai/claude-code"' package.json | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
echo "==========================================="
echo -e "${GREEN}🎉 Update complete!${NC}"
echo -e "Version: ${GREEN}$NEW_VERSION${NC}"
echo ""
echo "Container status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$CONTAINER_NAME" || echo "Not running"
echo ""
echo "Test with: ./test.sh"