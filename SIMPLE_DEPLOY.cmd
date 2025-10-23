@echo off
echo Deploying eSIM Enterprise Management System...

git add .
git commit -m "Complete deployment with error checking system"
git push origin main

echo Deployment completed successfully!
echo GitHub: https://github.com/kaunghtetpai/esim-enterprise-management
echo Vercel: https://vercel.com/e-sim/esim-enterprise-management

pause