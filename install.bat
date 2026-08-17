@echo off
setlocal enabledelayedexpansion

echo.
echo  ============================================
echo   OSOS Code Review - Skill Installer
echo  ============================================
echo.

:: Source directory (where this batch file lives)
set "SOURCE=%~dp0"

:: Target: user-level .claude directory
set "TARGET=%USERPROFILE%\.claude"
set "TOKEN_FILE=%TARGET%\.github_token"

:: -----------------------------------------------
:: 1. Create target directories
:: -----------------------------------------------
if not exist "%TARGET%" mkdir "%TARGET%"
if not exist "%TARGET%\scripts" mkdir "%TARGET%\scripts"
if not exist "%TARGET%\references" mkdir "%TARGET%\references"

:: -----------------------------------------------
:: 2. Copy skill files
:: -----------------------------------------------
echo  [1/3] Copying skill files to %TARGET% ...

copy /Y "%SOURCE%SKILL.md" "%TARGET%\SKILL.md" >nul 2>&1
if errorlevel 1 (
    echo        ERROR: Failed to copy SKILL.md
    goto :fail
)

copy /Y "%SOURCE%scripts\*.sh" "%TARGET%\scripts\" >nul 2>&1
if errorlevel 1 (
    echo        ERROR: Failed to copy scripts
    goto :fail
)

copy /Y "%SOURCE%references\*.md" "%TARGET%\references\" >nul 2>&1
if errorlevel 1 (
    echo        ERROR: Failed to copy references
    goto :fail
)

echo        Done.

:: -----------------------------------------------
:: 3. GitHub Token Setup
:: -----------------------------------------------
echo.
echo  [2/3] GitHub Token Setup
echo.

set "NEED_TOKEN=1"

:: Check for existing saved token
if exist "%TOKEN_FILE%" (
    set /p SAVED_TOKEN=<"%TOKEN_FILE%"

    :: Trim whitespace / carriage returns
    for /f "tokens=* delims= " %%t in ("!SAVED_TOKEN!") do set "SAVED_TOKEN=%%t"

    if not "!SAVED_TOKEN!"=="" (
        echo        Found saved token. Validating...

        :: Validate against GitHub API
        set "HTTP_CODE=000"
        for /f %%a in ('curl -s -o nul -w "%%{http_code}" -H "Authorization: Bearer !SAVED_TOKEN!" "https://api.github.com/user" 2^>nul') do set "HTTP_CODE=%%a"

        if "!HTTP_CODE!"=="200" (
            echo        Token is valid. No changes needed.
            set "NEED_TOKEN=0"
        ) else (
            echo        Token is expired or invalid ^(HTTP !HTTP_CODE!^).
        )
    )
)

if "!NEED_TOKEN!"=="1" (
    echo        Enter your GitHub Personal Access Token
    echo        ^(classic PAT with 'repo' scope^):
    echo.
    set /p "NEW_TOKEN=        Token: "

    if "!NEW_TOKEN!"=="" (
        echo.
        echo        WARNING: No token entered. You can run install.bat again later.
        goto :skip_token
    )

    echo        Validating token...

    set "HTTP_CODE=000"
    for /f %%a in ('curl -s -o nul -w "%%{http_code}" -H "Authorization: Bearer !NEW_TOKEN!" "https://api.github.com/user" 2^>nul') do set "HTTP_CODE=%%a"

    if "!HTTP_CODE!"=="200" (
        echo        Token is valid. Saving...
        >"%TOKEN_FILE%" echo !NEW_TOKEN!
        echo        Saved to %TOKEN_FILE%
    ) else if "!HTTP_CODE!"=="000" (
        echo.
        echo        ERROR: Could not reach GitHub. Is curl installed and internet available?
        echo        Token NOT saved. Run install.bat again when ready.
        goto :skip_token
    ) else (
        echo        WARNING: Token validation failed ^(HTTP !HTTP_CODE!^).
        echo.
        set /p "SAVE_ANYWAY=        Save anyway? (Y/N): "
        if /i "!SAVE_ANYWAY!"=="Y" (
            >"%TOKEN_FILE%" echo !NEW_TOKEN!
            echo        Token saved.
        ) else (
            echo        Token NOT saved. Run install.bat again when ready.
        )
    )
)

:skip_token

:: -----------------------------------------------
:: 4. Summary
:: -----------------------------------------------
echo.
echo  [3/3] Installation complete!
echo.
echo  ============================================
echo   Installed files:
echo     %TARGET%\SKILL.md
echo     %TARGET%\scripts\  (4 scripts)
echo     %TARGET%\references\  (6 rule files)
echo.
if exist "%TOKEN_FILE%" (
    echo   Token: saved at %TOKEN_FILE%
) else (
    echo   Token: NOT configured (run install.bat again)
)
echo  ============================================
echo.
echo   The OSOS Code Review skill is now available
echo   globally in Claude Code from any project.
echo.
echo   Usage:
echo     - Paste a GitHub PR URL and ask Claude to review it
echo     - Or type /review-pr in Claude Code
echo.
echo   To update your token later, just run install.bat again.
echo.

endlocal
pause
exit /b 0

:fail
echo.
echo  Installation failed. Check permissions and try again.
endlocal
pause
exit /b 1
