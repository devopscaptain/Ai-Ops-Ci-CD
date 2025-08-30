import json
import boto3
import yaml

bedrock = boto3.client('bedrock-runtime')
s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    
    # Get config file from S3
    response = s3.get_object(Bucket=bucket, Key=key)
    content = response['Body'].read().decode('utf-8')
    
    # Analyze with Bedrock
    prompt = f"""
    Analyze this infrastructure configuration for security misconfigurations and compliance issues:
    
    {content}
    
    Check for:
    - Security groups with 0.0.0.0/0 access
    - Unencrypted storage
    - Missing resource tags
    - Excessive permissions
    - Hardcoded secrets
    
    Return JSON format: {{"issues": [{{"type": "security", "severity": "high", "description": "...", "line": 10}}]}}
    """
    
    response = bedrock.invoke_model(
        modelId='anthropic.claude-3-sonnet-20240229-v1:0',
        body=json.dumps({
            'anthropic_version': 'bedrock-2023-05-31',
            'max_tokens': 1000,
            'messages': [{'role': 'user', 'content': prompt}]
        })
    )
    
    result = json.loads(response['body'].read())
    analysis = result['content'][0]['text']
    
    # Store results
    s3.put_object(
        Bucket=bucket,
        Key=f"results/{key}.json",
        Body=analysis
    )
    
    return {'statusCode': 200, 'body': analysis}
