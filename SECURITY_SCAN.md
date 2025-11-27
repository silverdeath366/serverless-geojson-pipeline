# Security Scanning with Trivy

## Quick Scan Commands

### 1. Scan Python Dependencies
```bash
trivy fs --severity HIGH,CRITICAL app/
```

### 2. Scan Dockerfile
```bash
trivy image --severity HIGH,CRITICAL --input app/Dockerfile
```

### 3. Scan Terraform for Misconfigurations
```bash
trivy config --severity HIGH,CRITICAL terraform/
```

### 4. Full Security Scan
```bash
# Install Trivy (if not installed)
# For WSL/Ubuntu:
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Run comprehensive scan
trivy fs --severity HIGH,CRITICAL .
```

