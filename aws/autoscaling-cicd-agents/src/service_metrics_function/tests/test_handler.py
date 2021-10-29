# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os
from unittest.mock import patch

import pytest
from botocore.exceptions import ClientError
from freezegun import freeze_time

from service_metrics_function import lambda_function
from service_metrics_function.tests import test_data as tdata


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
    

@freeze_time(tdata.cw_freeze_time)
@patch.dict(os.environ, tdata.cw_environment_variables)
class TestLambdaHandler:
    def test_valid_config(self, cloudwatch_stub):
        cloudwatch_stub.add_response('get_metric_statistics', tdata.cw_stats_response, tdata.cw_stats_expected_params)
        assert lambda_function.lambda_handler({}, MockContext()) == tdata.cw_stats_response['Datapoints'][0]['Maximum']

    @pytest.mark.parametrize('service_error_code', (
        'InvalidParameterValueException','MissingRequiredParameterException', 
        'InvalidParameterCombinationException', 'InternalServiceFault')
    )
    def test_client_error(self, cloudwatch_stub, service_error_code):
        cloudwatch_stub.add_client_error(
            "get_metric_statistics",
            expected_params = tdata.cw_stats_expected_params,
            service_error_code=service_error_code
        )
        with pytest.raises(ClientError) as excinfo:
            lambda_function.lambda_handler({}, MockContext())
        assert service_error_code in str(excinfo.value)
