@echo off
echo Fixing line endings for Python files...

powershell -Command "Get-ChildItem -Path . -Filter '*.py' -Recurse | ForEach-Object { $content = Get-Content $_.FullName -Raw; $content = $content -replace \"`r`n\", \"`n\"; [System.IO.File]::WriteAllText($_.FullName, $content, [System.Text.UTF8Encoding]::new($false)) }"

echo Line endings fixed!
pause 