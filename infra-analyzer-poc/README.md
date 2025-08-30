# Infrastructure Security Analyzer

AI-powered security analysis for Terraform, Kubernetes, and Helm configurations using AWS Bedrock in GitHub Actions.

## 🚀 Quick Deploy

```bash
git clone <this-repo>
cd infra-analyzer-poc
./deploy.sh
```

## 💰 Cost Breakdown

### AWS Bedrock (Claude 3 Sonnet)
- **Input tokens**: $3.00 per 1K tokens
- **Output tokens**: $15.00 per 1K tokens
- **Per scan**: $0.01 - $0.05 (typical 10-50 files)
- **Monthly estimate**: $1.00 - $3.00 (daily scans)

### GitHub Actions
- **Public repos**: FREE
- **Private repos**: 2000 minutes/month free, then $0.008/minute
- **Typical scan**: 2-5 minutes

### AWS Resources
- **IAM User**: FREE
- **CloudWatch Logs**: ~$0.50/month (7-day retention)

### **Total Monthly Cost: $1.50 - $4.00**

## 🏗️ Architecture

```
GitHub PR → Actions Trigger → Python Script → AWS Bedrock → Security Report
```

## 📋 Setup Instructions

1. **Deploy AWS resources:**
   ```bash
   ./deploy.sh
   ```

2. **Enable Bedrock model access:**
   - AWS Console → Bedrock → Model Access
   - Enable "Anthropic Claude 3 Sonnet"

3. **Add GitHub secrets** (from terraform output):
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

4. **Copy to your repository:**
   ```bash
   cp -r .github/ /path/to/your/repo/
   cp security_analyzer.py /path/to/your/repo/
   ```

## 🔍 What It Detects

- **Security Groups**: Open to 0.0.0.0/0
- **Storage**: Unencrypted S3/EBS/RDS
- **Secrets**: Hardcoded passwords/API keys
- **IAM**: Excessive permissions
- **Containers**: Root users, privileged mode
- **Network**: Insecure configurations
- **Compliance**: Missing tags, policies

## 📊 Sample Output

```
🔒 Infrastructure Security Analysis

❌ 3 critical, 2 medium, 1 low severity issues

🚨 HIGH terraform/main.tf line 15
   Security group allows SSH access from 0.0.0.0/0
   💡 Restrict to specific IP ranges or VPN

⚠️ MEDIUM k8s/deployment.yaml line 25  
   Container running as root user
   💡 Add securityContext with non-root user

📊 Cost Impact: $0.02/month for analysis
```

## 🔧 Customization

Edit `security_analyzer.py` to:
- Add custom security rules
- Modify severity levels  
- Change cost calculations
- Add new file types

## 📈 Monitoring

- **GitHub Security tab**: SARIF results
- **CloudWatch Logs**: Scan history
- **PR comments**: Real-time feedback
- **Build status**: Fails on critical issues

## 🛡️ Security Features

- **Least privilege IAM**: Only Bedrock access
- **No data storage**: Files analyzed in-memory
- **Encrypted transit**: All AWS API calls
- **Audit trail**: CloudWatch logging
