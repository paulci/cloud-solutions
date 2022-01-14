# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from unittest.mock import patch
import os

import pytest
import httpretty

from ado_deregister_agents_function import lambda_function, helpers
from ado_deregister_agents_function.tests import test_data as tdata


@patch.dict(os.environ, {'ado_org_name': 'myawsscalingorg', 'ado_secret_arn': tdata.secret_id})
class TestLambdaHandler:

    @patch.dict(os.environ, {'assign_public_ip': 'ENABLED'})
    @patch('ado_deregister_agents_function.lambda_function.helpers', helpers)
    def test_valid_config_scheduler_invoke_public_ip(self, secretsmanager_stub, http_mock_get_single_queue):
        httpretty.enable()
        secretsmanager_stub.add_response('get_secret_value', tdata.secrets_response, tdata.secrets_expected_params)
        expected_status = 204
        actual_status =  lambda_function.lambda_handler(tdata.public_ip_event_task_data, tdata.MockContext())
        assert actual_status == expected_status

    @patch.dict(os.environ, {'assign_public_ip': 'DISABLED'})    
    @patch('ado_deregister_agents_function.lambda_function.helpers', helpers)
    def test_valid_config_scheduler_invoke_private_ip(self, secretsmanager_stub, http_mock_get_single_queue):
        secretsmanager_stub.add_response('get_secret_value', tdata.secrets_response, tdata.secrets_expected_params)
        expected_status = 204
        actual_status =  lambda_function.lambda_handler(tdata.private_ip_event_task_data, tdata.MockContext())
        assert actual_status == expected_status
