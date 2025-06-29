# PowerShell script to fix line endings for Python files
# This converts Windows CRLF line endings to Unix LF line endings

Write-Host "Fixing line endings for Python files..." -ForegroundColor Green

# Get all Python files
$pythonFiles = Get-ChildItem -Path . -Filter "*.py" -Recurse

foreach ($file in $pythonFiles) {
    Write-Host "Processing: $($file.FullName)" -ForegroundColor Yellow
    
    # Read file content
    $content = Get-Content -Path $file.FullName -Raw
    
    # Replace CRLF with LF
    $content = $content -replace "`r`n", "`n"
    
    # Write back to file with UTF-8 encoding without BOM
    [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.UTF8Encoding]::new($false))
    
    Write-Host "Fixed: $($file.Name)" -ForegroundColor Green
}

Write-Host "Line endings fixed for all Python files!" -ForegroundColor Green
Write-Host "You can now run the test script on Linux." -ForegroundColor Cyan 