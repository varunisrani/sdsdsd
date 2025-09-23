import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";
import { createNodeWebSocket } from "@hono/node-ws";
import { getCookie, setCookie } from "hono/cookie";
import { SignJWT, jwtVerify } from "jose";
import { randomBytes } from "node:crypto";
import { Resend } from "resend";
import { query } from "@anthropic-ai/claude-code";
import fs from "fs";
import os from "os";
import path from "path";

// Constants
const DEFAULT_PORT = 8080;
const DEFAULT_MODEL = "claude-sonnet-4-0";
const MAX_PROMPT_LENGTH = 100000;
const SESSION_COOKIE = "sid";
const LOGIN_TTL_MIN = 10;
const SESSION_TTL_SEC = 60 * 60;

// Allowed models
const ALLOWED_MODELS = [
  "claude-sonnet-4-0",
  "claude-opus-4-1"
];

// Environment setup
const SECRET = new TextEncoder().encode(process.env.SESSION_SECRET || "devdevdev");
const resend = new Resend(process.env.RESEND_API_KEY);
const PORT = process.env.PORT || DEFAULT_PORT;

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
  console.error("To bypass this check (not recommended): ALLOW_LOCAL=true tsx server.ts\n");
  process.exit(1);
}

// Email service
async function sendEmail(to: string, subject: string, html: string) {
  if (!process.env.RESEND_API_KEY) {
    console.log(`[DEV] Would send email to ${to}: ${subject}`);
    console.log(`[DEV] HTML: ${html}`);
    return;
  }

  try {
    await resend.emails.send({
      from: process.env.EMAIL_FROM || 'Claude CLI <noreply@claude-cli.local>',
      to,
      subject,
      html
    });
    console.log(`Email sent to ${to}: ${subject}`);
  } catch (error) {
    console.error(`Failed to send email to ${to}:`, error);
    throw error;
  }
}

// JWT utilities
async function setSessionCookie(c: any, email: string) {
  const token = await new SignJWT({ sub: email, email })
    .setProtectedHeader({ alg: "HS256" })
    .setIssuedAt()
    .setExpirationTime(`${SESSION_TTL_SEC}s`)
    .sign(SECRET);

  setCookie(c, SESSION_COOKIE, token, {
    path: "/",
    maxAge: SESSION_TTL_SEC,
    httpOnly: true,
    secure: true,
    sameSite: "Lax"
  });
}

// Auth middleware for API endpoints
const requireApiAuth = (req: any, res: any, next: any) => {
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

  return res.status(401).json({ error: 'Unauthorized - Invalid or missing API key' });
};

// WebSocket auth middleware
async function requireAuthWS(c: any) {
  const val = getCookie(c, SESSION_COOKIE);
  if (!val) return null;
  try {
    await jwtVerify(val, SECRET);
    return true;
  } catch {
    return null;
  }
}

const app = new Hono();

// WebSocket setup
const { injectWebSocket, upgradeWebSocket } = createNodeWebSocket({ app });

// Startup logging
console.log("=== Claude Code SDK Container Starting ===");
console.log("Node version:", process.version);
console.log("Environment:", isDocker ? "Docker Container ✅" : "Local (bypass mode) ⚠️");
console.log("HOME:", os.homedir());
console.log("Claude token present:", !!process.env.CLAUDE_CODE_OAUTH_TOKEN);
console.log("API key configured:", !!process.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY);
console.log("API protection:", process.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY ? "ENABLED" : "DISABLED (public access)");
console.log("Resend API key present:", !!process.env.RESEND_API_KEY);

// Check for credential files
const credPath = path.join(os.homedir(), ".claude", ".credentials.json");
const configPath = path.join(os.homedir(), ".claude.json");
console.log("Credentials configured:", fs.existsSync(credPath) && fs.existsSync(configPath));

// Health check endpoint
app.get("/", (c) => {
  const hasToken = !!process.env.CLAUDE_CODE_OAUTH_TOKEN;
  const sdkLoaded = typeof query === "function";

  return c.json({
    status: hasToken && sdkLoaded ? "healthy" : "unhealthy",
    hasToken,
    sdkLoaded,
    message: "Claude Code SDK API with CLI",
    timestamp: new Date().toISOString(),
  });
});

// Legacy query endpoint (REST API with API key auth)
app.post("/query", async (c) => {
  try {
    // API key authentication
    const configuredKey = process.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY;
    if (configuredKey) {
      const apiKey = c.req.header('x-api-key') || c.req.header('authorization')?.replace('Bearer ', '');
      if (apiKey !== configuredKey) {
        return c.json({ error: 'Unauthorized - Invalid or missing API key' }, 401);
      }
    }

    const { prompt, options = {} } = await c.req.json();

    if (!prompt) {
      return c.json({ error: "Prompt is required" }, 400);
    }

    if (typeof prompt !== 'string') {
      return c.json({ error: "Prompt must be a string" }, 400);
    }

    if (prompt.length > MAX_PROMPT_LENGTH) {
      return c.json({
        error: `Prompt too long. Maximum length is ${MAX_PROMPT_LENGTH} characters`
      }, 400);
    }

    if (!process.env.CLAUDE_CODE_OAUTH_TOKEN) {
      return c.json({ error: "CLAUDE_CODE_OAUTH_TOKEN not configured" }, 401);
    }

    // Validate model if provided
    let selectedModel = DEFAULT_MODEL;
    if (options.model) {
      if (!ALLOWED_MODELS.includes(options.model)) {
        return c.json({
          error: `Invalid model. Allowed models: ${ALLOWED_MODELS.join(', ')}`
        }, 400);
      }
      selectedModel = options.model;
    }

    const messages = [];
    let responseText = "";

    // Build safe options
    const safeOptions = {
      model: selectedModel,
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

    return c.json({
      success: true,
      response: responseText
    });
  } catch (error: any) {
    console.error("Query error:", error.message);
    return c.json({
      error: "Failed to process query",
      details: error.message,
    }, 500);
  }
});

// Auth: start (magic link)
app.post("/auth/start", async (c) => {
  const { email } = await c.req.json().catch(() => ({}));
  if (!email) return c.body(null, 400);

  const token = await new SignJWT({ email, aud: "login" })
    .setProtectedHeader({ alg: "HS256" })
    .setJti(randomBytes(8).toString("hex"))
    .setIssuedAt()
    .setExpirationTime(`${LOGIN_TTL_MIN}m`)
    .sign(SECRET);

  const u = new URL(c.req.url);
  u.pathname = "/auth/verify";
  u.searchParams.set("t", token);

  await sendEmail(email, "Sign in to Claude CLI", `
    <h2>Sign in to Claude CLI</h2>
    <p>Click the link below to sign in (expires in ${LOGIN_TTL_MIN} minutes):</p>
    <p><a href="${u.toString()}" style="background: #0066cc; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">Sign in to Claude CLI</a></p>
    <p>If the button doesn't work, copy and paste this link:</p>
    <p><code>${u.toString()}</code></p>
  `);

  return c.body(null, 204);
});

// Auth: verify (magic link)
app.get("/auth/verify", async (c) => {
  const t = c.req.query("t");
  if (!t) return c.text("Bad Request", 400);

  try {
    const { payload } = await jwtVerify(t, SECRET, { audience: "login" });
    const email = String(payload.email || "");
    if (!email) return c.text("Invalid", 400);

    await setSessionCookie(c, email);
    c.status(302);
    c.header("Location", "/");
    return c.body(null);
  } catch {
    return c.text("Expired or invalid link", 400);
  }
});

// Auth: ping (check if authenticated) - supports both GET and HEAD
app.on(['GET', 'HEAD'], "/auth/verify-ping", async (c) => {
  const val = getCookie(c, SESSION_COOKIE);
  if (!val) return c.body(null, 401);
  try {
    await jwtVerify(val, SECRET);
    return c.body(null, 200);
  } catch {
    return c.body(null, 401);
  }
});

// WebSocket endpoint
app.get("/ws", upgradeWebSocket((c) => ({
  onOpen: async (event, ws) => {
    const ok = await requireAuthWS(c);
    if (!ok) {
      ws.close();
      return;
    }
    ws.send(JSON.stringify({ type: "ready" }));
  },

  onMessage: async (event, ws) => {
    let data: any;
    try {
      data = JSON.parse(String(event.data));
    } catch {
      return;
    }

    if (!data?.prompt) return;

    try {
      // Validate prompt
      if (typeof data.prompt !== 'string') return;
      if (data.prompt.length > MAX_PROMPT_LENGTH) {
        ws.send(JSON.stringify({
          type: "error",
          message: `Prompt too long. Maximum length is ${MAX_PROMPT_LENGTH} characters`
        }));
        return;
      }

      if (!process.env.CLAUDE_CODE_OAUTH_TOKEN) {
        ws.send(JSON.stringify({
          type: "error",
          message: "CLAUDE_CODE_OAUTH_TOKEN not configured"
        }));
        return;
      }

      // Use Claude Code SDK with streaming
      const response = query({
        prompt: data.prompt,
        options: {
          model: DEFAULT_MODEL,
        },
      });

      for await (const message of response) {
        // Extract text from assistant messages and stream
        if (message.type === "assistant" && message.message?.content) {
          for (const block of message.message.content) {
            if (block.type === "text") {
              // Stream character by character for CLI effect
              for (const char of block.text) {
                ws.send(JSON.stringify({ type: "text", chunk: char }));
                // Small delay for streaming effect
                await new Promise(resolve => setTimeout(resolve, 5));
              }
            }
          }
        }
      }

      ws.send(JSON.stringify({ type: "done" }));

    } catch (error: any) {
      console.error("WebSocket query error:", error.message);
      ws.send(JSON.stringify({
        type: "error",
        message: "Failed to process query"
      }));
    }
  },

  onClose: () => {}
})));

// Serve static assets first
app.use('/assets/*', serveStatic({ root: './web/dist' }));

// SPA fallback - serve index.html for non-API routes
app.notFound((c) => {
  // For non-API routes, serve the SPA
  if (!c.req.path.startsWith('/auth/') &&
      !c.req.path.startsWith('/ws') &&
      !c.req.path.startsWith('/query') &&
      !c.req.path.startsWith('/assets/')) {
    return serveStatic({
      root: './web/dist',
      path: './web/dist/index.html'
    })(c);
  }
  return c.text('Not Found', 404);
});

// Start server using Hono's serve function with WebSocket support
const server = serve({
  fetch: app.fetch,
  port: PORT
}, (info) => {
  console.log("\n=== Server started ===");
  console.log(`Claude Code SDK API with CLI listening on port ${info.port}`);
  console.log(`OAuth token configured: ${!!process.env.CLAUDE_CODE_OAUTH_TOKEN}`);
  console.log(`Visit http://localhost:${info.port} for the CLI interface`);
  console.log(`API endpoint: POST http://localhost:${info.port}/query`);
  console.log("Ready to receive requests");
  console.log("====================\n");
});

// Inject WebSocket support into the server
injectWebSocket(server);

// Handle graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM received, shutting down gracefully");
  server.close(() => {
    process.exit(0);
  });
});

process.on("SIGINT", () => {
  console.log("SIGINT received, shutting down gracefully");
  server.close(() => {
    process.exit(0);
  });
});