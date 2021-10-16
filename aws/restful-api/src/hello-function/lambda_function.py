# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import json

def lambda_handler(event, context):

    body = 'Hello from Lambda, {}!'.format(event['headers']['X-Forwarded-For'])
    return {
        'statusCode': 200,
        'body': json.dumps(body)
    }
