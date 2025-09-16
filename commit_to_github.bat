@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

REM Check for auto-monitor argument
if /i "%~1"=="--auto" (
    set "auto_mode=true"
    echo GitHub Auto-Monitor Script
    echo ==========================
    echo Auto-monitoring enabled. Checking for changes every minute...
    echo Press Ctrl+C to stop monitoring.
    echo.
    goto :auto_monitor
) else (
    set "auto_mode=false"
    echo Current directory: %CD%
    echo.
)

call :check_git_installed
call :setup_repository
call :show_repository_status
call :reset_git_state
call :setup_lfs
call :check_file_sizes
call :setup_remote_if_needed

REM Prepare commit message
if "%~1"=="" (
    for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set mydate=%%a-%%b-%%c
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do set mytime=%%a:%%b
    set commit_message=Auto commit !mydate! !mytime!
    set "auto_generated=true"
) else (
    set commit_message=%~1
    set "auto_generated=false"
)

REM Add all files to staging (excluding those now in .gitignore)
git add .

echo.
echo Git Status:
git status --porcelain
echo.

REM Check if there are changes to commit
git diff --staged --quiet
if errorlevel 1 (
    git commit -m "!commit_message!"
    echo.

    git push -u origin !current_branch!
    if errorlevel 1 (
        echo Push failed. Attempting to pull and merge remote changes...
        git pull origin !current_branch! --no-edit --allow-unrelated-histories
        if errorlevel 1 (
            echo Merge failed. Please resolve conflicts manually.
        ) else (
            echo Merge successful. Pushing again...
            git push -u origin !current_branch!
        )
    )
) else (
    echo No changes to commit.
)

if errorlevel 1 (
    echo.
    echo Push failed! Check the error messages above.
    echo Press any key to exit...
    pause >nul
    goto :eof
)

echo.
powershell -Command "Write-Host 'Commit completed successfully!' -ForegroundColor Green"
echo Press any key to exit...
pause >nul
exit /b

:auto_monitor
call :check_git_installed
call :setup_repository
call :setup_lfs
call :setup_remote_if_needed

:monitor_loop
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set current_time=%%a:%%b

echo [!current_time!] Checking for remote changes...
git fetch origin >nul 2>&1

git ls-remote --heads origin main >nul 2>&1
if not errorlevel 1 (
    set remote_branch=main
) else (
    git ls-remote --heads origin master >nul 2>&1
    if not errorlevel 1 (
        set remote_branch=master
    ) else (
        echo [!current_time!] No main or master branch found. Skipping remote check.
        goto skip_remote_check
    )
)

git diff HEAD origin/!remote_branch! --quiet >nul 2>&1
if errorlevel 1 (
    echo [!current_time!] Remote changes detected. Pulling from !remote_branch!...
    git pull origin !remote_branch! --no-edit --allow-unrelated-histories >nul 2>&1
    if errorlevel 1 (
        echo [!current_time!] Pull failed. Continuing with local changes...
    ) else (
        echo [!current_time!] Remote changes pulled successfully!
    )
)

:skip_remote_check
call :check_file_sizes
git add . >nul 2>&1
git diff --staged --quiet
if errorlevel 1 (
    echo [!current_time!] Local changes detected. Committing and pushing...

    for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set mydate=%%a-%%b-%%c
    set commit_message=Auto commit !mydate! !current_time!

    git commit -m "!commit_message!" >nul 2>&1

    for /f "tokens=*" %%a in ('git branch --show-current') do set current_branch=%%a
    git push -u origin !current_branch! >nul 2>&1
    if errorlevel 1 (
        git pull origin !current_branch! --no-edit --allow-unrelated-histories >nul 2>&1
        git push -u origin !current_branch! >nul 2>&1
    )

    echo [!current_time!] Auto-commit completed!
) else (
    echo [!current_time!] No local changes detected.
)

timeout /t 60 /nobreak >nul
goto monitor_loop

:check_git_installed
git --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git is not installed or not found in PATH.
    echo Please install Git from: https://git-scm.com/download/win
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
goto :eof

:setup_repository
if not exist ".git" (
    echo No .git folder found. Initializing git repository...
    git init
    git branch -M main
    echo Repository initialized successfully.
    echo.
    set "need_remote=true"
) else if not exist ".git\config" (
    echo .git folder exists but config is missing. Re-initializing...
    git init
    git branch -M main
    echo Repository re-initialized successfully.
    echo.
    set "need_remote=true"
) else (
    git branch -M main 2>nul
    git config --get remote.origin.url >nul 2>&1
    if errorlevel 1 (
        echo No remote origin configured.
        set "need_remote=true"
    ) else (
        set "need_remote=false"
    )
)
goto :eof

:show_repository_status
for /f "tokens=*" %%a in ('git branch --show-current') do set current_branch=%%a
for /f "delims=" %%r in ('git config --get remote.origin.url') do (
    set repo_url=%%r
    set repo_url=!repo_url:https://github.com/=!
    set repo_url=!repo_url:.git=!
    set repo_name=!repo_url!
)
powershell -Command "Write-Host 'Repository ' -NoNewline; Write-Host 'ready' -ForegroundColor Green -NoNewline; Write-Host ' | Remote: !repo_name! | Branch: !current_branch!'"
goto :eof

:reset_git_state
git fetch origin >nul 2>&1
git reset --mixed origin/main >nul 2>&1
if errorlevel 1 (
    git reset --mixed $(git hash-object -t tree /dev/null) >nul 2>&1
    if errorlevel 1 (
        git rm --cached -r . >nul 2>&1
    )
)
git reset >nul 2>&1
powershell -Command "Write-Host '  [OK] Git state reset' -ForegroundColor Green"
goto :eof

:setup_lfs
git lfs install --skip-repo >nul 2>&1
git lfs track "*.jar" >nul 2>&1
git lfs track "*.zip" >nul 2>&1
powershell -Command "Write-Host '  [OK] LFS tracking: *.jar, *.zip' -ForegroundColor Green"
goto :eof

:check_file_sizes
set "size_limit=52324403"
set "oversized_found=false"
set "reset_needed=false"

REM Check untracked files
for /f "delims=" %%f in ('git ls-files --others --exclude-standard') do (
    if exist "%%f" (
        for %%s in ("%%f") do (
            if %%~zs gtr !size_limit! (
                echo.
                echo Found oversized files:
                set /a file_mb=%%~zs/1048576
                powershell -Command "Write-Host '  - %%f (!file_mb!MB)' -ForegroundColor Red"
                echo.>> .gitignore
                echo %%f>> .gitignore
                set "oversized_found=true"
            )
        )
    )
)

REM Check staged files
for /f "delims=" %%f in ('git diff --cached --name-only 2^>nul') do (
    if exist "%%f" (
        for %%s in ("%%f") do (
            if %%~zs gtr !size_limit! (
                echo Found oversized staged file: %%f ^(%%~zs bytes^)
                echo.>> .gitignore
                echo %%f>> .gitignore
                set "oversized_found=true"
                set "reset_needed=true"
            )
        )
    )
)

if "!reset_needed!"=="true" (
    echo Resetting staged changes due to oversized files...
    git reset HEAD .
)

REM Remove oversized files from tracking only if NOT tracked by LFS
if "!oversized_found!"=="true" (
    set "lfs_files_found=false"
    for /f "delims=" %%f in ('git ls-files') do (
        if exist "%%f" (
            for %%s in ("%%f") do (
                if %%~zs gtr !size_limit! (
                    git lfs ls-files | findstr /C:"%%f" >nul 2>&1
                    if errorlevel 1 (
                        git rm --cached "%%f" >nul 2>&1
                        echo.>> .gitignore
                        echo %%f>> .gitignore
                    ) else (
                        if "!lfs_files_found!"=="false" (
                            echo.
                            echo LFS-tracked large files:
                            set "lfs_files_found=true"
                        )
                        set /a file_mb=%%~zs/1048576
                        powershell -Command "Write-Host '  - %%f (!file_mb!MB)' -ForegroundColor Green"
                    )
                )
            )
        )
    )
)
goto :eof

:setup_remote_if_needed
if "!need_remote!"=="true" (
    echo Setting up remote repository...
    echo.
    set /p "repo_url=Enter GitHub repository URL (https://github.com/username/repo.git): "
    git remote add origin "!repo_url!"
    echo Remote origin added successfully.
    echo.
)
goto :eof