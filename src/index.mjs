import express from "express";
import fs from "fs";
import path from "path";
import os from "os";
import { query } from "@anthropic-ai/claude-code";

const app = express();
app.use(express.json());

// Simple auth middleware - only for protected endpoints
const requireAuth = (req, res, next) => {
  const apiKey = req.headers['x-api-key'] || req.headers['authorization']?.replace('Bearer ', '');

  if (!process.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY || apiKey === process.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY) {
    next();
  } else {
    res.status(401).json({ error: 'Unauthorized - Invalid or missing API key' });
  }
};

// Check if running in Docker
const isDocker = fs.existsSync('/.dockerenv') ||
                  fs.existsSync('/run/.containerenv') ||
                  (process.env.container === 'docker');

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
console.log("Claude token length:", process.env.CLAUDE_CODE_OAUTH_TOKEN?.length || 0);
console.log("API key configured:", !!process.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY);
console.log("API protection:", process.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY ? "ENABLED" : "DISABLED (public access)");

// Check for credential files
const credPath = path.join(os.homedir(), ".claude", ".credentials.json");
const configPath = path.join(os.homedir(), ".claude.json");
console.log("Credentials file exists:", fs.existsSync(credPath));
console.log("Config file exists:", fs.existsSync(configPath));

if (fs.existsSync(credPath)) {
  try {
    const creds = JSON.parse(fs.readFileSync(credPath, "utf8"));
    console.log("Credentials structure valid:", !!creds.claudeAiOauth);
  } catch (e) {
    console.error("Error reading credentials:", e.message);
  }
}

const PORT = process.env.PORT || 8080;

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

    if (!process.env.CLAUDE_CODE_OAUTH_TOKEN) {
      return res
        .status(401)
        .json({ error: "CLAUDE_CODE_OAUTH_TOKEN not configured" });
    }

    const messages = [];
    let responseText = "";

    try {
      // Use the Claude Code SDK
      const response = query({
        prompt: prompt,
        options: {
          model: options.model || "claude-sonnet-4-0",
          ...options,
        },
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
        response: responseText,
        messageCount: messages.length,
        timestamp: new Date().toISOString(),
      });
    } catch (innerError) {
      console.error("Query execution error:", innerError);
      throw innerError;
    }
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
