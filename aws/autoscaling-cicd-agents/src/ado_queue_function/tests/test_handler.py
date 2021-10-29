# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from unittest.mock import mock_open, patch
import json

from botocore.exceptions import ValidationError
from pydantic import ValidationError
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


class TestLambdaHandler:
    @patch('ado_queue_function.lambda_function.helpers', helpers)
    def test_valid_config(self, secretsmanager_stub, cloudwatch_stub):
        secretsmanager_stub.add_response('get_secret_value', tdata.secrets_response, tdata.secrets_expected_params)
        cloudwatch_stub.add_response('put_metric_data', tdata.cw_response, tdata.cw_expected_params)
        with patch('builtins.open', mock_open(read_data=json.dumps(tdata.valid_cw_data_structure))):
            lambda_function.lambda_handler({}, MockContext())

    def test_invalid_config(self):
        with patch('builtins.open', mock_open(read_data=json.dumps(tdata.invalid_cw_data_structure))):
            with pytest.raises(ValidationError) as excinfo:
                lambda_function.lambda_handler({}, MockContext())
        assert 'Namespace' in str(excinfo.value)
