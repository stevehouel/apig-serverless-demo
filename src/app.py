import os, boto3, json

ESCALATION_INTENT_MESSAGE="Seems that you are having troubles with our service. Would you like to be transferred to the associate?"
FULFILMENT_CLOSURE_MESSAGE="Seems that you are having troubles with our service. Let me transfer you to the associate."

escalation_intent_name = 'Escalate'
client = boto3.client('comprehend')

def lambda_handler(event, context):
    # Get body content
    body = event.get('body')
    body = json.loads(body)

    sentiment=client.detect_sentiment(Text=body.get('message'),LanguageCode='fr')
    return {
       'statusCode': status,
       'body': json.dumps(sentiment, indent=2),
       'headers': {
           'Content-Type': 'application/json',
           'Access-Control-Allow-Origin': '*'
       },
   }