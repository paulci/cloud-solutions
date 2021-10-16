import jwt
from jwt.exceptions import PyJWTError


def lambda_handler(event, context):

    policy = {
        "principalId": "user",
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Effect": "Deny",
                    "Resource": "arn:aws:execute-api:us-east-1:198653053291:y0je959838/*/GET/paul"
                }
            ]
        }
    }
    encoded_payload = event['authorizationToken']
    
    try:
        payload = jwt.decode(encoded_payload, 'mysecret', algorithms=['HS256'])
    except PyJWTError:
        return policy
        
    if payload['name'] == 'paul':
        policy['policyDocument']['Statement'][0]['Effect'] = 'Allow'
    return policy
