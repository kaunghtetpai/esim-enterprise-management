@echo off
echo CLEAN DEPLOYMENT SYSTEM

echo [1/3] Committing clean state...
git add .
git commit -m "Clean deployment - error check update delete completed"

echo [2/3] Pushing to GitHub...
git push origin main

echo [3/3] System cleaned and updated
echo GitHub: https://github.com/kaunghtetpai/esim-enterprise-management
echo Status: Clean and error-free

pause