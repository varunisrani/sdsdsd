import { useEffect, useRef, useState } from "react";
import { createRoot } from "react-dom/client";

function Login() {
  return (
    <div
      style={{
        maxWidth: 420,
        margin: "15vh auto",
        fontFamily: "system-ui",
        textAlign: "center",
      }}
    >
      <div style={{ marginBottom: 32 }}>
        <h1 style={{ fontSize: 28, marginBottom: 8, color: "#fff" }}>
          Claude CLI
        </h1>
        <p style={{ color: "#888", margin: 0 }}>
          Containerized Claude Code with browser interface
        </p>
      </div>

      <button
        onClick={() => (window.location.href = "/auth/github")}
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          gap: 12,
          width: "100%",
          padding: "16px 24px",
          background: "#24292e",
          color: "#fff",
          border: "none",
          borderRadius: 6,
          fontSize: 16,
          fontWeight: 500,
          cursor: "pointer",
          transition: "background-color 0.2s",
        }}
        onMouseOver={(e) => (e.currentTarget.style.background = "#2f363d")}
        onMouseOut={(e) => (e.currentTarget.style.background = "#24292e")}
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
        </svg>
        Sign in with GitHub
      </button>

      <p
        style={{ color: "#666", marginTop: 24, fontSize: 14, lineHeight: 1.5 }}
      >
        Sign in with your GitHub account to access the Claude CLI interface.
      </p>
    </div>
  );
}

function CLI() {
  const [connected, setConnected] = useState(false);
  const [input, setInput] = useState("");
  const preRef = useRef<HTMLPreElement>(null);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    const ws = new WebSocket(
      (location.protocol === "https:" ? "wss://" : "ws://") +
        location.host +
        "/ws",
    );
    wsRef.current = ws;

    ws.onopen = () => {
      setConnected(true);
      log("✔ Connected to Claude CLI\n");
    };

    ws.onclose = () => {
      setConnected(false);
      log("✖ Disconnected\n");
    };

    ws.onmessage = (e) => {
      const msg = JSON.parse(e.data);
      if (msg.type === "text") log(msg.chunk);
      if (msg.type === "done") log("\n");
      if (msg.type === "ready") log("Ready for your questions...\n\n");
    };

    function log(s: string) {
      if (!preRef.current) return;
      preRef.current.textContent += s;
      preRef.current.scrollTop = preRef.current.scrollHeight;
    }

    return () => ws.close();
  }, []);

  const send = () => {
    if (!input.trim() || !connected) return;

    // Echo the user's input
    if (!preRef.current) return;
    preRef.current.textContent += `> ${input}\n`;
    preRef.current.scrollTop = preRef.current.scrollHeight;

    wsRef.current?.send(JSON.stringify({ prompt: input }));
    setInput("");
  };

  return (
    <div
      style={{
        display: "grid",
        gridTemplateRows: "1fr auto",
        height: "100vh",
        fontFamily:
          "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace",
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
      }}
    >
      <pre
        ref={preRef}
        style={{
          margin: 0,
          padding: 12,
          overflow: "auto",
          whiteSpace: "pre-wrap",
          background: "#0b0b0b",
          color: "#e6e6e6",
          fontSize: "14px",
          lineHeight: "1.4",
        }}
      />
      <div
        style={{
          display: "flex",
          gap: 8,
          padding: 8,
          borderTop: "1px solid #222",
          background: "#111",
          paddingBottom: "max(8px, env(safe-area-inset-bottom))", // Account for home indicator on iOS
        }}
      >
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && !e.shiftKey) {
              e.preventDefault();
              send();
            }
          }}
          placeholder={connected ? "Ask Claude anything..." : "Connecting..."}
          style={{
            flex: 1,
            padding: 10,
            background: "#000",
            color: "#fff",
            border: "1px solid #333",
            fontSize: "16px", // Prevent zoom on iOS
            borderRadius: "4px",
          }}
          disabled={!connected}
        />
        <button
          onClick={send}
          style={{
            padding: "10px 14px",
            background: connected ? "#0066cc" : "#333",
            color: "#fff",
            border: "none",
            cursor: connected ? "pointer" : "default",
            borderRadius: "4px",
          }}
          disabled={!connected}
        >
          Send
        </button>
      </div>
    </div>
  );
}

function App() {
  const [authed, setAuthed] = useState<boolean | null>(null);

  useEffect(() => {
    fetch("/auth/verify-ping", { method: "HEAD" })
      .then((r) => setAuthed(r.ok))
      .catch(() => setAuthed(false));
  }, []);

  if (authed === null) {
    return (
      <div
        style={{
          padding: 20,
          fontFamily: "system-ui",
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          height: "100vh",
          background: "#0b0b0b",
          color: "#e6e6e6",
        }}
      >
        Loading...
      </div>
    );
  }

  if (authed) return <CLI />;

  return (
    <div
      style={{
        background: "#0b0b0b",
        minHeight: "100vh",
        color: "#e6e6e6",
      }}
    >
      <Login />
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<App />);
