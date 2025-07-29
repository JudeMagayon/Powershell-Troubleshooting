# 
# Check and Fix Jupyter Setup for Regular Azure VD User
# 

Write-Host "=== Step 1: Checking AppData Local Write Access ===" -ForegroundColor Cyan

$localAppData = $env:LOCALAPPDATA
$testFolder = Join-Path $localAppData "JupyterTest"

Try {
    New-Item -ItemType Directory -Path $testFolder -Force | Out-Null
    if (Test-Path $testFolder) {
        Write-Host " AppData Local is writable: $localAppData" -ForegroundColor Green
        Remove-Item $testFolder -Recurse -Force
    } else {
        Write-Host " Cannot write to AppData Local: $localAppData" -ForegroundColor Red
        exit 1
    }
} Catch {
    Write-Host " Cannot write to AppData Local: $localAppData" -ForegroundColor Red
    exit 1
}

# 
Write-Host "`n=== Step 2: Checking Python and pip ===" -ForegroundColor Cyan

# Check Python
$pythonVersion = & python --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host " Python not found for this user. Install Python per-user or contact IT." -ForegroundColor Red
    exit 1
} else {
    Write-Host " Python detected: $pythonVersion" -ForegroundColor Green
}

# Check pip
$pipVersion = & python -m pip --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host " pip not available for this user. Installing ensurepip..." -ForegroundColor Yellow
    python -m ensurepip --user
} else {
    Write-Host " pip detected: $pipVersion" -ForegroundColor Green
}

# 
Write-Host "`n=== Step 3: Checking Jupyter & ipykernel Installation ===" -ForegroundColor Cyan

# Check if Jupyter is installed for the user
$jupyterInstalled = python -m pip show notebook --user 2>$null
$ipykernelInstalled = python -m pip show ipykernel --user 2>$null

if (-not $jupyterInstalled) {
    Write-Host " Jupyter not found. Installing for current user..." -ForegroundColor Yellow
    python -m pip install --user notebook
} else {
    Write-Host " Jupyter already installed for user." -ForegroundColor Green
}

if (-not $ipykernelInstalled) {
    Write-Host " ipykernel not found. Installing for current user..." -ForegroundColor Yellow
    python -m pip install --user ipykernel
} else {
    Write-Host " ipykernel already installed for user." -ForegroundColor Green
}

# 
Write-Host "`n=== Step 4: Registering Jupyter Kernel if Missing ===" -ForegroundColor Cyan

$kernelName = "python_user"
$kernelExists = python -m jupyter kernelspec list 2>$null | Select-String $kernelName

if (-not $kernelExists) {
    python -m ipykernel install --user --name=$kernelName
    if ($LASTEXITCODE -eq 0) {
        Write-Host " Jupyter kernel '$kernelName' registered for VS Code." -ForegroundColor Green
    } else {
        Write-Host " Kernel registration failed." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host " Kernel '$kernelName' already exists." -ForegroundColor Green
}

# 
Write-Host "`n=== Step 5: Creating and Running a Test Jupyter Notebook ===" -ForegroundColor Cyan

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$TestNotebook = Join-Path $DesktopPath "Test_Jupyter.ipynb"

# JSON content for a simple notebook with one code cell
$notebookContent = @"
{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "test-cell",
   "metadata": {},
   "outputs": [],
   "source": [
    "import sys\n",
    "print(' Jupyter test successful!')\n",
    "print('Python version:', sys.version)"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "$kernelName",
   "language": "python",
   "name": "$kernelName"
  },
  "language_info": {
   "name": "python"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
"@

# Save notebook to Desktop
$notebookContent | Out-File -FilePath $TestNotebook -Encoding utf8

Write-Host " Test Jupyter notebook created: $TestNotebook" -ForegroundColor Green

# Try running the notebook headless to verify
Write-Host "`n=== Step 6: Running Test Notebook in Jupyter ===" -ForegroundColor Cyan
jupyter nbconvert --to notebook --execute --inplace "$TestNotebook"

if ($LASTEXITCODE -eq 0) {
    Write-Host " Test notebook executed successfully!" -ForegroundColor Green
    Write-Host "Open it in VS Code or Jupyter Lab to confirm output." -ForegroundColor Cyan
} else {
    Write-Host " Notebook creation succeeded but execution failed. Open it in VS Code to debug." -ForegroundColor Yellow
}

Write-Host "`n=== All checks completed! You can now use Jupyter in VS Code. ===" -ForegroundColor Green
