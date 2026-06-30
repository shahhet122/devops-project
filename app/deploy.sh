#!/bin/bash
set -e

APP_NAME="devops-project-het7258"
RESOURCE_GROUP="imageapp-rg"

echo "==> Adding gunicorn to requirements..."
grep -q "gunicorn" requirements.txt || echo "gunicorn==21.2.0" >> requirements.txt

echo "==> Zipping app..."
zip -r ../app.zip . --exclude "*.pyc" --exclude "__pycache__/*"

echo "==> Setting startup command..."
az webapp config set \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --startup-file "gunicorn --bind=0.0.0.0:8000 app:app"

echo "==> Deploying to Azure App Service..."
az webapp deploy \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --src-path "../app.zip" \
  --type zip

echo "==> Done! App is live at: https://$APP_NAME.azurewebsites.net"
