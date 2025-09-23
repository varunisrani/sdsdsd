# Claude Code SDK Container

**Deploy Claude Code to your favorite cloud provider and use it just like Claude Code on your desktop!**

This repository containerizes Claude Code, allowing you to run it with your Anthropic subscription on AWS, Google Cloud, Azure, or any cloud platform that supports Docker. Once deployed, you can interact with Claude Code through a REST API from any application or service!

Since you're here, we expect you already have Claude Code installed and are loving it as much as we are. But if you haven't installed it yet, you can get started here: [Claude Code Installation Guide](https://docs.claude.com/en/docs/claude-code/overview)

> 🔒 **Security Note**: This container exposes Claude AI with tools through an HTTP API. Like any AI integration, be mindful of prompt injection when handling untrusted input. Learn more about this important topic from [Simon Willison's articles on prompt injection](https://simonwillison.net/tags/prompt-injection/).

## ✨ Features

### 🌐 **Dual Access Modes**
- **Web CLI Interface**: Interactive browser-based terminal with real-time streaming
- **REST API**: Programmatic access for applications and integrations

### 🔐 **Security & Access Control**
- **GitHub OAuth Authentication**: Simple one-click GitHub login for web CLI
- **API Key Protection**: Secure REST API access with configurable API keys
- **GitHub Allowlisting**: Control web CLI access by GitHub usernames or organizations
- **JWT Session Management**: Secure cookie-based sessions with expiration

### 🔧 **GitHub Integration**
- **OAuth2 Flow**: Standard GitHub OAuth for seamless authentication
- **Organization Support**: Restrict access by GitHub organization membership
- **User Allowlists**: Fine-grained control with specific GitHub usernames

### 🚀 **Production Ready**
- **Docker-First**: Optimized multi-stage build for cloud deployment
- **Health Monitoring**: Built-in health checks and status endpoints
- **Graceful Shutdown**: Proper signal handling for container orchestration
- **Comprehensive Logging**: Detailed startup and access control logging

### 🛠️ **Developer Experience**
- **Real-time Streaming**: Character-by-character CLI response streaming
- **Multiple Models**: Support for Claude Sonnet 4.0 and Opus 4.1
- **Backward Compatible**: Preserves existing REST API functionality
- **Auto-testing**: Comprehensive test script validates full functionality

**🚨 STOP! Only FIVE manual steps required:**

## 📋 Five-Step Setup (DO THIS YOURSELF)

### Step 1: Clone This Repo
```bash
git clone https://github.com/receipting/claude-code-sdk-container
cd claude-code-sdk-container
```

### Step 2: Get Your Claude OAuth Token

```bash
claude setup-token
```

This opens a browser to login to Anthropic.

After login, the token appears in your terminal.

COPY IT NOW - you can't get it again!

### Step 3: Create GitHub OAuth App

Go to [GitHub Settings > Developer settings > OAuth Apps](https://github.com/settings/applications/new){:target="_blank"} and create a new OAuth App:

- **Application name**: `Claude CLI Container` (or your preferred name)
- **Homepage URL**: `http://localhost:8080`
- **Authorization callback URL**: `http://localhost:8080/auth/github`

Copy the **Client ID** and **Client Secret** for the next step.

### Step 4: Create .env File in This Directory

```bash
cat > .env << 'EOF'
CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-YOUR-TOKEN-HERE
CLAUDE_CODE_SDK_CONTAINER_API_KEY=pick-any-random-string-as-your-api-key

# GitHub OAuth Configuration (Required for web CLI)
GITHUB_CLIENT_ID=your_github_app_client_id
GITHUB_CLIENT_SECRET=your_github_app_client_secret

# Required: GitHub access control for web CLI (choose one or both)
ALLOWED_GITHUB_USERS=user1,user2,user3
# ALLOWED_GITHUB_ORG=yourcompany
EOF
```

**Required:**
- **CLAUDE_CODE_OAUTH_TOKEN**: Your Claude Code OAuth token
- **CLAUDE_CODE_SDK_CONTAINER_API_KEY**: API key for REST endpoint protection
- **GITHUB_CLIENT_ID**: GitHub OAuth App Client ID
- **GITHUB_CLIENT_SECRET**: GitHub OAuth App Client Secret

**Required GitHub Access Control (for security):**
- **ALLOWED_GITHUB_USERS**: Comma-separated list of GitHub usernames allowed to access web CLI
- **ALLOWED_GITHUB_ORG**: GitHub organization name (users from this org can access web CLI)

**GitHub Access Behavior:**
- **At least one allowlist must be configured** - the container will not start without proper access control
- You must set either `ALLOWED_GITHUB_USERS` or `ALLOWED_GITHUB_ORG` (or both)
- This prevents unauthorized access to your Claude instance

### Step 5: Start Claude Code

Start Claude Code FROM INSIDE this directory

```bash
claude
```

## 🤖 Now Let Claude Code Do Everything Else!

**That's it! Now just tell Claude Code (which you already have running):**

Claude Code will handle all the Docker commands, testing, and setup for you.

### Example Claude Code Prompt:
```
I've created the .env file with my tokens.
Please build the Docker container, run it, and verify it's working by testing the API endpoints.
```

### What Claude Code Will Do:
- ✅ Build the Docker container
- ✅ Run the container with your .env file
- ✅ Test both health and query endpoints
- ✅ Show you working curl commands to use
- ✅ Fix any issues that come up

---

<details>

<summary>☁️ Deployment Options - Let Claude Code deploy this for you!</summary>

| Platform             | Service                              | “Deploy a Dockerized app” docs                                                                                                                                                                                                                  |
| -------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AWS                  | App Runner                           | [Getting started with App Runner](https://docs.aws.amazon.com/apprunner/latest/dg/getting-started.html)                                                                                                                                         |
| AWS                  | Amazon ECS (Fargate)                 | [Getting started with Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/getting-started-fargate.html)                                                                                                                        |
| AWS                  | Elastic Beanstalk (Docker)           | [Deploying with Docker containers](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create_deploy_docker.html)                                                                                                                            |
| AWS                  | Lightsail Containers                 | [Deploy and manage containers](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-container-services.html)                                                                                                                 |
| Google Cloud         | Cloud Run                            | [Deploying container images to Cloud Run](https://cloud.google.com/run/docs/deploying)                                                                                                                                                          |
| Google Cloud         | Google Kubernetes Engine (GKE)       | [Quickstart: Deploy an app to a GKE cluster](https://cloud.google.com/kubernetes-engine/docs/deploy-app-cluster)                                                                                                                                |
| Google Cloud         | App Engine Flexible (custom runtime) | [Build custom runtimes (Dockerfile)](https://cloud.google.com/appengine/docs/flexible/custom-runtimes/build)                                                                                                                                    |
| Azure                | Container Apps                       | [Quickstart: Deploy your first container app](https://learn.microsoft.com/en-us/azure/container-apps/get-started) • [Deploy existing image](https://learn.microsoft.com/en-us/azure/container-apps/get-started-existing-container-image-portal) |
| Azure                | App Service (Web App for Containers) | [Quickstart: Run a custom container on App Service](https://learn.microsoft.com/en-us/azure/app-service/quickstart-custom-container)                                                                                                            |
| Azure                | Container Instances (ACI)            | [Quickstart: Deploy a container instance](https://learn.microsoft.com/en-us/azure/container-instances/container-instances-quickstart-portal)                                                                                                    |
| Azure                | AKS (Kubernetes)                     | [Quickstart: Deploy an AKS cluster & app (CLI)](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli)                                                                                                                  |
| Fly.io               | Machines / Launch                    | [Deploy with a Dockerfile](https://fly.io/docs/languages-and-frameworks/dockerfile/)                                                                                                                                                            |
| Railway              | Services                             | [Build from a Dockerfile](https://docs.railway.com/guides/dockerfiles)                                                                                                                                                                          |
| Render               | Web Services                         | [Docker on Render](https://render.com/docs/docker)                                                                                                                                                                                              |
| DigitalOcean         | App Platform                         | [How to deploy from container images](https://docs.digitalocean.com/products/app-platform/how-to/deploy-from-container-images/)                                                                                                                 |
| Heroku               | Container Registry & Runtime         | [Container Registry & Runtime (Docker Deploys)](https://devcenter.heroku.com/articles/container-registry-and-runtime)                                                                                                                           |
| Kubernetes (generic) | —                                    | [Using kubectl to create a Deployment](https://kubernetes.io/docs/tutorials/kubernetes-basics/deploy-app/deploy-intro/)                                                                                                                         |


</details>

<details>
<summary>📚 Full Manual Instructions (if you really want to do it yourself)</summary>

## Manual Setup

### Prerequisites
- Docker installed on your machine
- Claude Code OAuth token from setup above

### Clone and Run

```bash
# Clone the repository
git clone <repository-url>
cd claude-code-sdk-container

# Copy and edit the .env file (NO QUOTES in values!)
cp .env.example .env
# Edit .env and add your actual tokens (without quotes)

# Build the Docker image (uses directory name for uniqueness)
docker build -t claude-code-$(basename "$(pwd)") .

# Run the container (use --env-file for .env file)
docker run -d --name claude-code-$(basename "$(pwd)") -p 8080:8080 --env-file .env claude-code-$(basename "$(pwd)")

# IMPORTANT: Check if container is actually running!
docker ps | grep claude-code-$(basename "$(pwd)")
# If not visible, check logs:
docker logs claude-code-$(basename "$(pwd)")
```

### Test It's Working

```bash
# Easy way - run the test script:
./test.sh

# Check for SDK updates:
./update.sh

# Or manually test:
# 1. First check health (no auth required) - should return JSON
curl http://localhost:8080/health

# 2. Test query endpoint (WORKING EXAMPLE - copy exactly!)
curl -X POST http://localhost:8080/query \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key-here" \
  -d '{"prompt": "Say hello"}'

# Common mistakes to avoid:
# ❌ Missing quotes around JSON
# ❌ Smart quotes instead of straight quotes
# ❌ Missing -X POST
# ❌ Wrong header format
```

## API Usage

### Authentication
The `/query` endpoint requires an API key. You can provide it in two ways:

```bash
# Option 1: X-API-Key header
curl -H "X-API-Key: your-api-key-here"

# Option 2: Authorization Bearer header
curl -H "Authorization: Bearer your-api-key-here"
```

The health check endpoint (`/health`) is public and doesn't require authentication.

### Health Check (No Auth Required)
```bash
GET http://localhost:8080/health
```

Returns:
```json
{
  "status": "healthy",
  "hasToken": true,
  "sdkLoaded": true,
  "message": "Claude Code SDK API",
  "timestamp": "2025-09-18T23:30:00.000Z"
}
```

### Query Claude (Auth Required)
```bash
POST http://localhost:8080/query
Content-Type: application/json
X-API-Key: your-api-key-here

{
  "prompt": "Your question here",
  "options": {
    "model": "claude-sonnet-4-0"  // optional
  }
}
```

Returns:
```json
{
  "success": true,
  "response": "Claude's response",
  "messageCount": 3,
  "timestamp": "2025-09-18T23:30:00.000Z"
}
```

## Deployment

### Using Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  claude-api:
    image: claude-code-$(basename "$(pwd)")
    container_name: claude-code-$(basename "$(pwd)")
    ports:
      - "8080:8080"
    environment:
      - CLAUDE_CODE_OAUTH_TOKEN=${CLAUDE_CODE_OAUTH_TOKEN}
    restart: unless-stopped
```

Then run:
```bash
docker-compose up -d
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `CLAUDE_CODE_OAUTH_TOKEN` | Yes | Your Claude Code OAuth token |
| `CLAUDE_CODE_SDK_CONTAINER_API_KEY` | No* | API key for endpoint authentication |
| `GITHUB_CLIENT_ID` | Yes** | GitHub OAuth App Client ID |
| `GITHUB_CLIENT_SECRET` | Yes** | GitHub OAuth App Client Secret |
| `ALLOWED_GITHUB_USERS` | Yes*** | Comma-separated list of allowed GitHub usernames |
| `ALLOWED_GITHUB_ORG` | Yes*** | GitHub organization name for access control |
| `SESSION_SECRET` | No | JWT signing secret (generate with: `openssl rand -hex 32`) |
| `PORT` | No | Server port (default: 8080) |

*If `CLAUDE_CODE_SDK_CONTAINER_API_KEY` is not set, the `/query` endpoint will be publicly accessible.
**Required only for web CLI access. REST API works without GitHub OAuth.
***At least one of `ALLOWED_GITHUB_USERS` or `ALLOWED_GITHUB_ORG` must be set for security.

### GitHub Access Control

Control who can access the web CLI interface by configuring GitHub allowlists:

```bash
# Allow specific GitHub usernames
ALLOWED_GITHUB_USERS=user1,user2,admin

# Allow users from a GitHub organization
ALLOWED_GITHUB_ORG=mycompany

# Combine both (user must match either usernames OR organization)
ALLOWED_GITHUB_USERS=admin,specialuser
ALLOWED_GITHUB_ORG=mycompany
```

**Access Control Behavior:**
- **At least one allowlist must be configured** - the container will not start without proper access control
- **Case insensitive**: GitHub usernames are normalized to lowercase
- **Organization check**: Currently checks user's public company field (basic implementation)
- **Error response**: Unauthorized users receive `GitHub user not authorized`

**Examples:**
```bash
# Organization-only access
ALLOWED_GITHUB_ORG=mycompany

# Specific users only
ALLOWED_GITHUB_USERS=alice,bob,charlie

# Mixed access (admin + entire organization)
ALLOWED_GITHUB_USERS=admin
ALLOWED_GITHUB_ORG=mycompany
```

**Container Naming**: Each deployment automatically gets a unique container name based on the directory name (e.g., `claude-code-my-project`). This allows multiple deployments without conflicts.

**Note**: For production use with organization membership, consider implementing proper GitHub API calls to check organization membership instead of relying on the public company field.

## Examples

### Python
```python
import requests

response = requests.post('http://localhost:8080/query',
    headers={'X-API-Key': 'your-api-key-here'},
    json={'prompt': 'Explain quantum computing in simple terms'})
print(response.json()['response'])
```

### JavaScript
```javascript
const response = await fetch('http://localhost:8080/query', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': 'your-api-key-here'
  },
  body: JSON.stringify({ prompt: 'Write a haiku about coding' })
});
const data = await response.json();
console.log(data.response);
```

### cURL
```bash
curl -X POST http://localhost:8080/query \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key-here" \
  -d '{
    "prompt": "What is the meaning of life?",
    "options": {
      "model": "claude-sonnet-4-0"
    }
  }' | jq .response
```

## Troubleshooting

### Quick Debug Checklist
```bash
# 1. Is container running?
docker ps | grep claude-code

# 2. Check container logs
docker logs claude-code-$(basename "$(pwd)")

# 3. Test health endpoint (should work without auth)
curl http://localhost:8080/health

# 4. Test with your actual API key
curl -X POST http://localhost:8080/query \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_ACTUAL_KEY_HERE" \
  -d '{"prompt": "test"}'
```

### Common Issues

| Issue | Solution |
|-------|----------|
| **Container exits immediately** | Check logs: `docker logs claude-code-$(basename "$(pwd)")`. Usually bad OAuth token |
| **"Unauthorized - Invalid or missing API key"** | Your API key doesn't match. Check: `docker exec claude-code-$(basename "$(pwd)") env | grep CLAUDE_CODE_SDK_CONTAINER` |
| **Connection refused on port 8080** | Container not running. Check: `docker ps`. Restart: `docker start claude-code-$(basename "$(pwd)")` |
| **Quotes in environment variables** | Remove ALL quotes from .env file. Docker doesn't strip them! |
| **"unhealthy" status** | OAuth token is wrong. Get correct one with: `claude setup-token` |
| **Works locally but not from other container** | Use `host.docker.internal:8080` instead of `localhost:8080` |
| **Changes to .env not working** | Must restart container: `docker restart claude-code-$(basename "$(pwd)")` |

## Updating Claude Code SDK

The container includes a specific version of the Claude Code SDK. To update to the latest version:

```bash
# Run the update script
./update.sh

# This will:
# 1. Check for SDK updates
# 2. Update package if needed
# 3. Rebuild the container
# 4. Restart with new version
```

The update script handles everything automatically, including graceful container restart.

## Technical Details

- **Base Image**: Node.js 22 Alpine (optimized for size)
- **Container Size**: ~331MB
- **Memory Usage**: ~256MB
- **Supported Models**: All Claude Code SDK models
- **SDK Version**: Locked at build time (use `./update.sh` to update)

## License

MIT

## Credits

Thanks to [cabinlab/claude-code-sdk-docker](https://github.com/cabinlab/claude-code-sdk-docker) for examples on implementing `setup-token` authentication flow.

</details>
