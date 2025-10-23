@echo off
echo Fixing GitLab Language Server...

:: Restart VS Code Language Server
taskkill /f /im "Code.exe" 2>nul
timeout /t 2

:: Clear VS Code cache
rmdir /s /q "%APPDATA%\Code\User\workspaceStorage" 2>nul
rmdir /s /q "%APPDATA%\Code\logs" 2>nul
rmdir /s /q "%APPDATA%\Code\CachedExtensions" 2>nul

:: Reset GitLab extension
code --uninstall-extension GitLab.gitlab-workflow
code --install-extension GitLab.gitlab-workflow

:: Restart VS Code
start code

echo GitLab Language Server fixed!
pause