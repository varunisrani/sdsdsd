import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";
import { createNodeWebSocket } from "@hono/node-ws";
import { getCookie, setCookie } from "hono/cookie";
import { SignJWT, jwtVerify } from "jose";
import { randomBytes } from "node:crypto";
import { Resend } from "resend";
import { query, type CanUseTool } from "@anthropic-ai/claude-code";
import fs from "fs";
import os from "os";
import path from "path";

// Environment setup
const SECRET = new TextEncoder().encode(process.env.SESSION_SECRET || "devdevdev");
const resend = new Resend(process.env.RESEND_API_KEY);
const PORT = process.env.PORT || 8080;

// Auto-allow all tool uses (no permission prompts)
const allowAll: CanUseTool = async (_toolName, input) => ({
  behavior: 'allow',
  updatedInput: input,
});

// Email allowlist configuration
const allowedEmails = process.env.ALLOWED_EMAILS?.split(',').map(e => e.trim().toLowerCase()) || [];
const allowedDomains = process.env.ALLOWED_DOMAINS?.split(',').map(d => d.trim().toLowerCase()) || [];

// Check if running in Docker (skip check in test mode)
if (process.env.NODE_ENV !== 'test') {
  const isDocker = fs.existsSync('/.dockerenv') || process.env.container === 'docker';

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
}

// Email validation function
function isEmailAllowed(email: string): boolean {
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return false;

  const normalizedEmail = email.toLowerCase().trim();

  // If no restrictions configured, allow all valid emails
  if (allowedEmails.length === 0 && allowedDomains.length === 0) return true;

  // Check email or domain
  return allowedEmails.includes(normalizedEmail) ||
         allowedDomains.includes(normalizedEmail.split('@')[1]);
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
    .setExpirationTime('3600s')
    .sign(SECRET);

  setCookie(c, 'sid', token, {
    path: "/",
    maxAge: 3600,
    httpOnly: true,
    secure: true,
    sameSite: "Lax"
  });
}

// API key auth helper
function checkApiAuth(c: any): boolean {
  const configuredKey = process.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY;
  if (!configuredKey) return true; // No key = public access

  const apiKey = c.req.header('x-api-key') || c.req.header('authorization')?.replace('Bearer ', '');
  return apiKey === configuredKey;
}

// WebSocket auth helper
async function checkWSAuth(c: any): Promise<boolean> {
  const val = getCookie(c, 'sid');
  if (!val) return false;
  try {
    await jwtVerify(val, SECRET);
    return true;
  } catch {
    return false;
  }
}

export const app = new Hono();

// WebSocket setup
const { injectWebSocket, upgradeWebSocket } = createNodeWebSocket({ app });

// Session ID store (keyed by WebSocket connection)
// The Claude SDK returns a new session ID with each response that must be used to resume the conversation
const sessionIds = new Map<any, string>();

// Startup logging (skip in test mode)
if (process.env.NODE_ENV !== 'test') {
  const isDocker = fs.existsSync('/.dockerenv') || process.env.container === 'docker';
  console.log("Claude Code SDK Container starting...");
  console.log("Environment:", isDocker ? "Docker" : "Local");
  console.log("Claude token:", !!process.env.CLAUDE_CODE_OAUTH_TOKEN ? "✓" : "✗");
  console.log("API protection:", !!process.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY ? "✓" : "✗");
  console.log("Email service:", !!process.env.RESEND_API_KEY ? "✓" : "✗");
}

// Health check endpoint
app.get("/health", (c) => {
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

// Serve React SPA at root for browser requests (skip in test mode)
if (process.env.NODE_ENV !== 'test') {
  app.get("/", serveStatic({
    root: './web/dist',
    path: './index.html'
  }));
}

// Legacy query endpoint (REST API with API key auth)
app.post("/query", async (c) => {
  try {
    // API key authentication
    if (!checkApiAuth(c)) {
      return c.json({ error: 'Unauthorized - Invalid or missing API key' }, 401);
    }

    const { prompt, options = {} } = await c.req.json();

    if (!prompt) {
      return c.json({ error: "Prompt is required" }, 400);
    }

    if (typeof prompt !== 'string') {
      return c.json({ error: "Prompt must be a string" }, 400);
    }

    if (prompt.length > 100000) {
      return c.json({ error: 'Prompt too long. Maximum 100000 characters' }, 400);
    }

    if (!process.env.CLAUDE_CODE_OAUTH_TOKEN) {
      return c.json({ error: "CLAUDE_CODE_OAUTH_TOKEN not configured" }, 401);
    }

    const messages = [];
    let responseText = "";

    // Build options for REST API
    const queryOptions = {
      model: options.model || 'claude-sonnet-4-0',
    };

    // Use the Claude Code SDK for simple question/answer
    const response = query({
      prompt: prompt,
      options: queryOptions,
    });

    for await (const message of response) {
      messages.push(message);

      // For REST API, just collect assistant text responses
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
  if (!email) return c.json({ error: "Email is required" }, 400);

  // Validate email format and allowlist
  if (!isEmailAllowed(email)) {
    return c.json({ error: "Email address not allowed" }, 403);
  }

  const token = await new SignJWT({ email, aud: "login" })
    .setProtectedHeader({ alg: "HS256" })
    .setJti(randomBytes(8).toString("hex"))
    .setIssuedAt()
    .setExpirationTime('10m')
    .sign(SECRET);

  const u = new URL(c.req.url);
  u.pathname = "/auth/verify";
  u.searchParams.set("t", token);

  await sendEmail(email, "Sign in to Claude CLI", `
    <h2>Sign in to Claude CLI</h2>
    <p>Click the link below to sign in (expires in 10 minutes):</p>
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

// Auth: ping (check if authenticated)
app.on(['GET', 'HEAD'], "/auth/verify-ping", async (c) => {
  const val = getCookie(c, 'sid');
  if (!val) return c.body(null, 401);
  try {
    await jwtVerify(val, SECRET);
    return c.body(null, 200);
  } catch {
    return c.body(null, 401);
  }
});

// WebSocket handler - exported for testing
export const websocketHandler = (c: any) => ({
  onOpen: async (event, ws) => {
    const ok = await checkWSAuth(c);
    if (!ok) {
      ws.close();
      return;
    }
    // Initialize session tracking for this connection
    sessionIds.set(ws, "");
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
      if (data.prompt.length > 100000) {
        ws.send(JSON.stringify({
          type: "error",
          message: 'Prompt too long. Maximum 100000 characters'
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

      // Get the current session ID for this connection
      const currentSessionId = sessionIds.get(ws);
      let newSessionId: string | undefined;

      // Build query options
      const queryOptions: any = {
        model: 'claude-sonnet-4-0',
        cwd: "/app",
        env: process.env,
      };

      // Resume the conversation if we have a session ID from a previous response
      if (currentSessionId) {
        queryOptions.resume = currentSessionId;
      }

      // Use Claude Code SDK with session management
      const response = query({
        prompt: data.prompt,
        options: queryOptions,
      });

      for await (const message of response) {
        // Capture the new session ID from the init message
        // Each response generates a new session ID that must be used for the next query
        if (message.type === "system" && message.subtype === "init" && message.session_id) {
          newSessionId = message.session_id;
          sessionIds.set(ws, newSessionId);
        }

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

  onClose: (event, ws) => {
    // Clean up session ID when connection closes
    sessionIds.delete(ws);
  }
});

// WebSocket endpoint
app.get("/ws", upgradeWebSocket(websocketHandler));

// Serve static assets (skip in test mode)
if (process.env.NODE_ENV !== 'test') {
  app.use('/assets/*', serveStatic({ root: './web/dist' }));
}

// SPA fallback - serve index.html for non-API routes
app.notFound((c) => {
  // For non-API routes, serve the SPA (skip in test mode)
  if (process.env.NODE_ENV !== 'test' &&
      !c.req.path.startsWith('/auth/') &&
      !c.req.path.startsWith('/ws') &&
      !c.req.path.startsWith('/query') &&
      !c.req.path.startsWith('/assets/')) {
    return serveStatic({
      root: './web/dist',
      path: './index.html'
    })(c);
  }
  return c.text('Not Found', 404);
});

// Start server only when not in test mode
if (process.env.NODE_ENV !== 'test') {
  const server = serve({
    fetch: app.fetch,
    port: PORT
  }, (info) => {
    console.log(`Server listening on port ${info.port}`);
    console.log(`Web CLI: http://localhost:${info.port}`);
    console.log(`API: POST http://localhost:${info.port}/query`);
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
}