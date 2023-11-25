# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import json
import lambda_function

def test_lambda_handler():
    event = {
        'headers': {
            'X-Forwarded-For': '127.0.0.1'
        }
    }
    expected_body = 'Hello from Lambda, 127.0.0.1!'
    expected_response = {
        'statusCode': 200,
        'body': json.dumps(expected_body)
    }

    response = lambda_function.lambda_handler(event, None)

    assert response == expected_response
