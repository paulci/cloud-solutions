# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os
from unittest.mock import MagicMock, patch

from lambda_function import lambda_handler, get_secret


class TestLambdaHandler:
    def test_lambda_handler_with_valid_token(self):
        event = {
            'methodArn': 'arn:aws:execute-api:us-west-2:123456789012:api-id/stage/GET/resource',
            'authorizationToken': 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzb21lIjoicGF5bG9hZCJ9.U0EMe-4E2GDRhy3C3Keujq51dLMfinN10SubEwKHch8'
        }
        context = MagicMock()

        with patch('lambda_function.get_secret') as mock_get_secret:
            mock_get_secret.return_value = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'

            response = lambda_handler(event, context)

            assert response['policyDocument']['Statement'][0]['Effect'] == 'Allow'

    def test_lambda_handler_with_invalid_token(self):
        event = {
            'methodArn': 'arn:aws:execute-api:us-west-2:123456789012:api-id/stage/GET/resource',
            'authorizationToken': 'invalid_token'
        }
        context = MagicMock()

        with patch('lambda_function.get_secret') as mock_get_secret:
            mock_get_secret.return_value = 'secret_key'

            response = lambda_handler(event, context)

            assert response['policyDocument']['Statement'][0]['Effect'] == 'Deny'

    def test_get_secret(self):
        os.environ['jwt_secret_arn'] = 'secret_arn'
        os.environ['region'] = 'us-west-2'

        secret_value = 'secret_key'

        client_mock = MagicMock()
        client_mock.get_secret_value.return_value = {
            'SecretString': secret_value
        }

        session_mock = MagicMock()
        session_mock.client.return_value = client_mock

        with patch('boto3.session.Session') as mock_session:
            mock_session.return_value = session_mock

            secret = get_secret()

            assert secret == secret_value