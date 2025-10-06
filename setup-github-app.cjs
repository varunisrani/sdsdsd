const http = require('http');
const fs = require('fs');
const { URL } = require('url');

const PORT = 8765;
const APP_NAME = process.argv[2] || 'glm-agent-sdk';

const manifest = {
  name: APP_NAME,
  url: "http://localhost:8080",
  redirect_url: `http://localhost:${PORT}/callback`,
  callback_urls: ["http://localhost:8080/auth/github"],
  request_oauth_on_install: true,
  setup_on_update: false,
  public: false,
  default_permissions: {
    emails: "read",
    members: "read"
  },
  default_events: []
};

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  if (url.pathname === '/') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>GLM-4.6 GitHub App Setup</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      max-width: 600px;
      margin: 50px auto;
      padding: 20px;
      background: #0d1117;
      color: #c9d1d9;
    }
    h1 { color: #58a6ff; }
    .button {
      background: #238636;
      color: white;
      border: none;
      padding: 12px 24px;
      font-size: 16px;
      border-radius: 6px;
      cursor: pointer;
      font-weight: 600;
    }
    .button:hover { background: #2ea043; }
    .info {
      background: #161b22;
      padding: 15px;
      border-radius: 6px;
      margin: 20px 0;
      border-left: 3px solid #58a6ff;
    }
  </style>
</head>
<body>
  <h1>🚀 Create GLM-4.6 GitHub App</h1>

  <div class="info">
    <p><strong>App name:</strong> ${APP_NAME}</p>
    <p><strong>What this does:</strong></p>
    <ul>
      <li>Creates a GitHub App for OAuth authentication</li>
      <li>Requests only email and profile read permissions</li>
      <li>Enables secure access to your GLM-4.6 container</li>
    </ul>
  </div>

  <p>Click the button below to create the GitHub App:</p>

  <form action="https://github.com/settings/apps/new" method="post">
    <input type="hidden" name="manifest" value='${JSON.stringify(manifest)}'>
    <button type="submit" class="button">
      Create GitHub App
    </button>
  </form>

  <p style="margin-top: 30px; color: #8b949e; font-size: 14px;">
    After clicking, GitHub will ask you to confirm the app creation.<br>
    Just click "Create GitHub App" and you'll be redirected back here automatically.
  </p>
</body>
</html>
    `);
  } else if (url.pathname === '/callback') {
    const code = url.searchParams.get('code');

    if (!code) {
      res.writeHead(400, { 'Content-Type': 'text/html' });
      res.end('<h1>Error: No code received</h1>');
      return;
    }

    try {
      const response = await fetch(`https://api.github.com/app-manifests/${code}/conversions`, {
        method: 'POST',
        headers: {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28'
        }
      });

      if (!response.ok) {
        throw new Error(`GitHub API error: ${response.status}`);
      }

      const credentials = await response.json();
      fs.writeFileSync('github-app-credentials.json', JSON.stringify(credentials, null, 2));

      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(`
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Success!</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      max-width: 600px;
      margin: 50px auto;
      padding: 20px;
      background: #0d1117;
      color: #c9d1d9;
      text-align: center;
    }
    h1 { color: #3fb950; }
    .success {
      background: #161b22;
      padding: 20px;
      border-radius: 6px;
      margin: 20px 0;
      border-left: 3px solid #3fb950;
    }
  </style>
</head>
<body>
  <h1>✅ GLM-4.6 GitHub App Created Successfully!</h1>
  <div class="success">
    <p>Your GLM-4.6 GitHub App credentials have been captured.</p>
    <p>You can close this window and return to your terminal.</p>
  </div>
</body>
</html>
      `);

      setTimeout(() => {
        server.close();
        process.exit(0);
      }, 2000);

    } catch (error) {
      res.writeHead(500, { 'Content-Type': 'text/html' });
      res.end(`<h1>Error: ${error.message}</h1>`);
    }
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`GLM-4.6 setup server running at http://localhost:${PORT}`);
  console.log('');
  console.log('Opening browser...');

  const open = process.platform === 'darwin' ? 'open' :
               process.platform === 'win32' ? 'start' : 'xdg-open';
  require('child_process').exec(`${open} http://localhost:${PORT}`);
});