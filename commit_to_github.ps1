$SCRIPT_VERSION = "1.5.7"

$script:menu_selection = 1
$script:need_remote = $false

$script:repo_url = ""
$script:current_br = ""
$script:status = ""

# Set console title
$Host.UI.RawUI.WindowTitle = "GitHub Script v$SCRIPT_VERSION"

# Check for restart flag to prevent infinite loops
$script_restarted = $args -contains "--restarted"
if ($script_restarted) {
    $args = $args | Where-Object { $_ -ne "--restarted" }
}

function Wait-ForKeyPress {
    param([string]$Message = "Press any key to continue...")
    Write-Host $Message
    Update-Status
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Test-GitInstalled {
    try {
        git --version | Out-Null
    } 
    catch {
        Write-Host "ERROR: Git is not installed or not found in PATH." -ForegroundColor Red
        Write-Host "Please install Git from: https://git-scm.com/download/win"
        Wait-ForKeyPress
        exit 1
    }
}

function Initialize-Repository {
    if (-not (Test-Path ".git")) {
        Write-Host "No .git folder found. Initializing git repository..."
        git init
        git branch -M main
        Write-Host "Repository initialized successfully.`n"
        $script:need_remote = $true
    }
    elseif (-not (Test-Path ".git\config")) {
        Write-Host ".git folder exists but config is missing. Re-initializing..."
        git init
        git branch -M main
        Write-Host "Repository re-initialized successfully.`n"
        $script:need_remote = $true
    } else {
        git branch -M main 2>$null | Out-Null
        $script:repo_url = git config --get remote.origin.url 2>$null
        if ($LASTEXITCODE -ne 0) {
            $script:need_remote = $true
        } 
        else {
            $script:need_remote = $false
        }
    }

    # Set up remote if needed
    if ($script:need_remote) {
        Write-Host "No remote origin configured. Setting up remote repository..."
        Write-Host "`n"

        do {
            $repo_url = Read-Host "Enter GitHub repository URL (https://github.com/username/repo.git)"

            # Validate URL format
            if ($repo_url -notmatch "github.com/") {
                Write-Host "Invalid URL format. Please use a GitHub repository URL."
                continue
            }

            # Test if repository exists and is accessible
            git ls-remote $repo_url 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Error: Repository does not exist or is not accessible. Please check:"
                Write-Host "- Repository URL is correct"
                Write-Host "- Repository exists on GitHub"
                Write-Host "- You have access rights to the repository"
                continue
            }

            break
        } while ($true)

        git remote add origin $repo_url
        Write-Host "Remote origin added successfully.`n"
    }
}

function Initialize-LFS {
    git lfs install --skip-repo 2>$null
    git lfs track "*.jar" 2>$null
    git lfs track "*.zip" 2>$null
}

function Test-FileSizes {
    $size_limit = 52324403
    $oversized_found = $false
    $reset_needed = $false

    # Check untracked files
    $untracked_files = git ls-files --others --exclude-standard
    foreach ($file in $untracked_files) {
        if (Test-Path $file) {
            $file_size = (Get-Item $file).Length
            if ($file_size -gt $size_limit) {
                Write-Host "`nFound oversized files:"
                $file_mb = [math]::Round($file_size / 1MB, 1)
                Write-Host "  - $file ($file_mb MB)" -ForegroundColor Red
                Add-Content -Path ".gitignore" -Value "`n$file"
                $oversized_found = $true
            }
        }
    }

    # Check staged files
    $staged_files = git diff --cached --name-only 2>$null
    foreach ($file in $staged_files) {
        if (Test-Path $file) {
            $file_size = (Get-Item $file).Length
            if ($file_size -gt $size_limit) {
                Write-Host "Found oversized staged file: $file ($file_size bytes)"
                Add-Content -Path ".gitignore" -Value "`n$file"
                $oversized_found = $true
                $reset_needed = $true
            }
        }
    }

    if ($reset_needed) {
        Write-Host "Resetting staged changes due to oversized files..."
        git reset HEAD .
    }

    # Remove oversized files from tracking only if NOT tracked by LFS
    if ($oversized_found) {
        $tracked_files = git ls-files
        foreach ($file in $tracked_files) {
            if (Test-Path $file) {
                $file_size = (Get-Item $file).Length
                if ($file_size -gt $size_limit) {
                    $lfs_check = git lfs ls-files | Select-String $file
                    if (-not $lfs_check) {
                        git rm --cached $file 2>$null
                        Add-Content -Path ".gitignore" -Value "`n$file"
                    }
                }
            }
        }
    }
}

function Test-RemoteChangesAvailable {
    $script:current_br = $current_branch = git branch --show-current
    git fetch origin 2>$null
    git diff HEAD "origin/$current_branch" --quiet 2>$null
    return ($LASTEXITCODE -ne 0)
}

function Test-LocalChangesAvailable {
    git diff --quiet
    $diff_result = $LASTEXITCODE
    git diff --cached --quiet
    $cached_diff_result = $LASTEXITCODE
    return (($diff_result -ne 0) -or ($cached_diff_result -ne 0))
}

function Update-Status {
    $has_remote_changes = Test-RemoteChangesAvailable
    $has_local_changes = Test-LocalChangesAvailable

    $script:status = @{
        Repository = $script:repo_url
        Branch = $script:current_br
        HasRemoteChanges = $has_remote_changes
        HasLocalChanges = $has_local_changes
    }
}

function Show-Status {
    Write-Host "Repository | " -NoNewline
    Write-Host $script:status.Branch -ForegroundColor Cyan -NoNewline
    Write-Host " | " -NoNewline
    Write-Host $script:status.Repository -ForegroundColor Blue -NoNewline
    Write-Host " | " -NoNewline

    if ($script:status.HasRemoteChanges -and $script:status.HasLocalChanges) {
        Write-Host "Remote & Local Changes" -ForegroundColor Yellow
    } elseif ($script:status.HasRemoteChanges) {
        Write-Host "Remote Changes" -ForegroundColor Yellow
    } elseif ($script:status.HasLocalChanges) {
        Write-Host "Local Changes" -ForegroundColor Yellow
    } else {
        Write-Host "Synced" -ForegroundColor Green
    }
}

function Show-MenuDisplay {
    param($status_line)
    Clear-Host
    Write-Host "Current directory: $(Get-Location)`n"
    Show-Status

    for ($i = 0; $i -lt $script:menu_items.Count; $i++) {
        $item = $script:menu_items[$i]
        $prefix = if ($i -eq ($script:menu_selection - 1)) { "  > " } else { "    " }

        if ($i -eq ($script:menu_selection - 1)) {
            # Selected item
            Write-Host "$prefix$($item.Title)" -ForegroundColor $item.Color
        } elseif ($item.Title -eq "Pull Changes from Remote" -and $script:remote_changes_available) {
            # Special case for pull option when changes available
            Write-Host "$prefix$($item.Title)" -ForegroundColor Blue
        } else {
            # Normal unselected item
            Write-Host "$prefix$($item.Title)"
        }
    }

    Write-Host "`nUse UP/DOWN arrow keys to navigate, ENTER to select, ESC to exit"
}

function Start-MenuLoop {
    param($status_line)
    while ($true) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            13 { # ENTER
                $selected_item = $script:menu_items[$script:menu_selection - 1]
                & $selected_item.Action

                $script:menu_selection = 1
                Show-MenuDisplay $status_line
                break
            }
            27 { # ESC
                exit
            }
            38 { # UP
                $script:menu_selection--
                if ($script:menu_selection -lt 1) { $script:menu_selection = $script:menu_items.Count }
                Show-MenuDisplay $status_line
            }
            40 { # DOWN
                $script:menu_selection++
                if ($script:menu_selection -gt $script:menu_items.Count) { $script:menu_selection = 1 }
                Show-MenuDisplay $status_line
            }
        }
    }
}

function Show-Menu {
    $script:menu_selection = 1
    Show-MenuDisplay $status_line
    Start-MenuLoop $status_line
}

function Commit-Script {    
    if (Test-LocalChangesAvailable) {
        git add .

        Write-Host "`nGit Status:"
        git status --porcelain
        Write-Host "`n"

        $confirm_commit = Read-Host "Do you want to commit these changes? (y/n)"
        if ($confirm_commit -ne "y" -and $confirm_commit -ne "Y") {
            Write-Host "Commit cancelled."
            Wait-ForKeyPress
            return
        }

        $mydate = Get-Date -Format "ddd-MM-dd"
        $mytime = Get-Date -Format "HH:mm"
        $commit_message = "Auto commit $mydate $mytime"

        git commit -m $commit_message
        Write-Host "`n"

        $current_branch = git branch --show-current

        git push -u origin $current_branch
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Push failed. Attempting to pull and merge remote changes..."
            git pull origin $current_branch --no-edit --allow-unrelated-histories
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Merge failed. Please resolve conflicts manually."
            } else {
                Write-Host "Merge successful. Pushing again..."
                git push -u origin $current_branch
            }
        }

        if ($LASTEXITCODE -ne 0) {
            Write-Host "`nPush failed! Check the error messages above."
            Wait-ForKeyPress
            return
        }

        Write-Host "`nCommit completed successfully!" -ForegroundColor Green
    } 
    else {
        Write-Host "No changes to commit."
    }

    Wait-ForKeyPress
}

$script:menu_items = @(
    @{ Title = "Commit Changes Now"; Action = { Commit-Script }; Color = "Green" },
    @{ Title = "Pull Changes from Remote"; Action = { Start-PullRemoteChanges }; Color = "Cyan" },
    @{ Title = "Hard Reset to Remote"; Action = { Start-HardResetLocal }; Color = "Red" },
    @{ Title = "Force Push to Remote"; Action = { Start-ForcePushMode }; Color = "Red" }
)

function Start-PullRemoteChanges {
    $current_branch = git branch --show-current
    git fetch origin 2>$null

    if (Test-RemoteChangesAvailable) {
        # Show what changes are available
        Write-Host "`nChanges available from remote:"
        git log HEAD..origin/$current_branch --oneline --max-count=5

        $confirm_pull = Read-Host "`nDo you want to pull these changes? (y/n)"
        if ($confirm_pull -ne "y" -and $confirm_pull -ne "Y") {
            Write-Host "Pull cancelled."
            Wait-ForKeyPress
            return
        }

        Write-Host "`nPulling updates:" -ForegroundColor Yellow
        Write-Host "`n"

        # Check for uncommitted local changes that would prevent pull
        git diff --quiet
        $diff_result = $LASTEXITCODE
        git diff --cached --quiet
        $cached_diff_result = $LASTEXITCODE

        if (Test-LocalChangesAvailable) {
            Write-Host "`nUncommitted local changes detected:" -ForegroundColor Yellow
            Write-Host "========================"
            git status --porcelain
            Write-Host "`nStashing uncommitted changes before pull..."
            git stash push -m "Auto-stash before manual pull"
            $stash_created = $true
        } else {
            $stash_created = $false
        }

        git pull origin $current_branch --no-edit --allow-unrelated-histories --stat

        # Restore stashed changes and check for conflicts
        if ($stash_created) {
            Write-Host "`nRestoring stashed changes..."
            git stash pop 2>$null
            # Check if stash pop created conflicts
            $conflict_files = git ls-files --unmerged
            if ($conflict_files) {
                Write-Host "`nCONFLICTS from restoring local changes!" -ForegroundColor Red
                Write-Host "Please resolve conflicts manually and run the script again."
                Wait-ForKeyPress
                return
            }
        }

        # Check if pull resulted in merge conflicts
        $conflict_files = git ls-files --unmerged
        if ($conflict_files) {
            Write-Host "`nMERGE CONFLICTS DETECTED!" -ForegroundColor Red
            Write-Host "Please resolve conflicts manually and run the script again."
            Wait-ForKeyPress
            return
        }

        Write-Host "`nPull completed successfully!" -ForegroundColor Green
    } 
    else {
        Write-Host "Already up to date with remote" -ForegroundColor Green
    }

    Wait-ForKeyPress
}

function Start-HardResetLocal {
    if (Test-LocalChangesAvailable or Test-RemoteChangesAvailable) {
        Write-Host "`nWARNING: This will PERMANENTLY DELETE all local changes!" -ForegroundColor Red
        Write-Host "Your local repository will be reset to match the remote exactly." -ForegroundColor Yellow
        Write-Host "`nWhat will happen:"
        Write-Host "  1. All uncommitted changes will be lost"
        Write-Host "  2. All local commits not on remote will be lost"
        Write-Host "  3. Working directory will match remote branch exactly`n"

        # Determine which branch to reset to
        $current_branch = git branch --show-current
        git rev-parse "origin/$current_branch" 2>$null
        if ($LASTEXITCODE -ne 0) {
            # Try main branch if current branch doesn't exist on remote
            git rev-parse "origin/main" 2>$null
            if ($LASTEXITCODE -eq 0) {
                $reset_branch = "main"
                Write-Host "Note: Current branch ($current_branch) not found on remote." -ForegroundColor Yellow
                Write-Host "Will reset to origin/main instead."
            } else {
                # Try master branch
                git rev-parse "origin/master" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $reset_branch = "master"
                    Write-Host "Note: Current branch ($current_branch) not found on remote." -ForegroundColor Yellow
                    Write-Host "Will reset to origin/master instead."
                } else {
                    Write-Host "ERROR: No suitable remote branch found!" -ForegroundColor Red
                    Write-Host "Cannot determine which remote branch to reset to."
                    Wait-ForKeyPress
                    return
                }
            }
        } else {
            $reset_branch = $current_branch
        }

        Write-Host "`nReady to reset to origin/$reset_branch!" -ForegroundColor Cyan
        $confirm = Read-Host "`nType 'RESET' to confirm (anything else cancels)"

        if ($confirm -ne "RESET") {
            Write-Host "`nReset cancelled."
            Wait-ForKeyPress
            return
        }

        Write-Host "`nPerforming hard reset...`n"

        # Abort any ongoing merge/rebase
        git merge --abort 2>$null
        git rebase --abort 2>$null

        # Clean working directory
        Write-Host "Cleaning working directory..."
        git clean -fd
        git reset --hard HEAD

        # Switch to target branch and reset
        Write-Host "Switching to $reset_branch branch..."
        git checkout $reset_branch 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Creating $reset_branch branch from origin/$reset_branch..."
            git checkout -b $reset_branch "origin/$reset_branch"
        }

        # Hard reset to remote
        Write-Host "Resetting to origin/$reset_branch..."
        git reset --hard "origin/$reset_branch"

        # Clean any remaining untracked files
        git clean -fd

        Write-Host "`nHard reset completed successfully!" -ForegroundColor Green
        Write-Host "Local repository now matches origin/$reset_branch!" -ForegroundColor Green
        Write-Host "`nRepository status:"
        $status = git status --porcelain
        if (-not $status) {
            Write-Host "  Working directory is clean"
        } else {
            git status --porcelain
        }
    }
    else {
        Write-Host "Remote already matches your local changes exactly." -ForegroundColor Yellow
    }

    Wait-ForKeyPress
}

function Start-ForcePushMode {
    if (Test-LocalChangesAvailable) {
        Write-Host "`nWARNING: This will FORCEFULLY OVERWRITE the remote repository!" -ForegroundColor Red
        Write-Host "Remote will be reset to match your local changes exactly." -ForegroundColor Yellow
        Write-Host "`nWhat will happen:"
        Write-Host "  1. All local changes will be committed"
        Write-Host "  2. Remote repository will be force-pushed to match local"
        Write-Host "  3. Any remote changes not in local will be LOST FOREVER`n"

        $confirm = Read-Host "Type 'FORCE' to confirm force push (anything else cancels)"

        if ($confirm -ne "FORCE") {
            Write-Host "`nForce push cancelled."
            Wait-ForKeyPress
            return
        }

        Write-Host "`nPerforming force push...`n"
        Write-Host "Adding all local changes...`n"

        git add .

        $mydate = Get-Date -Format "ddd-MM-dd"
        $mytime = Get-Date -Format "HH:mm"
        git commit -m "Force push commit $mydate $mytime"

        # Get current branch
        $current_branch = git branch --show-current

        Write-Host "Force pushing to origin/$current_branch..."
        git push origin $current_branch --force

        if ($LASTEXITCODE -ne 0) {
            Write-Host "`nForce push failed! Check the error messages above." -ForegroundColor Red
            Wait-ForKeyPress
            return
        }

        Write-Host "`nForce push completed successfully!" -ForegroundColor Green
        Write-Host "Remote repository now matches your local changes exactly!" -ForegroundColor Green
    }
    else {
        Write-Host "Remote repository already matches your local changes exactly!" -ForegroundColor Yellow
    }

    Wait-ForKeyPress
}

function Start-Script {
    Test-GitInstalled
    Initialize-Repository

    Initialize-LFS | Out-Null
    Test-FileSizes

    Update-Status
    Show-Menu
}

#THIS IS THE ENTRY POINT OF THE SCRIPT
Start-Script

# Check if script was updated and restart if needed
$current_branch = git branch --show-current 2>$null
if ($current_branch) {
    $script_updated = git diff HEAD "origin/$current_branch" --name-only 2>$null | Select-String "commit_to_github.ps1"
    if ($script_updated -and -not $script_restarted) {
        Write-Host "`nScript updated! Restarting with new version..." -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        & "$PSCommandPath" --restarted @args
        exit
    } elseif ($script_restarted) {
        Write-Host "  [OK] Script restarted with latest version" -ForegroundColor Green
    }
}