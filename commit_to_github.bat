@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

REM Version tracking
set "SCRIPT_VERSION=1.5.6"

REM Check for restart flag to prevent infinite loops
if /i "%~1"=="--restarted" (
    shift
    set "script_restarted=true"
) else (
    set "script_restarted=false"
)

REM Check for command line arguments
if /i "%~1"=="--auto" (
    set "auto_mode=true"
    echo GitHub Auto-Monitor Script v%SCRIPT_VERSION%
    echo ==========================
    echo Auto-monitoring enabled. Checking for changes every minute...
    echo Press ESC to stop monitoring.
    echo.
    goto :auto_monitor
) else if /i "%~1"=="--commit" (
    set "auto_mode=false"
    echo Current directory: %CD%
    echo.
    goto :main_script
) else if /i "%~1"=="--force-push" (
    set "auto_mode=false"
    echo Current directory: %CD%
    echo.
    goto :force_push_mode
) else if not "%~1"=="" (
    REM Custom commit message provided
    set "auto_mode=false"
    echo Current directory: %CD%
    echo.
    goto :main_script
) else (
    REM Run setup steps then show interactive menu
    goto :setup_and_menu
)

:setup_and_menu
echo GitHub Auto-Monitor Script v%SCRIPT_VERSION%
call :check_git_installed
call :setup_repository
call :setup_remote_if_needed
call :show_repository_status
call :check_remote_changes
call :check_remote_changes_status
call :setup_lfs
call :check_file_sizes
echo.
goto :show_menu

:show_menu
set "menu_selection=1"
call :display_menu
goto :menu_loop

:display_menu
cls
echo GitHub Auto-Monitor Script v%SCRIPT_VERSION%
echo ==========================================
echo Current directory: %CD%
git config --get remote.origin.url >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%a in ('git config --get remote.origin.url') do set repo_url=%%a
    echo Repository: !repo_url!
) else (
    echo Repository: Not configured
)
echo.
echo Select an option:
echo.
if "%menu_selection%"=="1" (
    powershell -Command "Write-Host '  > Commit Changes Now' -ForegroundColor Green"
    echo    Auto-Monitor Mode
    if "%remote_changes_available%"=="true" (
        powershell -Command "Write-Host '    Pull Changes from Remote' -ForegroundColor Blue"
    ) else (
        echo    Pull Changes from Remote
    )
    echo    Hard Reset to Remote
    echo    Force Push to Remote
) else if "%menu_selection%"=="2" (
    echo    Commit Changes Now
    powershell -Command "Write-Host '  > Auto-Monitor Mode' -ForegroundColor Green"
    if "%remote_changes_available%"=="true" (
        powershell -Command "Write-Host '    Pull Changes from Remote' -ForegroundColor Blue"
    ) else (
        echo    Pull Changes from Remote
    )
    echo    Hard Reset to Remote
    echo    Force Push to Remote
) else if "%menu_selection%"=="3" (
    echo    Commit Changes Now
    echo    Auto-Monitor Mode
    if "%remote_changes_available%"=="true" (
        powershell -Command "Write-Host '  > Pull Changes from Remote' -ForegroundColor Blue"
    ) else (
        powershell -Command "Write-Host '  > Pull Changes from Remote' -ForegroundColor Cyan"
    )
    echo    Hard Reset to Remote
    echo    Force Push to Remote
) else if "%menu_selection%"=="4" (
    echo    Commit Changes Now
    echo    Auto-Monitor Mode
    if "%remote_changes_available%"=="true" (
        powershell -Command "Write-Host '    Pull Changes from Remote' -ForegroundColor Blue"
    ) else (
        echo    Pull Changes from Remote
    )
    powershell -Command "Write-Host '  > Hard Reset to Remote' -ForegroundColor Red"
    echo    Force Push to Remote
) else (
    echo    Commit Changes Now
    echo    Auto-Monitor Mode
    if "%remote_changes_available%"=="true" (
        powershell -Command "Write-Host '    Pull Changes from Remote' -ForegroundColor Blue"
    ) else (
        echo    Pull Changes from Remote
    )
    echo    Hard Reset to Remote
    powershell -Command "Write-Host '  > Force Push to Remote' -ForegroundColor Red"
)
echo.
echo Use UP/DOWN arrow keys to navigate, ENTER to select, ESC to exit
goto :eof

:menu_loop

REM Direct key reading without timeout or beeping
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "$Host.UI.RawUI.FlushInputBuffer(); $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); switch($key.VirtualKeyCode){13{'ENTER'}27{'ESC'}38{'UP'}40{'DOWN'}default{'OTHER'}}"') do set key_input=%%a

if "%key_input%"=="ENTER" goto :process_selection
if "%key_input%"=="ESC" exit /b
if "%key_input%"=="UP" (
    if "%menu_selection%"=="1" set "menu_selection=5"
    if "%menu_selection%"=="2" set "menu_selection=1"
    if "%menu_selection%"=="3" set "menu_selection=2"
    if "%menu_selection%"=="4" set "menu_selection=3"
    if "%menu_selection%"=="5" set "menu_selection=4"
    call :display_menu
)
if "%key_input%"=="DOWN" (
    if "%menu_selection%"=="1" set "menu_selection=2"
    if "%menu_selection%"=="2" set "menu_selection=3"
    if "%menu_selection%"=="3" set "menu_selection=4"
    if "%menu_selection%"=="4" set "menu_selection=5"
    if "%menu_selection%"=="5" set "menu_selection=1"
    call :display_menu
)
goto :menu_loop

:process_selection
if "%menu_selection%"=="1" (
    set "auto_mode=false"
    set "from_menu=true"
    goto :main_script
) else if "%menu_selection%"=="2" (
    set "auto_mode=true"
    echo Auto-monitoring enabled. Checking for changes every minute...
    echo Press ESC to stop monitoring.
    echo.
    goto :auto_monitor
) else if "%menu_selection%"=="3" (
    echo.
    echo Pull changes mode selected.
    echo.
    goto :pull_remote_changes
) else if "%menu_selection%"=="4" (
    echo.
    echo Hard reset mode selected.
    echo.
    goto :hard_reset_local
) else (
    echo.
    echo Force push mode selected.
    echo.
    goto :force_push_mode
)

:main_script
REM Skip setup display when coming from menu
if not defined from_menu (
    echo GitHub Auto-Monitor Script v%SCRIPT_VERSION%
    call :check_git_installed
    call :setup_repository
    call :setup_remote_if_needed
    call :show_repository_status
    call :pull_latest_changes
        call :setup_lfs
    call :check_file_sizes
) else (
    REM Just do essential checks without display
    call :check_git_installed >nul 2>&1
    call :setup_repository >nul 2>&1
    call :setup_remote_if_needed >nul 2>&1
    call :check_remote_changes >nul 2>&1
    call :setup_lfs >nul 2>&1
    call :check_file_sizes >nul 2>&1
)

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

    if errorlevel 1 (
        echo.
        echo Push failed! Check the error messages above.
        echo Press any key to exit...
        pause >nul
        goto :eof
    )

    echo.
    powershell -Command "Write-Host 'Commit completed successfully!' -ForegroundColor Green"
) else (
    echo No changes to commit.
)

echo Press any key to return to menu...
pause >nul
goto :show_menu

:auto_monitor
call :check_git_installed
call :setup_repository
call :setup_lfs >nul 2>&1
call :setup_remote_if_needed

:monitor_loop
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set current_time=%%a:%%b

echo [!current_time!] Checking for remote changes...
call :check_remote_changes

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

REM Check for ESC key press during 60 second wait
for /l %%i in (1,1,60) do (
    timeout /t 1 /nobreak >nul 2>&1
    REM Check if ESC was pressed
    for /f "tokens=*" %%a in ('powershell -NoProfile -Command "if ([Console]::KeyAvailable) { $key = [Console]::ReadKey($true); if ($key.Key -eq 'Escape') { 'ESC' } }"') do (
        if "%%a"=="ESC" (
            echo.
            echo Auto-monitor stopped. Returning to menu...
            goto :show_menu
        )
    )
)
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
        set "need_remote=true"
    ) else (
        set "need_remote=false"
    )
)
goto :eof

:show_repository_status
for /f "tokens=*" %%a in ('git branch --show-current') do set current_branch=%%a
git config --get remote.origin.url >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%r in ('git config --get remote.origin.url') do (
        set repo_url=%%r
        set repo_url=!repo_url:https://github.com/=!
        set repo_url=!repo_url:.git=!
        set repo_name=!repo_url!
    )

    REM Test if remote is actually accessible
    for /f "delims=" %%r in ('git config --get remote.origin.url') do set full_repo_url=%%r
    git ls-remote "!full_repo_url!" >nul 2>&1
    if not errorlevel 1 (
        powershell -Command "Write-Host 'Repository ' -NoNewline; Write-Host 'ready' -ForegroundColor Green -NoNewline; Write-Host ' | Remote: !repo_name! | Branch: !current_branch!'"
    ) else (
        powershell -Command "Write-Host 'Repository ' -NoNewline; Write-Host 'error' -ForegroundColor Red -NoNewline; Write-Host ' | Remote: !repo_name! (invalid) | Branch: !current_branch!'"
        powershell -Command "Write-Host 'ERROR: Remote repository is not accessible. Please reconfigure with a valid GitHub URL.' -ForegroundColor Red"
        echo.
        set /p "delete_git=Do you want to delete the .git folder and start fresh? (y/n): "
        if /i "!delete_git!"=="y" (
            echo Deleting .git folder...
            rmdir /s /q .git
            echo .git folder deleted. Run the script again to start fresh.
        ) else (
            echo You can manually run: git remote remove origin
            echo Then run this script again to reconfigure.
        )
        echo.
        echo Press any key to exit...
        pause >nul
        exit
    )
) else (
    powershell -Command "Write-Host 'Repository ' -NoNewline; Write-Host 'ready' -ForegroundColor Green -NoNewline; Write-Host ' | Remote: not configured | Branch: !current_branch!'"
)
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
    for /f "delims=" %%f in ('git ls-files') do (
        if exist "%%f" (
            for %%s in ("%%f") do (
                if %%~zs gtr !size_limit! (
                    git lfs ls-files | findstr /C:"%%f" >nul 2>&1
                    if errorlevel 1 (
                        git rm --cached "%%f" >nul 2>&1
                        echo.>> .gitignore
                        echo %%f>> .gitignore
                    )
                )
            )
        )
    )
)
goto :eof

:setup_remote_if_needed
if "!need_remote!"=="true" (
    echo No remote origin configured. Setting up remote repository...
    echo.
    :ask_for_url
    set /p "repo_url=Enter GitHub repository URL (https://github.com/username/repo.git): "

    REM Validate URL format - just check for github.com
    echo %repo_url% | findstr /C:"github.com/" >nul
    if errorlevel 1 (
        echo Invalid URL format. Please use a GitHub repository URL.
        goto ask_for_url
    )

    REM Test if repository exists and is accessible
    git ls-remote "!repo_url!" >nul 2>&1
    if errorlevel 1 (
        echo Error: Repository does not exist or is not accessible. Please check:
        echo - Repository URL is correct
        echo - Repository exists on GitHub
        echo - You have access rights to the repository
        goto ask_for_url
    )

    git remote add origin "!repo_url!"
    echo Remote origin added successfully.
    echo.
)
goto :eof

:check_remote_changes_status
set "remote_changes_available=false"
git config --get remote.origin.url >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%a in ('git branch --show-current') do set current_branch=%%a
    git fetch origin >nul 2>&1

    REM Check if we have any commits and remote branch exists
    git rev-parse HEAD >nul 2>&1
    if not errorlevel 1 (
        git rev-parse origin/!current_branch! >nul 2>&1
        if not errorlevel 1 (
            REM Check if there are changes available on remote
            git diff HEAD origin/!current_branch! --quiet >nul 2>&1
            if errorlevel 1 (
                set "remote_changes_available=true"
            )
        )
    )
)
goto :eof

:check_remote_changes
git config --get remote.origin.url >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%a in ('git branch --show-current') do set current_branch=%%a
    git fetch origin >nul 2>&1

    REM Check if we have any commits in the local repository
    git rev-parse HEAD >nul 2>&1
    if errorlevel 1 (
        powershell -Command "Write-Host '  [OK] New repository - no remote comparison needed' -ForegroundColor Green"
        goto :eof
    )

    REM Check if remote branch exists
    git rev-parse origin/!current_branch! >nul 2>&1
    if errorlevel 1 (
        powershell -Command "Write-Host '  [OK] Remote branch origin/!current_branch! not found - first push will create it' -ForegroundColor Yellow"
        goto :eof
    )

    REM Check if there are changes available on remote
    git diff HEAD origin/!current_branch! --quiet >nul 2>&1
    if errorlevel 1 (
        powershell -Command "Write-Host '  [NOTICE] Remote changes available' -ForegroundColor Yellow"
    ) else (
        powershell -Command "Write-Host '  [OK] Already up to date with remote' -ForegroundColor Green"
    )
) else (
    echo No remote origin configured. Skipping check.
)
goto :eof

:pull_remote_changes
call :check_git_installed
call :setup_repository
call :setup_lfs >nul 2>&1
call :setup_remote_if_needed

cls
echo GitHub Auto-Monitor Script v%SCRIPT_VERSION% - Pull Changes Mode
echo =================================================================
echo.

REM Check if remote is configured
git config --get remote.origin.url >nul 2>&1
if errorlevel 1 (
    powershell -Command "Write-Host 'ERROR: No remote origin configured!' -ForegroundColor Red"
    echo Cannot pull from remote without a configured origin.
    echo Please configure a remote first.
    echo.
    echo Press any key to return to menu...
    pause >nul
    goto :show_menu
)

for /f "tokens=*" %%a in ('git branch --show-current') do set current_branch=%%a
git fetch origin >nul 2>&1

REM Check if we have any commits in the local repository
git rev-parse HEAD >nul 2>&1
if errorlevel 1 (
    powershell -Command "Write-Host 'New repository - no remote comparison needed' -ForegroundColor Green"
    echo.
    echo Press any key to return to menu...
    pause >nul
    goto :show_menu
)

REM Check if remote branch exists
git rev-parse origin/!current_branch! >nul 2>&1
if errorlevel 1 (
    powershell -Command "Write-Host 'Remote branch origin/!current_branch! not found' -ForegroundColor Yellow"
    echo First push will create it.
    echo.
    echo Press any key to return to menu...
    pause >nul
    goto :show_menu
)

REM Check if there are changes to pull
git diff HEAD origin/!current_branch! --quiet >nul 2>&1
if errorlevel 1 (
    powershell -Command "Write-Host 'Remote changes detected - pulling updates:' -ForegroundColor Yellow"
    echo.

    REM Check for uncommitted local changes that would prevent pull
    git diff --quiet && git diff --cached --quiet
    if errorlevel 1 (
        echo.
        powershell -Command "Write-Host 'Uncommitted local changes detected:' -ForegroundColor Yellow"
        echo ========================
        git status --porcelain
        echo.
        echo Stashing uncommitted changes before pull...
        git stash push -m "Auto-stash before manual pull"
        set "stash_created=true"
    ) else (
        set "stash_created=false"
    )

    git pull origin !current_branch! --no-edit --allow-unrelated-histories --stat

    REM Restore stashed changes and check for conflicts
    if "!stash_created!"=="true" (
        echo.
        echo Restoring stashed changes...
        git stash pop >nul 2>&1
        REM Check if stash pop created conflicts
        git ls-files --unmerged | findstr . >nul 2>&1
        if not errorlevel 1 (
            echo.
            powershell -Command "Write-Host 'CONFLICTS from restoring local changes!' -ForegroundColor Red"
            echo.
            echo Conflicted files:
            git ls-files --unmerged | for /f "tokens=4" %%f in ('findstr /v "^$"') do echo   - %%f
            echo.
            goto :conflict_resolution_menu
        )
    )

    REM Check if pull resulted in merge conflicts
    git ls-files --unmerged | findstr . >nul 2>&1
    if not errorlevel 1 (
        echo.
        powershell -Command "Write-Host 'MERGE CONFLICTS DETECTED!' -ForegroundColor Red"
        echo.
        echo Conflicted files:
        git ls-files --unmerged | for /f "tokens=4" %%f in ('findstr /v "^$"') do echo   - %%f
        echo.
        goto :conflict_resolution_menu
    )

    echo.
    powershell -Command "Write-Host 'Pull completed successfully!' -ForegroundColor Green"
) else (
    powershell -Command "Write-Host 'Already up to date with remote' -ForegroundColor Green"
)

echo.
echo Press any key to return to menu...
pause >nul
goto :show_menu

:hard_reset_local
call :check_git_installed
call :setup_repository

echo GitHub Auto-Monitor Script v%SCRIPT_VERSION% - Hard Reset Mode
echo ================================================================
echo.
powershell -Command "Write-Host 'WARNING: This will PERMANENTLY DELETE all local changes!' -ForegroundColor Red"
powershell -Command "Write-Host 'Your local repository will be reset to match the remote exactly.' -ForegroundColor Yellow"
echo.
echo What will happen:
echo   1. All uncommitted changes will be lost
echo   2. All local commits not on remote will be lost
echo   3. Working directory will match remote branch exactly
echo.

REM Check if remote is configured
git config --get remote.origin.url >nul 2>&1
if errorlevel 1 (
    powershell -Command "Write-Host 'ERROR: No remote origin configured!' -ForegroundColor Red"
    echo Cannot perform hard reset without a remote repository.
    echo Please configure a remote first.
    echo.
    echo Press any key to return to menu...
    pause >nul
    goto :show_menu
)

REM Check if remote is accessible
git fetch origin >nul 2>&1
if errorlevel 1 (
    powershell -Command "Write-Host 'ERROR: Cannot fetch from remote!' -ForegroundColor Red"
    echo Remote repository is not accessible or does not exist.
    echo.
    echo Press any key to return to menu...
    pause >nul
    goto :show_menu
)

REM Determine which branch to reset to
for /f "tokens=*" %%a in ('git branch --show-current') do set current_branch=%%a
git rev-parse origin/!current_branch! >nul 2>&1
if errorlevel 1 (
    REM Try main branch if current branch doesn't exist on remote
    git rev-parse origin/main >nul 2>&1
    if not errorlevel 1 (
        set reset_branch=main
        powershell -Command "Write-Host 'Note: Current branch (!current_branch!) not found on remote.' -ForegroundColor Yellow"
        echo Will reset to origin/main instead.
    ) else (
        REM Try master branch
        git rev-parse origin/master >nul 2>&1
        if not errorlevel 1 (
            set reset_branch=master
            powershell -Command "Write-Host 'Note: Current branch (!current_branch!) not found on remote.' -ForegroundColor Yellow"
            echo Will reset to origin/master instead.
        ) else (
            powershell -Command "Write-Host 'ERROR: No suitable remote branch found!' -ForegroundColor Red"
            echo Cannot determine which remote branch to reset to.
            echo.
            echo Press any key to return to menu...
            pause >nul
            goto :show_menu
        )
    )
) else (
    set reset_branch=!current_branch!
)

echo.
powershell -Command "Write-Host 'Ready to reset to origin/!reset_branch!' -ForegroundColor Cyan"
echo.
set /p "confirm=Type 'RESET' to confirm (anything else cancels): "

if /i not "!confirm!"=="RESET" (
    echo.
    echo Reset cancelled.
    echo.
    echo Press any key to return to menu...
    pause >nul
    goto :show_menu
)

echo.
echo Performing hard reset...
echo.

REM Abort any ongoing merge/rebase
git merge --abort >nul 2>&1
git rebase --abort >nul 2>&1

REM Clean working directory
echo Cleaning working directory...
git clean -fd
git reset --hard HEAD

REM Switch to target branch and reset
echo Switching to !reset_branch! branch...
git checkout !reset_branch! >nul 2>&1
if errorlevel 1 (
    echo Creating !reset_branch! branch from origin/!reset_branch!...
    git checkout -b !reset_branch! origin/!reset_branch!
)

REM Hard reset to remote
echo Resetting to origin/!reset_branch!...
git reset --hard origin/!reset_branch!

REM Clean any remaining untracked files
git clean -fd

echo.
powershell -Command "Write-Host 'Hard reset completed successfully!' -ForegroundColor Green"
powershell -Command "Write-Host 'Local repository now matches origin/!reset_branch!' -ForegroundColor Green"
echo.
echo Repository status:
git status --porcelain
if errorlevel 1 (
    echo   No changes - repository is clean
) else (
    echo   Working directory is clean
)

echo.
echo Press any key to return to menu...
pause >nul
goto :show_menu

:conflict_resolution_menu
set "conflict_selection=1"
call :display_conflict_menu
goto :conflict_menu_loop

:display_conflict_menu
cls
echo Conflict Resolution
echo ==================
echo.
echo Conflicted files:
for /f "tokens=4" %%f in ('git ls-files --unmerged') do echo   - %%f
echo.
echo Git status:
git status --porcelain | findstr "^UU\|^AA\|^DD\|^AU\|^UA"
echo.
echo Choose how to resolve conflicts:
echo.

REM Option 1
if "%conflict_selection%"=="1" (
    powershell -Command "Write-Host '  > Keep Remote Version (from GitHub)' -ForegroundColor Green"
) else (
    echo    Keep Remote Version (from GitHub)
)

REM Option 2
if "%conflict_selection%"=="2" (
    powershell -Command "Write-Host '  > Keep Local Version (your changes)' -ForegroundColor Green"
) else (
    echo    Keep Local Version (your changes)
)

REM Option 3
if "%conflict_selection%"=="3" (
    powershell -Command "Write-Host '  > Manual Resolution (exit to resolve manually)' -ForegroundColor Yellow"
) else (
    echo    Manual Resolution (exit to resolve manually)
)

echo.
echo Use UP/DOWN arrow keys to navigate, ENTER to select, ESC to exit
goto :eof

:conflict_menu_loop
REM Direct key reading without timeout or beeping
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "$Host.UI.RawUI.FlushInputBuffer(); $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); switch($key.VirtualKeyCode){13{'ENTER'}27{'ESC'}38{'UP'}40{'DOWN'}default{'OTHER'}}"') do set key_input=%%a

if "%key_input%"=="ENTER" goto :process_conflict_selection
if "%key_input%"=="ESC" goto :show_menu
if "%key_input%"=="UP" (
    if "%conflict_selection%"=="1" (
        set "conflict_selection=3"
    ) else if "%conflict_selection%"=="2" (
        set "conflict_selection=1"
    ) else (
        set "conflict_selection=2"
    )
    call :display_conflict_menu
)
if "%key_input%"=="DOWN" (
    if "%conflict_selection%"=="1" (
        set "conflict_selection=2"
    ) else if "%conflict_selection%"=="2" (
        set "conflict_selection=3"
    ) else (
        set "conflict_selection=1"
    )
    call :display_conflict_menu
)
goto :conflict_menu_loop

:process_conflict_selection
if "%conflict_selection%"=="1" goto :resolve_remote
if "%conflict_selection%"=="2" goto :resolve_local
if "%conflict_selection%"=="3" goto :resolve_manual
goto :resolve_error

:resolve_remote
echo.
echo Keeping remote version (from GitHub)...
echo.
REM Handle delete/modify conflicts by accepting remote deletions
git ls-files --unmerged | for /f "tokens=4" %%f in ('findstr /v "^$"') do (
    echo Resolving conflict for: %%f
    git rm "%%f" >nul 2>&1
    git checkout origin/HEAD -- "%%f" >nul 2>&1
)
git add .
git commit -m "Resolve conflicts by keeping remote version"
powershell -Command "Write-Host 'Conflicts resolved using remote version!' -ForegroundColor Green"
goto :conflict_resolved

:resolve_local
echo.
echo Keeping local version (your changes)...
echo.
REM Handle delete/modify conflicts by keeping local changes
git ls-files --unmerged | for /f "tokens=4" %%f in ('findstr /v "^$"') do (
    echo Resolving conflict for: %%f
    git add "%%f"
)
git commit -m "Resolve conflicts by keeping local version"
powershell -Command "Write-Host 'Conflicts resolved using local version!' -ForegroundColor Green"
goto :conflict_resolved

:resolve_manual
echo.
echo Manual resolution selected. Returning to menu...
echo.
powershell -Command "Write-Host 'Please resolve conflicts manually, then run the script again.' -ForegroundColor Yellow"
goto :show_menu

:resolve_error
echo ERROR: Invalid selection
goto :show_menu

:conflict_resolved
echo.
echo Press any key to return to menu...
pause >nul
goto :show_menu

:force_push_mode
echo GitHub Auto-Monitor Script v%SCRIPT_VERSION% - Force Push Mode
echo ==============================================================
echo.
powershell -Command "Write-Host 'WARNING: This will FORCEFULLY OVERWRITE the remote repository!' -ForegroundColor Red"
powershell -Command "Write-Host 'Remote will be reset to match your local changes exactly.' -ForegroundColor Yellow"
echo.
echo What will happen:
echo   1. All local changes will be committed
echo   2. Remote repository will be force-pushed to match local
echo   3. Any remote changes not in local will be LOST FOREVER
echo.

call :check_git_installed
call :setup_repository
call :setup_remote_if_needed

REM Check if remote is configured
git config --get remote.origin.url >nul 2>&1
if errorlevel 1 (
    powershell -Command "Write-Host 'ERROR: No remote origin configured!' -ForegroundColor Red"
    echo Cannot perform force push without a remote repository.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo.
set /p "confirm=Type 'FORCE' to confirm force push (anything else cancels): "

if /i not "!confirm!"=="FORCE" (
    echo.
    echo Force push cancelled.
    echo Press any key to return to menu...
    pause >nul
    goto :show_menu
)

echo.
echo Performing force push...
echo.

REM Add all changes
echo Adding all local changes...
git add .

REM Check if there are changes to commit
git diff --staged --quiet
if errorlevel 1 (
    echo Committing all local changes...
    for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set mydate=%%a-%%b-%%c
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do set mytime=%%a:%%b
    git commit -m "Force push commit !mydate! !mytime!"
) else (
    echo No new changes to commit.
)

REM Get current branch
for /f "tokens=*" %%a in ('git branch --show-current') do set current_branch=%%a

echo Force pushing to origin/!current_branch!...
git push origin !current_branch! --force

if errorlevel 1 (
    echo.
    powershell -Command "Write-Host 'Force push failed! Check the error messages above.' -ForegroundColor Red"
    echo Press any key to return to menu...
    pause >nul
    goto :show_menu
)

echo.
powershell -Command "Write-Host 'Force push completed successfully!' -ForegroundColor Green"
powershell -Command "Write-Host 'Remote repository now matches your local changes exactly!' -ForegroundColor Green"

echo.
echo Press any key to return to menu...
pause >nul
goto :show_menu

echo.
echo Press any key to continue...
pause >nul

REM Continue with the rest of the script after conflict resolution
echo.
powershell -Command "Write-Host '  [OK] Conflicts resolved' -ForegroundColor Green"

REM If script was updated, restart with new version (but only if not already restarted)
for /f "tokens=*" %%a in ('git branch --show-current') do set current_branch=%%a
git diff HEAD origin/!current_branch! --name-only | findstr /C:"commit_to_github.bat" >nul 2>&1
set script_updated=!errorlevel!

if !script_updated! equ 0 (
    if "!script_restarted!"=="false" (
        echo.
        powershell -Command "Write-Host 'Script updated! Restarting with new version...' -ForegroundColor Cyan"
        timeout /t 2 /nobreak >nul
        start "" "%~dpnx0" --restarted %*
        exit
    ) else (
        powershell -Command "Write-Host '  [OK] Script restarted with latest version' -ForegroundColor Green"
    )
)
goto :show_menu





















