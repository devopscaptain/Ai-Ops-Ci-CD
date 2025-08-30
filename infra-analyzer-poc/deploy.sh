#!/bin/bash
set -e

echo "🚀 Deploying Infrastructure Security Analyzer"
echo "============================================="

# Check prerequisites
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Install from: https://terraform.io"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Install from: https://aws.amazon.com/cli/"
    exit 1
fi

# Deploy infrastructure
cd infrastructure
echo "📦 Initializing Terraform..."
terraform init

echo "📋 Planning deployment..."
terraform plan

echo "🏗️ Deploying AWS resources..."
terraform apply -auto-approve

echo "🔑 Getting AWS credentials for GitHub..."
AWS_ACCESS_KEY=$(terraform output -raw aws_access_key_id)
AWS_SECRET_KEY=$(terraform output -raw aws_secret_access_key)

cd ..

echo ""
echo "✅ Deployment Complete!"
echo "======================="
echo ""
echo "📋 Next Steps:"
echo "1. Add these secrets to your GitHub repository:"
echo "   - AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY"
echo "   - AWS_SECRET_ACCESS_KEY: [hidden - check terraform output]"
echo ""
echo "2. Copy files to your repository:"
echo "   cp -r .github/ /path/to/your/repo/"
echo "   cp security_analyzer.py /path/to/your/repo/"
echo ""
echo "💰 Cost Breakdown (Monthly Estimates):"
echo "======================================="
echo "AWS Bedrock Claude 3 Sonnet:"
echo "  - Per scan: ~\$0.01 - \$0.05 (depends on file size)"
echo "  - Daily scans: ~\$0.30 - \$1.50/month"
echo "  - Per PR scan: ~\$0.01 - \$0.03"
echo ""
echo "GitHub Actions:"
echo "  - Free for public repos"
echo "  - Private repos: 2000 minutes/month free"
echo "  - Additional: \$0.008/minute"
echo ""
echo "AWS IAM User: FREE"
echo "CloudWatch Logs: ~\$0.50/month (7-day retention)"
echo ""
echo "💡 Total Estimated Cost: \$1-3/month for typical usage"
echo ""
echo "🔧 Enable Bedrock Model Access:"
echo "1. Go to AWS Console > Bedrock > Model Access"
echo "2. Enable 'Anthropic Claude 3 Sonnet'"
echo "3. Wait for approval (usually instant)"

# Show terraform outputs securely
echo ""
echo "🔐 Run this to see GitHub secrets:"
echo "cd infrastructure && terraform output setup_instructions"
