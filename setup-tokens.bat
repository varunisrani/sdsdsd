@echo off
setlocal enabledelayedexpansion

echo 🚀 Claude Agent SDK Container - Automated Setup
echo ================================================
echo.
echo This script will guide you through the complete setup process:
echo   1. Get your Claude OAuth token
echo   2. Create a GitHub App (one click!)
echo   3. Configure access control
echo   4. Generate all necessary credentials
echo.

REM Check if Claude CLI is installed
where claude >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Error: Claude CLI not found
    echo.
    echo Please install Claude Code first:
    echo   https://docs.claude.com/en/docs/claude-code/overview
    pause
    exit /b 1
)

echo ✅ Claude CLI detected
echo.

REM ============================================
REM STEP 1: Get Claude OAuth Token
REM ============================================
echo 📋 Step 1: Getting your Claude OAuth Token
echo -------------------------------------------
echo.
echo This will open your browser to authenticate with Anthropic.
echo After login, you'll see your OAuth token in the terminal.
echo.
pause

echo.
echo Running: claude setup-token
echo.

REM Run claude setup-token and capture output
echo Running: claude setup-token
claude setup-token
echo.
echo ⚠️  Could not automatically extract token from output.
echo.
echo Please paste your Claude OAuth token here:
echo ^(It starts with sk-ant-oat01-...^)
set /p "CLAUDE_TOKEN="

REM If no token found, ask user to paste it
if "!CLAUDE_TOKEN!"=="" (
    echo.
    echo ⚠️  Could not automatically extract token from output.
    echo.
    echo Please paste your Claude OAuth token here:
    echo ^(It starts with sk-ant-oat01-...^)
    set /p "CLAUDE_TOKEN="
)

if "!CLAUDE_TOKEN!"=="" (
    echo ❌ Error: No token provided
    pause
    exit /b 1
)

echo.
echo ✅ Claude token captured: !CLAUDE_TOKEN:~0,20!...
echo.

REM ============================================
REM STEP 2: Generate API Key
REM ============================================
echo 📋 Step 2: Generating API Key
echo -------------------------------------------
echo.

REM Generate random API key using PowerShell
for /f "delims=" %%i in ('powershell -Command "-join (1..64 | ForEach-Object {[char](48..90 + 97..122 | Get-Random)})"') do set "API_KEY=%%i"

echo ✅ Generated API key: !API_KEY:~0,16!...
echo.

REM ============================================
REM STEP 3: GitHub App Setup
REM ============================================
echo 📋 Step 3: GitHub App Setup
echo -------------------------------------------
echo.

REM Check if GitHub credentials already exist in .env
set "GITHUB_CLIENT_ID="
set "GITHUB_CLIENT_SECRET="

if exist .env (
    for /f "tokens=2 delims==" %%i in ('findstr "^GITHUB_CLIENT_ID=" .env 2^>nul') do set "EXISTING_CLIENT_ID=%%i"
    for /f "tokens=2 delims==" %%i in ('findstr "^GITHUB_CLIENT_SECRET=" .env 2^>nul') do set "EXISTING_CLIENT_SECRET=%%i"

    if not "!EXISTING_CLIENT_ID!"=="" if not "!EXISTING_CLIENT_SECRET!"=="" (
        echo ✅ GitHub App credentials already configured
        echo    Client ID: !EXISTING_CLIENT_ID!
        echo.
        set "GITHUB_CLIENT_ID=!EXISTING_CLIENT_ID!"
        set "GITHUB_CLIENT_SECRET=!EXISTING_CLIENT_SECRET!"
    )
)

REM Only create new GitHub App if credentials don't exist
if "!GITHUB_CLIENT_ID!"=="" (
    REM Generate unique app name using timestamp
    for /f %%i in ('powershell -Command "Get-Date -Format 'yyyyMMddHHmm'"') do set "TIMESTAMP=%%i"
    set "APP_NAME=claude-agent-sdk-!TIMESTAMP!"

    echo Creating GitHub App: !APP_NAME!
    echo.
    echo Opening browser for one-click creation...
    echo.

    REM Create temporary server script
    echo const http = require('http'); > "%temp%\github-app-setup-server.js"
    echo const fs = require('fs'); >> "%temp%\github-app-setup-server.js"
    echo const { URL } = require('url'); >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo const PORT = 8765; >> "%temp%\github-app-setup-server.js"
    echo const APP_NAME = "!APP_NAME!"; >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo const manifest = { >> "%temp%\github-app-setup-server.js"
    echo   name: APP_NAME, >> "%temp%\github-app-setup-server.js"
    echo   url: "http://localhost:8080", >> "%temp%\github-app-setup-server.js"
    echo   redirect_url: `http://localhost:${PORT}/callback`, >> "%temp%\github-app-setup-server.js"
    echo   callback_urls: ["http://localhost:8080/auth/github"], >> "%temp%\github-app-setup-server.js"
    echo   request_oauth_on_install: true, >> "%temp%\github-app-setup-server.js"
    echo   setup_on_update: false, >> "%temp%\github-app-setup-server.js"
    echo   public: false, >> "%temp%\github-app-setup-server.js"
    echo   default_permissions: { >> "%temp%\github-app-setup-server.js"
    echo     emails: "read", >> "%temp%\github-app-setup-server.js"
    echo     members: "read" >> "%temp%\github-app-setup-server.js"
    echo   }, >> "%temp%\github-app-setup-server.js"
    echo   default_events: [] >> "%temp%\github-app-setup-server.js"
    echo }; >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo const server = http.createServer(async (req, res) =^> { >> "%temp%\github-app-setup-server.js"
    echo   const url = new URL(req.url, `http://localhost:${PORT}`); >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo   if (url.pathname === '/') { >> "%temp%\github-app-setup-server.js"
    echo     res.writeHead(200, { 'Content-Type': 'text/html' }); >> "%temp%\github-app-setup-server.js"
    echo     res.end(` >> "%temp%\github-app-setup-server.js"
    echo ^<!DOCTYPE html^> >> "%temp%\github-app-setup-server.js"
    echo ^<html^> >> "%temp%\github-app-setup-server.js"
    echo ^<head^> >> "%temp%\github-app-setup-server.js"
    echo   ^<meta charset="UTF-8"^> >> "%temp%\github-app-setup-server.js"
    echo   ^<title^>GitHub App Setup^</title^> >> "%temp%\github-app-setup-server.js"
    echo   ^<style^> >> "%temp%\github-app-setup-server.js"
    echo     body { >> "%temp%\github-app-setup-server.js"
    echo       font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; >> "%temp%\github-app-setup-server.js"
    echo       max-width: 600px; >> "%temp%\github-app-setup-server.js"
    echo       margin: 50px auto; >> "%temp%\github-app-setup-server.js"
    echo       padding: 20px; >> "%temp%\github-app-setup-server.js"
    echo       background: #0d1117; >> "%temp%\github-app-setup-server.js"
    echo       color: #c9d1d9; >> "%temp%\github-app-setup-server.js"
    echo     } >> "%temp%\github-app-setup-server.js"
    echo     h1 { color: #58a6ff; } >> "%temp%\github-app-setup-server.js"
    echo     .button { >> "%temp%\github-app-setup-server.js"
    echo       background: #238636; >> "%temp%\github-app-setup-server.js"
    echo       color: white; >> "%temp%\github-app-setup-server.js"
    echo       border: none; >> "%temp%\github-app-setup-server.js"
    echo       padding: 12px 24px; >> "%temp%\github-app-setup-server.js"
    echo       font-size: 16px; >> "%temp%\github-app-setup-server.js"
    echo       border-radius: 6px; >> "%temp%\github-app-setup-server.js"
    echo       cursor: pointer; >> "%temp%\github-app-setup-server.js"
    echo       font-weight: 600; >> "%temp%\github-app-setup-server.js"
    echo     } >> "%temp%\github-app-setup-server.js"
    echo     .button:hover { background: #2ea043; } >> "%temp%\github-app-setup-server.js"
    echo     .info { >> "%temp%\github-app-setup-server.js"
    echo       background: #161b22; >> "%temp%\github-app-setup-server.js"
    echo       padding: 15px; >> "%temp%\github-app-setup-server.js"
    echo       border-radius: 6px; >> "%temp%\github-app-setup-server.js"
    echo       margin: 20px 0; >> "%temp%\github-app-setup-server.js"
    echo       border-left: 3px solid #58a6ff; >> "%temp%\github-app-setup-server.js"
    echo     } >> "%temp%\github-app-setup-server.js"
    echo   ^</style^> >> "%temp%\github-app-setup-server.js"
    echo ^</head^> >> "%temp%\github-app-setup-server.js"
    echo ^<body^> >> "%temp%\github-app-setup-server.js"
    echo   ^<h1^>🚀 Create GitHub App^</h1^> >> "%temp%\github-app-setup-server.js"
    echo   ^<div class="info"^> >> "%temp%\github-app-setup-server.js"
    echo     ^<p^>^<strong^>App name:^</strong^> ${APP_NAME}^</p^> >> "%temp%\github-app-setup-server.js"
    echo     ^<p^>^<strong^>What this does:^</strong^>^</p^> >> "%temp%\github-app-setup-server.js"
    echo     ^<ul^> >> "%temp%\github-app-setup-server.js"
    echo       ^<li^>Creates a GitHub App for OAuth authentication^</li^> >> "%temp%\github-app-setup-server.js"
    echo       ^<li^>Requests only email and profile read permissions^</li^> >> "%temp%\github-app-setup-server.js"
    echo       ^<li^>Automatically configures callback URLs^</li^> >> "%temp%\github-app-setup-server.js"
    echo     ^</ul^> >> "%temp%\github-app-setup-server.js"
    echo   ^</div^> >> "%temp%\github-app-setup-server.js"
    echo   ^<p^>Click the button below to create the GitHub App:^</p^> >> "%temp%\github-app-setup-server.js"
    echo   ^<form action="https://github.com/settings/apps/new" method="post"^> >> "%temp%\github-app-setup-server.js"
    echo     ^<input type="hidden" name="manifest" value='${JSON.stringify(manifest)}'^> >> "%temp%\github-app-setup-server.js"
    echo     ^<button type="submit" class="button"^>Create GitHub App^</button^> >> "%temp%\github-app-setup-server.js"
    echo   ^</form^> >> "%temp%\github-app-setup-server.js"
    echo   ^<p style="margin-top: 30px; color: #8b949e; font-size: 14px;"^> >> "%temp%\github-app-setup-server.js"
    echo     After clicking, GitHub will ask you to confirm the app creation.^<br^> >> "%temp%\github-app-setup-server.js"
    echo     Just click "Create GitHub App" and you'll be redirected back here automatically. >> "%temp%\github-app-setup-server.js"
    echo   ^</p^> >> "%temp%\github-app-setup-server.js"
    echo ^</body^> >> "%temp%\github-app-setup-server.js"
    echo ^</html^> >> "%temp%\github-app-setup-server.js"
    echo     `); >> "%temp%\github-app-setup-server.js"
    echo   } else if (url.pathname === '/callback') { >> "%temp%\github-app-setup-server.js"
    echo     const code = url.searchParams.get('code'); >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo     if (!code) { >> "%temp%\github-app-setup-server.js"
    echo       res.writeHead(400, { 'Content-Type': 'text/html' }); >> "%temp%\github-app-setup-server.js"
    echo       res.end('^<h1^>Error: No code received^</h1^>'); >> "%temp%\github-app-setup-server.js"
    echo       return; >> "%temp%\github-app-setup-server.js"
    echo     } >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo     try { >> "%temp%\github-app-setup-server.js"
    echo       const response = await fetch(`https://api.github.com/app-manifests/${code}/conversions`, { >> "%temp%\github-app-setup-server.js"
    echo         method: 'POST', >> "%temp%\github-app-setup-server.js"
    echo         headers: { >> "%temp%\github-app-setup-server.js"
    echo           'Accept': 'application/vnd.github+json', >> "%temp%\github-app-setup-server.js"
    echo           'X-GitHub-Api-Version': '2022-11-28' >> "%temp%\github-app-setup-server.js"
    echo         } >> "%temp%\github-app-setup-server.js"
    echo       }); >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo       if (!response.ok) { >> "%temp%\github-app-setup-server.js"
    echo         throw new Error(`GitHub API error: ${response.status}`); >> "%temp%\github-app-setup-server.js"
    echo       } >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo       const credentials = await response.json(); >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo       fs.writeFileSync('%temp%\github-app-credentials.json', JSON.stringify(credentials, null, 2)); >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo       res.writeHead(200, { 'Content-Type': 'text/html' }); >> "%temp%\github-app-setup-server.js"
    echo       res.end(` >> "%temp%\github-app-setup-server.js"
    echo ^<!DOCTYPE html^> >> "%temp%\github-app-setup-server.js"
    echo ^<html^> >> "%temp%\github-app-setup-server.js"
    echo ^<head^> >> "%temp%\github-app-setup-server.js"
    echo   ^<meta charset="UTF-8"^> >> "%temp%\github-app-setup-server.js"
    echo   ^<title^>Success!^</title^> >> "%temp%\github-app-setup-server.js"
    echo   ^<style^> >> "%temp%\github-app-setup-server.js"
    echo     body { >> "%temp%\github-app-setup-server.js"
    echo       font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; >> "%temp%\github-app-setup-server.js"
    echo       max-width: 600px; >> "%temp%\github-app-setup-server.js"
    echo       margin: 50px auto; >> "%temp%\github-app-setup-server.js"
    echo       padding: 20px; >> "%temp%\github-app-setup-server.js"
    echo       background: #0d1117; >> "%temp%\github-app-setup-server.js"
    echo       color: #c9d1d9; >> "%temp%\github-app-setup-server.js"
    echo       text-align: center; >> "%temp%\github-app-setup-server.js"
    echo     } >> "%temp%\github-app-setup-server.js"
    echo     h1 { color: #3fb950; } >> "%temp%\github-app-setup-server.js"
    echo     .success { >> "%temp%\github-app-setup-server.js"
    echo       background: #161b22; >> "%temp%\github-app-setup-server.js"
    echo       padding: 20px; >> "%temp%\github-app-setup-server.js"
    echo       border-radius: 6px; >> "%temp%\github-app-setup-server.js"
    echo       margin: 20px 0; >> "%temp%\github-app-setup-server.js"
    echo       border-left: 3px solid #3fb950; >> "%temp%\github-app-setup-server.js"
    echo     } >> "%temp%\github-app-setup-server.js"
    echo   ^</style^> >> "%temp%\github-app-setup-server.js"
    echo ^</head^> >> "%temp%\github-app-setup-server.js"
    echo ^<body^> >> "%temp%\github-app-setup-server.js"
    echo   ^<h1^>✅ GitHub App Created Successfully!^</h1^> >> "%temp%\github-app-setup-server.js"
    echo   ^<div class="success"^> >> "%temp%\github-app-setup-server.js"
    echo     ^<p^>Your GitHub App credentials have been captured.^</p^> >> "%temp%\github-app-setup-server.js"
    echo     ^<p^>You can close this window and return to your terminal.^</p^> >> "%temp%\github-app-setup-server.js"
    echo   ^</div^> >> "%temp%\github-app-setup-server.js"
    echo ^</body^> >> "%temp%\github-app-setup-server.js"
    echo ^</html^> >> "%temp%\github-app-setup-server.js"
    echo       `); >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo       setTimeout(() =^> { >> "%temp%\github-app-setup-server.js"
    echo         server.close(); >> "%temp%\github-app-setup-server.js"
    echo         process.exit(0); >> "%temp%\github-app-setup-server.js"
    echo       }, 2000); >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo     } catch (error) { >> "%temp%\github-app-setup-server.js"
    echo       res.writeHead(500, { 'Content-Type': 'text/html' }); >> "%temp%\github-app-setup-server.js"
    echo       res.end(`^<h1^>Error: ${error.message}^</h1^>`); >> "%temp%\github-app-setup-server.js"
    echo     } >> "%temp%\github-app-setup-server.js"
    echo   } else { >> "%temp%\github-app-setup-server.js"
    echo     res.writeHead(404); >> "%temp%\github-app-setup-server.js"
    echo     res.end('Not Found'); >> "%temp%\github-app-setup-server.js"
    echo   } >> "%temp%\github-app-setup-server.js"
    echo }); >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo server.listen(PORT, () =^> { >> "%temp%\github-app-setup-server.js"
    echo   console.log(`Setup server running at http://localhost:${PORT}`); >> "%temp%\github-app-setup-server.js"
    echo   console.log(''); >> "%temp%\github-app-setup-server.js"
    echo   console.log('Opening browser...'); >> "%temp%\github-app-setup-server.js"
    echo. >> "%temp%\github-app-setup-server.js"
    echo   const open = process.platform === 'darwin' ? 'open' : >> "%temp%\github-app-setup-server.js"
    echo                process.platform === 'win32' ? 'start' : 'xdg-open'; >> "%temp%\github-app-setup-server.js"
    echo   require('child_process').exec(`${open} http://localhost:${PORT}`); >> "%temp%\github-app-setup-server.js"
    echo }); >> "%temp%\github-app-setup-server.js"

    REM Start the server
    start /B node "%temp%\github-app-setup-server.js"

    REM Wait for server to start
    timeout /t 2 /nobreak >nul

    echo ⏳ Waiting for you to click 'Create GitHub App' in the browser...
    echo.
    echo If the browser didn't open, visit: http://localhost:8765
    echo.

    REM Wait for credentials file to be created
    :wait_for_creds
    if not exist "%temp%\github-app-credentials.json" (
        timeout /t 1 /nobreak >nul
        goto wait_for_creds
    )

    REM Extract credentials from JSON file
    for /f "tokens=2 delims=:" %%i in ('findstr /c:"\"client_id\"" "%temp%\github-app-credentials.json"') do set "GITHUB_CLIENT_ID=%%i"
    for /f "tokens=2 delims=:" %%i in ('findstr /c:"\"client_secret\"" "%temp%\github-app-credentials.json"') do set "GITHUB_CLIENT_SECRET=%%i"

    REM Clean up quotes and spaces
    set "GITHUB_CLIENT_ID=!GITHUB_CLIENT_ID: =!"
    set "GITHUB_CLIENT_ID=!GITHUB_CLIENT_ID:"=!"
    set "GITHUB_CLIENT_ID=!GITHUB_CLIENT_ID:,=!"
    set "GITHUB_CLIENT_SECRET=!GITHUB_CLIENT_SECRET: =!"
    set "GITHUB_CLIENT_SECRET=!GITHUB_CLIENT_SECRET:"=!"
    set "GITHUB_CLIENT_SECRET=!GITHUB_CLIENT_SECRET:,=!"

    echo.
    echo ✅ GitHub App created successfully!
    echo    App Name: !APP_NAME!
    echo    Client ID: !GITHUB_CLIENT_ID!
    echo.

    REM Clean up temp files
    del "%temp%\github-app-credentials.json" >nul 2>nul
    del "%temp%\github-app-setup-server.js" >nul 2>nul
)

REM ============================================
REM STEP 4: Configure Access Control
REM ============================================
echo 📋 Step 4: Access Control Configuration
echo -------------------------------------------
echo.
echo For security, you must configure who can access the web CLI.
echo.

REM Try to get GitHub username if gh CLI is available
set "GH_USERNAME="
where gh >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('gh auth status 2^>nul ^&^& gh api /user --jq .login 2^>nul') do set "GH_USERNAME=%%i"
)

set "ALLOWED_USERS="
if not "!GH_USERNAME!"=="" (
    set "ALLOWED_USERS=!GH_USERNAME!"
    echo ✅ Your GitHub username '!GH_USERNAME!' has been added to the allowlist.
    echo.
    set /p "add_users=Would you like to add additional GitHub usernames? (y/N): "
    if /i "!add_users!"=="y" (
        echo.
        set /p "ADDITIONAL_USERS=Enter additional usernames (comma-separated): "
        if not "!ADDITIONAL_USERS!"=="" (
            set "ALLOWED_USERS=!ALLOWED_USERS!,!ADDITIONAL_USERS!"
        )
    )
    echo.
) else (
    echo Option 1: Allow specific GitHub usernames (comma-separated)
    echo Option 2: Allow all members of a GitHub organization
    echo Option 3: Both
    echo.
    set /p "ALLOWED_USERS=Enter allowed GitHub usernames (or press ENTER to skip): "
)

set /p "ALLOWED_ORG=Enter allowed GitHub organization (or press ENTER to skip): "

if "!ALLOWED_USERS!"=="" if "!ALLOWED_ORG!"=="" (
    echo.
    echo ⚠️  Warning: You must configure at least one access control method!
    echo.
    set /p "ALLOWED_USERS=Enter allowed GitHub usernames (required): "

    if "!ALLOWED_USERS!"=="" (
        echo ❌ Error: Access control is required for security
        pause
        exit /b 1
    )
)

REM ============================================
REM STEP 5: Write .env file
REM ============================================
echo.
echo 📋 Step 5: Writing .env file
echo -------------------------------------------
echo.

(
echo # Claude OAuth Token
echo CLAUDE_CODE_OAUTH_TOKEN=!CLAUDE_TOKEN!
echo.
echo # API Key for REST endpoint protection
echo CLAUDE_AGENT_SDK_CONTAINER_API_KEY=!API_KEY!
echo.
echo # GitHub App Configuration
echo GITHUB_CLIENT_ID=!GITHUB_CLIENT_ID!
echo GITHUB_CLIENT_SECRET=!GITHUB_CLIENT_SECRET!
echo.
echo # GitHub Access Control
) > .env

if not "!ALLOWED_USERS!"=="" (
    echo ALLOWED_GITHUB_USERS=!ALLOWED_USERS! >> .env
)

if not "!ALLOWED_ORG!"=="" (
    echo ALLOWED_GITHUB_ORG=!ALLOWED_ORG! >> .env
)

echo ✅ Created .env file with all credentials
echo.

REM ============================================
REM COMPLETE!
REM ============================================
echo 🎉 Setup Complete!
echo ================================================
echo.
echo All credentials have been configured in .env
echo.

REM Show access control summary
echo Access Control:
if not "!ALLOWED_USERS!"=="" (
    echo   ✅ Allowed users: !ALLOWED_USERS!
)
if not "!ALLOWED_ORG!"=="" (
    echo   ✅ Allowed organization: !ALLOWED_ORG!
)
echo.

echo Next steps:
echo   1. Return to Claude Code and ask: 'Please run ./test.sh'
echo   2. Once running, open: http://localhost:8080
echo.
echo Your API key for REST access:
echo   !API_KEY!
echo.

REM Clean up temp files
del "%temp%\claude_output.txt" >nul 2>nul

echo.
echo Setup complete! Press any key to exit...
pause >nul
exit /b 0