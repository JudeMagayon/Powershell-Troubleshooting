# PowerShell Script to Fix Jupyter Kernel Errors in Nerdio AVD
# through Nerdio scripted action or user session)

Write-Output "Starting Jupyter kernel repair..."

$UserProfile = $env:USERPROFILE
$AppData = $env:APPDATA
$JupyterRuntime = Join-Path $AppData "jupyter\runtime"
$JupyterData = Join-Path $AppData "jupyter\data"
$JupyterDir = Join-Path $UserProfile ".jupyter"
$IPythonDir = Join-Path $UserProfile ".ipython"

Write-Output "Cleaning up existing Jupyter folders..."

$foldersToDelete = @($JupyterRuntime, $JupyterDir, $IPythonDir)

foreach ($folder in $foldersToDelete) {
    if (Test-Path $folder) {
        try {
            Remove-Item -Recurse -Force -Path $folder
            Write-Output "Removed: $folder"
        } catch {
            Write-Warning "Could not delete $folder: $_"
        }
    }
}

# Step 2: Recreate necessary runtime folders
Write-Output " Recreating Jupyter runtime folders..."
New-Item -ItemType Directory -Force -Path $JupyterRuntime | Out-Null
New-Item -ItemType Directory -Force -Path $JupyterDir | Out-Null

Write-Output " Setting user environment variables..."
[Environment]::SetEnvironmentVariable("JUPYTER_RUNTIME_DIR", $JupyterRuntime, "User")
[Environment]::SetEnvironmentVariable("JUPYTER_DATA_DIR", $JupyterData, "User")

Write-Output "Installing notebook and ipykernel in current Python environment..."

$python = "python"  # Assumes python is in PATH

$commands = @(
    "$python -m pip install --upgrade pip",
    "$python -m pip install notebook ipykernel --force-reinstall",
    "$python -m ipykernel install --user --name=myenv --display-name 'Python (myenv)' --force"
)

foreach ($cmd in $commands) {
    Write-Output "`Running: $cmd"
    try {
        cmd.exe /c $cmd
    } catch {
        Write-Warning "Command failed: $_"
    }
}

Write-Output "`nJupyter kernel repair completed. You may now reopen VS Code and select 'Python (myenv)' kernel."
