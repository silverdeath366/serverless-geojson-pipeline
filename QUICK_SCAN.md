# Quick Snyk Scan Guide

## After Pushing to GitHub

### Option 1: Snyk Web UI (Easiest)
1. Go to https://app.snyk.io
2. Click "Add Project" → "GitHub"
3. Select your repository
4. Snyk scans automatically
5. View results in dashboard

### Option 2: Snyk CLI (Quick Commands)

```bash
# 1. Install & Authenticate (if not done)
npm install -g snyk
snyk auth

# 2. Scan Python dependencies
snyk test --file=app/requirements.txt --severity-threshold=high
snyk test --file=app/requirements-lambda.txt --severity-threshold=high

# 3. Scan Terraform
snyk iac test terraform/ --severity-threshold=high

# 4. Full scan (all at once)
snyk test --all-projects --severity-threshold=high
```

### Option 3: GitHub Actions (Automatic)

If you added the `SNYK_TOKEN` secret:
- Go to repository → Actions tab
- Security scan runs automatically
- View results there

## What to Share

After scanning, share:
- Any **CRITICAL** vulnerabilities
- Any **HIGH** vulnerabilities  
- Screenshot or text output

I'll help fix them! 🔧

