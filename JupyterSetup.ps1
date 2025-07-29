# ========================================
# Check and Fix Jupyter Setup for Regular User in Azure VD
# ========================================

Write-Host "=== Step 1: Checking AppData Local Write Access ===" -ForegroundColor Cyan

$localAppData = $env:LOCALAPPDATA
$testFolder = Join-Path $localAppData "JupyterTest"

Try {
    New-Item -ItemType Directory -Path $testFolder -Force | Out-Null
    if (Test-Path $testFolder) {
        Write-Host "AppData Local is writable: $localAppData" -ForegroundColor Green
        Remove-Item $testFolder -Recurse -Force
    } else {
        Write-Host " Cannot write to AppData Local: $localAppData" -ForegroundColor Red
        exit 1
    }
} Catch {
    Write-Host " Cannot write to AppData Local: $localAppData" -ForegroundColor Red
    exit 1
}

# ========================================
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

# ========================================
Write-Host "`n=== Step 3: Installing Jupyter & ipykernel for user ===" -ForegroundColor Cyan
python -m pip install --user --upgrade pip
python -m pip install --user notebook ipykernel

if ($LASTEXITCODE -eq 0) {
    Write-Host " Jupyter and ipykernel installed for current user." -ForegroundColor Green
} else {
    Write-Host " Failed to install Jupyter. Check if AppData is blocked or storage is redirected." -ForegroundColor Red
    exit 1
}

# ========================================
Write-Host "`n=== Step 4: Registering Jupyter Kernel ===" -ForegroundColor Cyan
python -m ipykernel install --user --name="python_user"

if ($LASTEXITCODE -eq 0) {
    Write-Host " Jupyter kernel 'python_user' registered for VS Code." -ForegroundColor Green
    Write-Host "You can now select it in VS Code → Jupyter Kernel dropdown." -ForegroundColor Cyan
} else {
    Write-Host " Kernel registration failed." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== All checks completed successfully! ===" -ForegroundColor Green

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
    "print('Jupyter test successful!')\n",
    "print('Python version:', sys.version)"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "python_user",
   "language": "python",
   "name": "python_user"
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

Write-Host "Test Jupyter notebook created: $TestNotebook" -ForegroundColor Green

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
