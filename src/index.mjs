import express from "express";
import fs from "fs";
import path from "path";
import os from "os";
import { query } from "@anthropic-ai/claude-code";

// Constants
const DEFAULT_PORT = 8080;
const DEFAULT_MODEL = "claude-sonnet-4-0";
const MAX_PROMPT_LENGTH = 100000; // Reasonable limit

// Allowed models - add new models here as they become available
const ALLOWED_MODELS = [
  "claude-sonnet-4-0",
  "claude-opus-4-1"
];

// Just use console directly - no wrapper needed

const app = express();
app.use(express.json({ limit: '1mb' })); // Prevent huge payloads

// Simple auth middleware - only for protected endpoints
const requireAuth = (req, res, next) => {
  const configuredKey = process.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY;

  // No key configured = public access
  if (!configuredKey) {
    return next();
  }

  // Check provided key
  const apiKey = req.headers['x-api-key'] || req.headers['authorization']?.replace('Bearer ', '');
  if (apiKey === configuredKey) {
    return next();
  }

  res.status(401).json({ error: 'Unauthorized - Invalid or missing API key' });
};

// Check if running in Docker
const isDocker = fs.existsSync('/.dockerenv') ||
                 fs.existsSync('/run/.containerenv') ||
                 process.env.container === 'docker';

if (!isDocker && process.env.ALLOW_LOCAL !== 'true') {
  console.error("\n❌ ERROR: This application must be run in Docker!");
  console.error("\n📋 Quick Start:");
  console.error("1. Ensure Docker is running");
  console.error("2. Build the image: docker build -t claude-code-sdk .");
  console.error("3. Run the container: docker run -d -p 8080:8080 --env-file .env claude-code-sdk");
  console.error("4. Test it: ./test.sh\n");
  console.error("Or simply run: ./test.sh (it will start Docker if needed)\n");
  console.error("To bypass this check (not recommended): ALLOW_LOCAL=true node src/index.mjs\n");
  process.exit(1);
}

// Check authentication on startup
console.log("=== Claude Code SDK Container Starting ===");
console.log("Node version:", process.version);
console.log("Environment:", isDocker ? "Docker Container ✅" : "Local (bypass mode) ⚠️");
console.log("HOME:", os.homedir());
console.log("Claude token present:", !!process.env.CLAUDE_CODE_OAUTH_TOKEN);
console.log("API key configured:", !!process.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY);
console.log("API protection:", process.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY ? "ENABLED" : "DISABLED (public access)");

// Check for credential files (without exposing sensitive data)
const credPath = path.join(os.homedir(), ".claude", ".credentials.json");
const configPath = path.join(os.homedir(), ".claude.json");
console.log("Credentials configured:", fs.existsSync(credPath) && fs.existsSync(configPath));

const PORT = process.env.PORT || DEFAULT_PORT;

// Health check endpoint
app.get("/", (req, res) => {
  const hasToken = !!process.env.CLAUDE_CODE_OAUTH_TOKEN;
  const sdkLoaded = typeof query === "function";

  res.json({
    status: hasToken && sdkLoaded ? "healthy" : "unhealthy",
    hasToken,
    sdkLoaded,
    message: "Claude Code SDK API",
    timestamp: new Date().toISOString(),
  });
});

// Query endpoint - send a prompt to Claude (protected)
app.post("/query", requireAuth, async (req, res) => {
  try {
    const { prompt, options = {} } = req.body;

    if (!prompt) {
      return res.status(400).json({ error: "Prompt is required" });
    }

    if (typeof prompt !== 'string') {
      return res.status(400).json({ error: "Prompt must be a string" });
    }

    if (prompt.length > MAX_PROMPT_LENGTH) {
      return res.status(400).json({
        error: `Prompt too long. Maximum length is ${MAX_PROMPT_LENGTH} characters`
      });
    }

    if (!process.env.CLAUDE_CODE_OAUTH_TOKEN) {
      return res
        .status(401)
        .json({ error: "CLAUDE_CODE_OAUTH_TOKEN not configured" });
    }

    // Validate model if provided
    let selectedModel = DEFAULT_MODEL;
    if (options.model) {
      if (!ALLOWED_MODELS.includes(options.model)) {
        return res.status(400).json({
          error: `Invalid model. Allowed models: ${ALLOWED_MODELS.join(', ')}`
        });
      }
      selectedModel = options.model;
    }

    const messages = [];
    let responseText = "";

    // Build safe options - only allow explicitly safe parameters
    const safeOptions = {
      model: selectedModel,
      // Only add other options here after security review
      // Do NOT use spread operator with user input
    };

    // Use the Claude Code SDK
    const response = query({
      prompt: prompt,
      options: safeOptions,
    });

    for await (const message of response) {
      messages.push(message);

      // Extract text from assistant messages
      if (message.type === "assistant" && message.message?.content) {
        for (const block of message.message.content) {
          if (block.type === "text") {
            responseText += block.text;
          }
        }
      }
    }

    res.json({
      success: true,
      response: responseText
    });
  } catch (error) {
    console.error("Query error:", error.message);
    res.status(500).json({
      error: "Failed to process query",
      details: error.message,
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log("\n=== Server started ===");
  console.log(`Claude Code SDK API listening on port ${PORT}`);
  console.log(
    `OAuth token configured: ${!!process.env.CLAUDE_CODE_OAUTH_TOKEN}`,
  );
  console.log("Ready to receive requests");
  console.log("====================\n");
});

// Handle graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM received, shutting down gracefully");
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("SIGINT received, shutting down gracefully");
  process.exit(0);
});
