import json

def lambda_handler(event, context):

    body = 'Hello from Lambda, {}!'.format(event['headers']['X-Forwarded-For'])
    return {
        'statusCode': 200,
        'body': json.dumps(body)
    }
