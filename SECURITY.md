# Security Policy

## Security Scanning

This project uses **Snyk** for comprehensive security scanning:

- **Dependencies**: Python package vulnerabilities
- **Infrastructure**: Terraform misconfigurations
- **Containers**: Docker image vulnerabilities
- **Code**: Security issues in source code

## Running Security Scans

### Snyk (Recommended - Already Configured)
```bash
# Install Snyk CLI (if not already installed)
npm install -g snyk

# Authenticate
snyk auth

# Scan Python dependencies
snyk test --file=app/requirements.txt

# Scan Terraform
snyk iac test terraform/

# Scan all
snyk test
```

### Bandit (Python Security Linter)
```bash
pip install bandit[toml]
bandit -r app/ -ll
```

## Reporting Vulnerabilities

If you discover a security vulnerability, please:
1. **DO NOT** open a public issue
2. Email security details to the repository maintainer
3. Include steps to reproduce
4. Wait for acknowledgment before disclosure

## Security Best Practices

- ✅ All dependencies are regularly updated
- ✅ Secrets are never committed to the repository
- ✅ Infrastructure follows AWS security best practices
- ✅ Code follows secure coding guidelines
- ✅ Regular security scans via Snyk

