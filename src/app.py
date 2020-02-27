import os, boto3, json

client = boto3.client('comprehend')

def lambda_handler(event, context):
    # Get body content
    body = event.get('body')

    sentiment=client.detect_sentiment(Text=body,LanguageCode='fr')
    return {
       'statusCode': status,
       'body': json.dumps(sentiment, indent=2),
       'headers': {
           'Content-Type': 'application/json',
           'Access-Control-Allow-Origin': '*'
       },
   }