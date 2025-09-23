import { useEffect, useRef, useState } from "react";
import { createRoot } from "react-dom/client";

function Login({ onSent }: { onSent: () => void }) {
  const [email, setEmail] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  return (
    <div style={{maxWidth: 420, margin: "10vh auto", fontFamily: "system-ui"}}>
      <h3>Sign in to Claude CLI</h3>
      <input
        placeholder="you@company.com"
        value={email}
        onChange={(e)=>setEmail(e.target.value)}
        style={{width:"100%", padding:8, marginBottom:8, background:"#111", color:"#fff", border:"1px solid #333"}}
        disabled={isLoading}
      />
      <button
        onClick={async ()=>{
          if(!email || isLoading) return;
          setIsLoading(true);
          try {
            await fetch("/auth/start",{
              method:"POST",
              headers:{'Content-Type':'application/json'},
              body:JSON.stringify({email})
            });
            onSent();
          } catch (error) {
            console.error("Failed to send magic link:", error);
            setIsLoading(false);
          }
        }}
        style={{padding:"8px 12px", background: isLoading ? "#333" : "#0066cc", color:"#fff", border:"none", cursor: isLoading ? "default" : "pointer"}}
        disabled={isLoading}
      >
        {isLoading ? "Sending..." : "Send magic link"}
      </button>
      <p style={{color:"#666", marginTop: 12}}>We'll email you a link. Click it, you're in.</p>
    </div>
  );
}

function CLI() {
  const [connected, setConnected] = useState(false);
  const [input, setInput] = useState("");
  const preRef = useRef<HTMLPreElement>(null);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    const ws = new WebSocket((location.protocol === "https:" ? "wss://" : "ws://") + location.host + "/ws");
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

    function log(s: string){
      if(preRef.current){
        preRef.current.textContent += s;
        preRef.current.scrollTop = preRef.current.scrollHeight;
      }
    }

    return () => ws.close();
  }, []);

  const send = () => {
    if (!input.trim() || !connected) return;

    // Echo the user's input
    if (preRef.current) {
      preRef.current.textContent += `> ${input}\n`;
      preRef.current.scrollTop = preRef.current.scrollHeight;
    }

    wsRef.current?.send(JSON.stringify({ prompt: input }));
    setInput("");
  };

  return (
    <div style={{display:"grid", gridTemplateRows:"1fr auto", height:"100vh", fontFamily:"ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace"}}>
      <pre
        ref={preRef}
        style={{
          margin:0,
          padding:12,
          overflow:"auto",
          whiteSpace:"pre-wrap",
          background:"#0b0b0b",
          color:"#e6e6e6",
          fontSize: "14px",
          lineHeight: "1.4"
        }}
      />
      <div style={{display:"flex", gap:8, padding:8, borderTop:"1px solid #222", background:"#111"}}>
        <input
          value={input}
          onChange={(e)=>setInput(e.target.value)}
          onKeyDown={(e)=>{
            if(e.key==="Enter" && !e.shiftKey){
              e.preventDefault();
              send();
            }
          }}
          placeholder={connected ? "Ask Claude anything..." : "Connecting..."}
          style={{
            flex:1,
            padding:10,
            background:"#000",
            color:"#fff",
            border:"1px solid #333",
            fontSize: "14px"
          }}
          disabled={!connected}
        />
        <button
          onClick={send}
          style={{
            padding:"10px 14px",
            background: connected ? "#0066cc" : "#333",
            color:"#fff",
            border:"none",
            cursor: connected ? "pointer" : "default"
          }}
          disabled={!connected}
        >
          Send
        </button>
      </div>
    </div>
  );
}

function App(){
  const [sent, setSent] = useState(false);
  const [authed, setAuthed] = useState<boolean | null>(null);

  useEffect(()=>{
    fetch("/auth/verify-ping",{method:"HEAD"})
      .then(r=>setAuthed(r.ok))
      .catch(()=>setAuthed(false));
  },[]);

  if (authed === null) {
    return (
      <div style={{
        padding:20,
        fontFamily:"system-ui",
        display:"flex",
        justifyContent:"center",
        alignItems:"center",
        height:"100vh"
      }}>
        Loading...
      </div>
    );
  }

  if (authed) return <CLI />;

  return sent ? (
    <div style={{
      maxWidth:420,
      margin:"10vh auto",
      fontFamily:"system-ui",
      textAlign:"center"
    }}>
      <h3>Check your email</h3>
      <p style={{color:"#666", marginTop: 12}}>Click the link we sent to sign in.</p>
    </div>
  ) : (
    <Login onSent={()=>setSent(true)} />
  );
}

createRoot(document.getElementById("root")!).render(<App/>);