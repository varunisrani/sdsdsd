@echo off
setlocal enabledelayedexpansion

echo Testing GLM-4.6 Agent SDK Container...
echo =====================================

REM Check if .env exists
if not exist .env (
    echo Error: .env file not found
    echo Create .env file first: copy .env.glm-example .env
    pause
    exit /b 1
)

REM Load environment variables from .env
echo Loading environment...
set "ANTHROPIC_BASE_URL="
set "ANTHROPIC_AUTH_TOKEN="
set "CLAUDE_AGENT_SDK_CONTAINER_API_KEY="
set "GITHUB_CLIENT_ID="
set "GITHUB_CLIENT_SECRET="
set "ALLOWED_GITHUB_USERS="
set "ALLOWED_GITHUB_ORG="
set "GLM_MODEL="
set "SESSION_SECRET="
set "PORT="

REM Parse .env file (handle comments and empty lines)
for /f "tokens=1,2 delims==" %%a in ('findstr /v /c:"#" .env ^| findstr /v /c:"^$"') do (
    if not "%%b"=="" (
        set "%%a=%%b"
    )
)

REM Check if tokens are set (GLM-4.6 or Claude)
if "!ANTHROPIC_AUTH_TOKEN!"=="" if "!CLAUDE_CODE_OAUTH_TOKEN!"=="" (
    echo Error: ANTHROPIC_AUTH_TOKEN or CLAUDE_CODE_OAUTH_TOKEN not set in .env
    pause
    exit /b 1
)

REM Determine which AI provider is configured
if not "!ANTHROPIC_AUTH_TOKEN!"=="" (
    set "AI_PROVIDER=GLM-4.6"
    echo Using GLM-4.6 AI provider
) else (
    set "AI_PROVIDER=Claude"
    echo Using Claude AI provider
)

echo Environment loaded

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Docker is not running. Please start Docker.
    pause
    exit /b 1
)

REM Get container name from directory (sanitize for Docker)
for %%F in ("%CD%") do set "DIR_NAME=%%~nF"
set "DIR_NAME_SAFE=!DIR_NAME!"
set "DIR_NAME_SAFE=!DIR_NAME_SAFE: =-!"
set "DIR_NAME_SAFE=!DIR_NAME_SAFE: =!"
set "DIR_NAME_SAFE=!DIR_NAME_SAFE:(=!"
set "DIR_NAME_SAFE=!DIR_NAME_SAFE:)=!"
set "DIR_NAME_SAFE=!DIR_NAME_SAFE:[=!"
set "DIR_NAME_SAFE=!DIR_NAME_SAFE:]=!"
set "CONTAINER_NAME=glm-!DIR_NAME_SAFE!"
set "IMAGE_NAME=glm-!DIR_NAME_SAFE!"

echo Container will be named: !CONTAINER_NAME!

REM Check if Docker image exists
docker images | findstr /i "!IMAGE_NAME!" >nul
if %errorlevel% neq 0 (
    echo Building Docker image...
    docker build -t "!IMAGE_NAME!" .
    if %errorlevel% neq 0 (
        echo Docker build failed
        pause
        exit /b 1
    )
) else (
    echo Docker image already exists
)

REM Check if container is already running
docker ps | findstr /i "!CONTAINER_NAME!" >nul
if %errorlevel% equ 0 (
    echo Container is already running
) else (
    REM Stop and remove existing container if it exists
    docker ps -a | findstr /i "!CONTAINER_NAME!" >nul
    if %errorlevel% equ 0 (
        echo Removing existing container...
        docker stop "!CONTAINER_NAME!" >nul 2>&1
        docker rm "!CONTAINER_NAME!" >nul 2>&1
    )

    echo Starting container...
    docker run -d --name "!CONTAINER_NAME!" -p 8082:8080 --env-file .env "!IMAGE_NAME!"
    if %errorlevel% neq 0 (
        echo Failed to start container
        pause
        exit /b 1
    )

    echo Waiting for container to start...
    timeout /t 5 /nobreak >nul
)

echo Testing health endpoint...
powershell -Command "try { $response = Invoke-RestMethod -Uri 'http://localhost:8082/health' -UseBasicParsing; Write-Host $response | ConvertTo-Json -Compress } catch { Write-Host 'FAILED' }" > "%temp%\health_check.txt"

set /p HEALTH_RESPONSE=<"%temp%\health_check.txt"

echo "!HEALTH_RESPONSE!" | findstr /i "failed" >nul
if %errorlevel% equ 0 (
    echo Health check failed
    pause
    exit /b 1
)

echo "!HEALTH_RESPONSE!" | findstr /i "healthy" >nul
if %errorlevel% equ 0 (
    echo Health check passed - !AI_PROVIDER! is responding
) else (
    echo Health check unhealthy - check AI provider token
    echo Provider: !AI_PROVIDER!
    echo Response: !HEALTH_RESPONSE!
)

echo Testing query endpoint...
if not "!CLAUDE_AGENT_SDK_CONTAINER_API_KEY!"=="" (
    echo Testing with API key protection...
    powershell -Command "$body = @{ prompt = 'Say hello in 3 words' } | ConvertTo-Json -Compress; try { $response = Invoke-RestMethod -Uri 'http://localhost:8082/query' -Method POST -ContentType 'application/json' -Headers @{ 'X-API-Key' = '!CLAUDE_AGENT_SDK_CONTAINER_API_KEY!' } -Body $body -UseBasicParsing; Write-Host $response | ConvertTo-Json -Compress } catch { Write-Host 'FAILED' }" > "%temp%\query_response.txt"
) else (
    echo Testing without API key protection...
    powershell -Command "$body = @{ prompt = 'Say hello in 3 words' } | ConvertTo-Json -Compress; try { $response = Invoke-RestMethod -Uri 'http://localhost:8082/query' -Method POST -ContentType 'application/json' -Body $body -UseBasicParsing; Write-Host $response | ConvertTo-Json -Compress } catch { Write-Host 'FAILED' }" > "%temp%\query_response.txt"
)

set /p QUERY_RESPONSE=<"%temp%\query_response.txt"

echo "!QUERY_RESPONSE!" | findstr /i "failed" >nul
if %errorlevel% equ 0 (
    echo Query failed
    pause
    exit /b 1
)

echo "!QUERY_RESPONSE!" | findstr /i "success" >nul
if %errorlevel% equ 0 (
    echo Query successful
) else (
    echo Query failed: !QUERY_RESPONSE!
    pause
    exit /b 1
)

echo.
echo ==========================================
echo All tests passed!
echo 🎉 !AI_PROVIDER! container is running successfully!
echo.
echo 🌐 Web CLI: http://localhost:8082
echo 🔧 API: POST http://localhost:8082/query
echo.
echo 💡 Note: You're using !AI_PROVIDER! as the AI provider
echo.
echo Container Details:
echo   Name: !CONTAINER_NAME!
echo   Model: !GLM_MODEL!
echo   Port: 8080
echo.
echo To stop the container: docker stop !CONTAINER_NAME!
echo To view logs: docker logs !CONTAINER_NAME!
echo ==========================================

REM Clean up temp files
del "%temp%\health_check.txt" >nul 2>&1
del "%temp%\query_response.txt" >nul 2>&1

echo.
echo Press any key to open the web interface...
pause >nul

REM Open browser
start http://localhost:8082

endlocal