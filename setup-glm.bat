@echo off
setlocal enabledelayedexpansion

echo 🚀 GLM-4.6 Agent SDK Container - Automated Setup
echo ==================================================
echo.
echo This script will guide you through the complete GLM-4.6 setup process:
echo   1. Get your GLM-4.6 API key from Z.AI
echo   2. Create a GitHub App (one click!)
echo   3. Configure access control
echo   4. Generate all necessary credentials
echo.

REM ============================================
REM STEP 1: Get GLM-4.6 API Key
REM ============================================
echo 📋 Step 1: Getting your GLM-4.6 API Key
echo -------------------------------------------
echo.
echo Please visit https://z.ai to get your GLM-4.6 API key.
echo.
echo Steps:
echo   1. Go to https://z.ai and sign up/login
echo   2. Navigate to API section
echo   3. Generate or copy your API key
echo   4. The key should start with your unique identifier
echo.

echo Please paste your GLM-4.6 API key here:
echo ^(Your API key from z.ai^)
set /p "GLM_API_KEY="

if "!GLM_API_KEY!"=="" (
    echo ❌ Error: No API key provided
    pause
    exit /b 1
)

echo.
echo ✅ GLM-4.6 API key captured: !GLM_API_KEY:~0,16!...
echo.

REM ============================================
REM STEP 2: Generate API Key
REM ============================================
echo 📋 Step 2: Generating Container API Key
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
    set "APP_NAME=glm-agent-sdk-!TIMESTAMP!"

    echo Creating GitHub App: !APP_NAME!
    echo.
    echo Opening browser for one-click creation...
    echo.

    REM Start the GitHub App setup server
    echo Starting GitHub App setup server...
    start /B node setup-github-app.cjs "!APP_NAME!"

    REM Wait for server to start
    timeout /t 2 /nobreak >nul

    echo ⏳ Waiting for you to click 'Create GitHub App' in the browser...
    echo.
    echo If the browser didn't open, visit: http://localhost:8765
    echo.

    REM Wait for credentials file to be created
    :wait_for_creds
    if not exist "github-app-credentials.json" (
        timeout /t 1 /nobreak >nul
        goto wait_for_creds
    )

    REM Extract credentials from JSON file
    for /f "tokens=2 delims=:" %%i in ('findstr /c:"\"client_id\"" github-app-credentials.json') do set "GITHUB_CLIENT_ID=%%i"
    for /f "tokens=2 delims=:" %%i in ('findstr /c:"\"client_secret\"" github-app-credentials.json') do set "GITHUB_CLIENT_SECRET=%%i"

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
    del "github-app-credentials.json" >nul 2>nul
)

REM ============================================
REM STEP 4: Configure Access Control
REM ============================================
echo 📋 Step 4: Access Control Configuration
echo -------------------------------------------
echo.
echo For security, you must configure who can access the GLM-4.6 web CLI.
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
echo # GLM-4.6 Configuration for Claude Agent SDK Container
echo.
echo # GLM-4.6 API Configuration (Required)
echo ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
echo ANTHROPIC_AUTH_TOKEN=!GLM_API_KEY!
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

(
echo.
echo # Model configuration
echo GLM_MODEL=GLM-4.6
echo.
echo # Session secret for JWT signing
echo SESSION_SECRET=!API_KEY!
) >> .env

echo ✅ Created .env file with all credentials
echo.

REM ============================================
REM COMPLETE!
REM ============================================
echo 🎉 GLM-4.6 Setup Complete!
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

echo Configuration Summary:
echo   ✅ AI Provider: GLM-4.6 (Z.AI)
echo   ✅ Model: GLM-4.6
echo   ✅ API Base URL: https://api.z.ai/api/anthropic
echo   ✅ GitHub OAuth: Configured
echo   ✅ Container API Key: Generated
echo.

echo Next steps:
echo   1. Return to Claude Code and ask: 'Please run ./test.sh'
echo   2. Once running, open: http://localhost:8080
echo   3. Sign in with GitHub and enjoy GLM-4.6!
echo.

echo Your container API key for REST access:
echo   !API_KEY!
echo.

echo 🚀 You're all set to use GLM-4.6 instead of Claude!
echo 💰 Cost-effective alternative with full API compatibility!
echo.

REM Clean up temp files
del "%temp%\claude_output.txt" >nul 2>nul

echo.
echo Setup complete! Press any key to exit...
pause >nul
exit /b 0