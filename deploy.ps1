# Set script to exit on error
$ErrorActionPreference = "Stop"

# Define a mandatory parameter for the commit message
param(
    [Parameter(Mandatory=$true, HelpMessage="Please provide a commit message.")]
    [string]$CommitMsg
)

Write-Host "Starting deployment process..." -ForegroundColor Green

# --- Git Operations ---
Write-Host "Running Git operations..." -ForegroundColor Yellow
git add .
git commit -m "$CommitMsg"
git push
Write-Host "Git code pushed successfully." -ForegroundColor Green

# --- Hexo Operations ---
Write-Host "Cleaning and generating Hexo site..." -ForegroundColor Yellow
hexo clean
hexo generate -d
Write-Host "Hexo site generated and deployed successfully." -ForegroundColor Green

Write-Host "All operations completed!" -ForegroundColor Green
