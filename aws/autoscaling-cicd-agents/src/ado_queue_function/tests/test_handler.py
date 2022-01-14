# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from unittest.mock import mock_open, patch
import json
import os

import pytest

from ado_queue_function import lambda_function, helpers
from ado_queue_function.tests import test_data as tdata


class MockContext:
    def __init__(self):
        function_name = ''
        function_version = ''
        invoked_function_arn = ''
        memory_limit_in_mb = ''
        aws_request_id = ''
        log_group_name = ''
        log_stream_name = ''

    def get_remaining_time_in_millis(self):
        pass

@patch.dict(os.environ, {
    'ado_org_name': 'myawsscalingorg', 
    'ado_secret_arn': tdata.secret_id, 
    'ado_pool_id': '10', 
    'cw_namespace': 'ADOAgentQueue',
    'agent_cw_metric_prefix': 'Queue',
    'ado_secret_arn': 'arn:aws:secretsmanager:us-east-1:123456789012:secret:MySecret'
    })
class TestLambdaHandler:
    @patch('ado_queue_function.lambda_function.helpers', helpers)
    def test_valid_config_scheduler_invoke(self, secretsmanager_stub, cloudwatch_stub, http_mock_get_single_queue):
        secretsmanager_stub.add_response('get_secret_value', tdata.secrets_response, tdata.secrets_expected_params)
        cloudwatch_stub.add_response('put_metric_data', tdata.cw_response, tdata.cw_expected_params)
        with patch('builtins.open', mock_open(read_data=json.dumps(tdata.valid_cw_data_structure))):
            assert lambda_function.lambda_handler({'source': 'aws.events'}, MockContext()) == tdata.valid_ado_return
    
    @patch('ado_queue_function.lambda_function.helpers', helpers)
    def test_valid_config_unscheduled_invoke(self, secretsmanager_stub, http_mock_get_single_queue):
        secretsmanager_stub.add_response('get_secret_value', tdata.secrets_response, tdata.secrets_expected_params)
        with patch('builtins.open', mock_open(read_data=json.dumps(tdata.valid_cw_data_structure))):
            assert lambda_function.lambda_handler({}, MockContext()) == tdata.valid_ado_return

    @patch.dict(os.environ, {'cw_namespace': ''})
    def test_invalid_config(self):
        with pytest.raises(ValueError) as excinfo:
            lambda_function.lambda_handler({}, MockContext())
        assert 'Namespace' in str(excinfo.value)
