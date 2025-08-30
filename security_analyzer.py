#!/usr/bin/env python3
import os
import json
import boto3
import glob
import yaml
from datetime import datetime

class SecurityAnalyzer:
    def __init__(self):
        self.bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
        self.total_tokens = 0
        self.api_calls = 0
        
    def analyze_file(self, content, filename):
        prompt = f"""Analyze this infrastructure configuration for security vulnerabilities:

File: {filename}
Content:
{content}

Check for:
- Security groups with 0.0.0.0/0 access
- Unencrypted storage (S3, EBS, RDS)
- Hardcoded secrets/passwords
- Excessive IAM permissions
- Missing security configurations
- Container security issues
- Network misconfigurations

Return JSON format:
{{"issues": [{{"severity": "high|medium|low", "description": "Brief issue description", "line": 10, "recommendation": "How to fix"}}]}}"""

        try:
            response = self.bedrock.invoke_model(
                modelId='anthropic.claude-3-sonnet-20240229-v1:0',
                body=json.dumps({
                    'anthropic_version': 'bedrock-2023-05-31',
                    'max_tokens': 1500,
                    'messages': [{'role': 'user', 'content': prompt}]
                })
            )
            
            self.api_calls += 1
            result = json.loads(response['body'].read())
            content_text = result['content'][0]['text']
            
            # Extract JSON from response
            start = content_text.find('{')
            end = content_text.rfind('}') + 1
            if start != -1 and end != -1:
                return json.loads(content_text[start:end])
            
        except Exception as e:
            print(f"Error analyzing {filename}: {e}")
            
        return {"issues": []}

    def calculate_costs(self):
        # Claude 3 Sonnet pricing: $3 per 1K input tokens, $15 per 1K output tokens
        # Estimate ~500 input + 200 output tokens per file
        input_tokens = self.api_calls * 500
        output_tokens = self.api_calls * 200
        
        input_cost = (input_tokens / 1000) * 3.00
        output_cost = (output_tokens / 1000) * 15.00
        
        return {
            'per_scan': round(input_cost + output_cost, 4),
            'monthly_estimate': round((input_cost + output_cost) * 30, 2),  # Assuming daily scans
            'api_calls': self.api_calls
        }

    def generate_sarif(self, issues):
        sarif = {
            "version": "2.1.0",
            "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
            "runs": [{
                "tool": {
                    "driver": {
                        "name": "Infrastructure Security Analyzer",
                        "version": "1.0.0"
                    }
                },
                "results": []
            }]
        }
        
        for issue in issues:
            sarif["runs"][0]["results"].append({
                "ruleId": f"security-{issue['severity']}",
                "message": {"text": issue['description']},
                "level": "error" if issue['severity'] == 'high' else "warning",
                "locations": [{
                    "physicalLocation": {
                        "artifactLocation": {"uri": issue['file']},
                        "region": {"startLine": issue.get('line', 1)}
                    }
                }]
            })
        
        return sarif

    def run(self):
        # Find all infrastructure files
        patterns = ['**/*.tf', '**/*.tfvars', '**/*.yaml', '**/*.yml']
        files = []
        for pattern in patterns:
            files.extend(glob.glob(pattern, recursive=True))
        
        # Filter out common non-infrastructure files
        exclude = ['.github', 'node_modules', '.git', '__pycache__']
        files = [f for f in files if not any(ex in f for ex in exclude)]
        
        print(f"Analyzing {len(files)} infrastructure files...")
        
        all_issues = []
        for file_path in files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                if len(content.strip()) == 0:
                    continue
                    
                print(f"Analyzing: {file_path}")
                analysis = self.analyze_file(content, file_path)
                
                for issue in analysis.get('issues', []):
                    issue['file'] = file_path
                    all_issues.append(issue)
                    
            except Exception as e:
                print(f"Error reading {file_path}: {e}")
        
        # Calculate costs
        costs = self.calculate_costs()
        
        # Generate summary
        high_count = len([i for i in all_issues if i['severity'] == 'high'])
        medium_count = len([i for i in all_issues if i['severity'] == 'medium'])
        low_count = len([i for i in all_issues if i['severity'] == 'low'])
        
        if high_count > 0:
            summary = f"❌ {high_count} critical, {medium_count} medium, {low_count} low severity issues"
        elif medium_count > 0:
            summary = f"⚠️ {medium_count} medium, {low_count} low severity issues"
        elif low_count > 0:
            summary = f"ℹ️ {low_count} low severity issues"
        else:
            summary = "✅ No security issues detected"
        
        # Save results
        results = {
            'timestamp': datetime.utcnow().isoformat(),
            'summary': summary,
            'issues': all_issues,
            'files_scanned': len(files),
            'estimated_monthly_cost': costs['monthly_estimate'],
            'scan_cost': costs['per_scan']
        }
        
        with open('security-results.json', 'w') as f:
            json.dump(results, f, indent=2)
        
        # Generate SARIF for GitHub Security tab
        sarif = self.generate_sarif(all_issues)
        with open('security-results.sarif', 'w') as f:
            json.dump(sarif, f, indent=2)
        
        print(f"\n📊 Analysis Complete:")
        print(f"   Files scanned: {len(files)}")
        print(f"   Issues found: {len(all_issues)}")
        print(f"   Cost this scan: ${costs['per_scan']}")
        print(f"   Monthly estimate: ${costs['monthly_estimate']}")
        
        return len([i for i in all_issues if i['severity'] == 'high'])

if __name__ == '__main__':
    analyzer = SecurityAnalyzer()
    high_issues = analyzer.run()
    
    if high_issues > 0:
        print(f"\n❌ Exiting with error: {high_issues} high-severity issues found")
        exit(1)
    else:
        print("\n✅ Security scan passed")
        exit(0)
