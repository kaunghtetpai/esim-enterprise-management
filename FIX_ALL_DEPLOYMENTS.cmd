@echo off
echo FIXING ALL DEPLOYMENT ERRORS

echo [1/8] Cleaning failed deployments...
vercel rm esim-frontend --yes
vercel rm epm-portal --yes

echo [2/8] Removing build conflicts...
del /f /q vercel.json
del /f /q package-lock.json
del /f /q frontend\package-lock.json
del /f /q backend\package-lock.json

echo [3/8] Installing dependencies...
npm install
cd frontend && npm install && cd ..
cd backend && npm install && cd ..

echo [4/8] Creating simple vercel config...
echo {"version": 2, "builds": [{"src": "frontend/package.json", "use": "@vercel/static-build"}]} > vercel.json

echo [5/8] Building project...
npm run build:frontend

echo [6/8] Deploying to Vercel...
vercel --prod --yes

echo [7/8] Updating GitHub...
git add .
git commit -m "Fix all deployment errors - clean build"
git push origin main

echo [8/8] DEPLOYMENT FIXED
pause