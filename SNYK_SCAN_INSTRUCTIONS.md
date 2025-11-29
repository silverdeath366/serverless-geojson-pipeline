# Snyk Security Scan Instructions

## Method 1: Snyk GitHub Integration (Recommended - Automatic)

If Snyk is already connected to your GitHub account:

1. **Go to Snyk Dashboard**: https://app.snyk.io
2. **Add Project**:
   - Click "Add Project" or "+" button
   - Select "GitHub" as source
   - Find your repository: `aws-geojson-processing-pipeline`
   - Click "Add selected repositories"
3. **Snyk will automatically scan**:
   - Python dependencies (`requirements.txt`, `requirements-lambda.txt`)
   - Terraform files
   - Dockerfile
   - Code vulnerabilities

## Method 2: Snyk CLI (Manual Scan)

### Install Snyk CLI (if not installed)
```bash
# Install via npm (if you have Node.js)
npm install -g snyk

# Or via Homebrew (Mac)
brew tap snyk/tap
brew install snyk

# Or download binary
# https://github.com/snyk/snyk/releases
```

### Authenticate
```bash
snyk auth
# This will open browser to authenticate
```

### Run Scans

#### 1. Scan Python Dependencies
```bash
# From project root
cd app
snyk test --file=requirements.txt
snyk test --file=requirements-lambda.txt
```

#### 2. Scan Terraform (Infrastructure as Code)
```bash
# From project root
cd terraform
snyk iac test .
```

#### 3. Scan Dockerfile
```bash
# From project root
cd app
snyk container test Dockerfile
```

#### 4. Full Scan (All at once)
```bash
# From project root
snyk test --all-projects
```

### Scan with Specific Severity
```bash
# Only show HIGH and CRITICAL
snyk test --severity-threshold=high

# For Terraform
snyk iac test terraform/ --severity-threshold=high
```

## Method 3: GitHub Actions (Automatic on Push)

If you've pushed the `.github/workflows/security.yml` file:

1. **Go to your repository on GitHub**
2. **Click "Actions" tab**
3. **The security scan will run automatically** on push
4. **View results** in the Actions tab

### To enable Snyk in GitHub Actions:
1. Go to repository Settings → Secrets and variables → Actions
2. Add secret: `SNYK_TOKEN`
3. Get token from: https://app.snyk.io/account
4. Add the token as `SNYK_TOKEN` secret

## What Snyk Will Scan

### ✅ Python Dependencies
- `app/requirements.txt`
- `app/requirements-lambda.txt`
- Known CVEs in packages
- Outdated packages

### ✅ Infrastructure as Code
- `terraform/` directory
- Security misconfigurations
- Overly permissive IAM policies
- Public resources
- Missing encryption

### ✅ Docker Images
- `app/Dockerfile`
- Base image vulnerabilities
- Package vulnerabilities in image

### ✅ Code Security
- Hardcoded secrets
- Security anti-patterns
- Insecure functions

## Understanding Results

### Severity Levels:
- **CRITICAL**: Fix immediately
- **HIGH**: Fix as soon as possible
- **MEDIUM**: Fix when convenient
- **LOW**: Consider fixing

### What to Share:
After scanning, share:
1. **CRITICAL** vulnerabilities (if any)
2. **HIGH** vulnerabilities (if any)
3. Screenshot or output of the scan results

I'll help you fix them!

## Quick Commands Summary

```bash
# Authenticate (first time only)
snyk auth

# Scan everything
snyk test --all-projects --severity-threshold=high

# Scan Terraform specifically
snyk iac test terraform/ --severity-threshold=high

# Scan Python dependencies
snyk test --file=app/requirements.txt --severity-threshold=high
```

## After Scanning

1. **Review results** in Snyk dashboard or CLI output
2. **Share HIGH/CRITICAL findings** with me
3. **I'll help fix** any vulnerabilities found
4. **Re-scan** to verify fixes

