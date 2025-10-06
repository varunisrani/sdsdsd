# GLM-4.6 Integration Guide

## 🚀 Quick Start with GLM-4.6

This guide shows how to use GLM-4.6 as a cost-effective alternative to Claude in the Agent SDK Container.

### Why GLM-4.6?
- 💰 **Significantly cheaper** than Claude API
- 🚀 **Drop-in replacement** - API compatible
- 🔧 **Minimal configuration changes**
- 📦 **Same features** as Claude (WebSocket, multi-agent, auth)

## 📋 Setup Instructions

### Step 1: Get GLM-4.6 API Key
1. Visit [https://z.ai](https://z.ai)
2. Sign up or login
3. Navigate to API section
4. Generate/copy your API key

### Step 2: Run GLM-4.6 Setup Script

**Windows:**
```cmd
setup-glm.bat
```

**Linux/Mac:**
```bash
# Create Linux version of setup script or configure manually
```

### Step 3: Manual Configuration (Alternative)

Create `.env` file:
```env
# GLM-4.6 Configuration
ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
ANTHROPIC_AUTH_TOKEN=your-glm-api-key-here

# Container API Key (generate with: openssl rand -hex 32)
CLAUDE_AGENT_SDK_CONTAINER_API_KEY=your-api-key-here

# GitHub OAuth (required for web access)
GITHUB_CLIENT_ID=your_github_app_client_id
GITHUB_CLIENT_SECRET=your_github_app_client_secret

# Security (required)
ALLOWED_GITHUB_USERS=your-github-username

# Model configuration
GLM_MODEL=GLM-4.6
SESSION_SECRET=your-session-secret-32-chars-minimum
```

### Step 4: Run Container
```bash
./test.sh
```

## 🔧 Configuration Options

### Model Selection
```env
# Use GLM-4.6 (default)
GLM_MODEL=GLM-4.6

# Or use GLM-4.5-Air for faster responses
GLM_MODEL=GLM-4.5-Air
```

### API Endpoint
```env
# Default Z.AI endpoint
ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic

# Alternative endpoints if provided
ANTHROPIC_BASE_URL=https://your-endpoint.com/api/anthropic
```

## 🆚 Claude vs GLM-4.6 Comparison

| Feature | Claude | GLM-4.6 |
|---------|--------|---------|
| **Cost** | Higher | Lower ✅ |
| **API Compatibility** | Native | Compatible ✅ |
| **WebSocket Support** | ✅ | ✅ |
| **Multi-Agent** | ✅ | ✅ |
| **GitHub OAuth** | ✅ | ✅ |
| **Docker Support** | ✅ | ✅ |
| **Model Quality** | Excellent | Very Good ✅ |

## 🔄 Migration from Claude

### Automatic Migration
If you have an existing `.env` file with Claude configuration:

1. **Replace Claude token:**
   ```env
   # OLD
   CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-...

   # NEW
   ANTHROPIC_AUTH_TOKEN=your-glm-api-key
   ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
   ```

2. **Add model configuration:**
   ```env
   GLM_MODEL=GLM-4.6
   ```

3. **Keep everything else the same!**
   - GitHub OAuth configuration unchanged
   - API key protection unchanged
   - Access control unchanged

### Backward Compatibility
The container supports both Claude and GLM-4.6:
- If `ANTHROPIC_AUTH_TOKEN` is set → Uses GLM-4.6
- If `CLAUDE_CODE_OAUTH_TOKEN` is set → Uses Claude
- If both are set → Prioritizes GLM-4.6

## 🚨 Troubleshooting

### Common Issues

#### "ANTHROPIC_AUTH_TOKEN not configured"
```bash
# Check your .env file
cat .env | grep ANTHROPIC_AUTH_TOKEN

# Ensure no quotes around the token
# Correct: ANTHROPIC_AUTH_TOKEN=your-key-here
# Wrong:   ANTHROPIC_AUTH_TOKEN="your-key-here"
```

#### "Health check unhealthy"
```bash
# Check container logs
docker logs claude-agent-sdk-container

# Verify API key is valid
curl -H "Authorization: Bearer YOUR_GLM_API_KEY" \
     https://api.z.ai/api/anthropic/v1/messages
```

#### Model not responding
```bash
# Check which model is configured
docker logs claude-agent-sdk-container | grep "Model:"

# Try fallback model
export GLM_MODEL=GLM-4.5-Air
./test.sh
```

### Debug Mode
```bash
# Run with debug logging
docker run -d -p 8080:8080 --env-file .env \
  -e DEBUG=true \
  --name glm-debug \
  claude-agent-sdk-container
```

## 📊 Performance Monitoring

### Check AI Provider Status
```bash
# Health endpoint shows provider info
curl http://localhost:8080/health

# Response example:
{
  "status": "healthy",
  "hasToken": true,
  "sdkLoaded": true,
  "message": "Claude Agent SDK API with CLI",
  "provider": "GLM-4.6"
}
```

### Monitor API Usage
The container logs show:
- Which AI provider is being used
- Model configuration
- API response times

## 🔐 Security Notes

### API Key Protection
- GLM-4.6 API keys are stored in environment variables
- Container generates secure session tokens
- GitHub OAuth still required for web access

### Access Control
Same security features as Claude:
- GitHub user allowlist
- Organization restrictions
- API key protection for REST endpoints

## 💡 Tips & Best Practices

1. **Start with GLM-4.5-Air** for testing (faster, cheaper)
2. **Use GLM-4.6** for production (better quality)
3. **Monitor API usage** through Z.AI dashboard
4. **Keep API keys secure** - never commit to git
5. **Use environment-specific** .env files

## 🆘 Support

For GLM-4.6 specific issues:
- Check [Z.AI Documentation](https://docs.z.ai)
- Verify API key validity
- Check service status

For container issues:
- Check Docker logs
- Verify .env configuration
- Ensure GitHub OAuth is configured

## 🎉 Success!

Once setup is complete:
1. Visit http://localhost:8080
2. Sign in with GitHub
3. Start using GLM-4.6! 🚀

You're now running a cost-effective AI container with GLM-4.6!