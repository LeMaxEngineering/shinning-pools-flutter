# PowerShell script to configure CORS for Firebase Storage
# This script requires Google Cloud SDK to be installed

Write-Host "Configuring CORS for Firebase Storage..." -ForegroundColor Green

# Check if gsutil is available
try {
    $gsutilVersion = gsutil version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "gsutil found. Configuring CORS..." -ForegroundColor Green
        
        # Set CORS configuration
        gsutil cors set config/cors.json gs://shinningpools-8049e.appspot.com
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "CORS configuration applied successfully!" -ForegroundColor Green
            Write-Host "You may need to wait a few minutes for changes to take effect." -ForegroundColor Yellow
        } else {
            Write-Host "Failed to apply CORS configuration." -ForegroundColor Red
        }
    } else {
        Write-Host "gsutil not found. Please install Google Cloud SDK first." -ForegroundColor Red
        Write-Host "Download from: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: gsutil not found or not accessible." -ForegroundColor Red
    Write-Host "Please install Google Cloud SDK and ensure it's in your PATH." -ForegroundColor Yellow
}

Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 