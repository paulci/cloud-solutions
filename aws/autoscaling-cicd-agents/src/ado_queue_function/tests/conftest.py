# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os
from httpretty import http

import pytest
from botocore.stub import Stubber
import httpretty

os.environ['region'] = 'us-east-1'

from ado_queue_function import helpers

# Botocore Stubs
@pytest.fixture(scope='function')
def secretsmanager_stub():
    with Stubber(helpers.secretsmanager_client) as stubber:
        yield stubber
        stubber.assert_no_pending_responses()

@pytest.fixture(scope='function')
def cloudwatch_stub():
    with Stubber(helpers.cloudwatch_client) as stubber:
        yield stubber
        stubber.assert_no_pending_responses()


# httpretty API Mocks
@pytest.fixture()
def cleanup_httpretty():
    httpretty.reset()
    httpretty.disable()

@pytest.fixture()
def http_mock_get_single_queue():
    httpretty.register_uri(
        httpretty.GET,
        'https://dev.azure.com/myawsscalingorg/_apis/distributedtask/pools/10/jobrequests?api-version=6.0',
        body='{"count":2, "value":[{"requestId": 1,"assignTime":"2021-05-02T16:22:53.8966667Z"},{"requestId": 2}]}'
    )
    httpretty.register_uri(
        httpretty.GET,
        'https://dev.azure.com/myawsscalingorg/_apis/distributedtask/pools/1200/jobrequests?api-version=6.0',
        body='{"count":0, "value":[]}'
    )

@pytest.fixture()
def http_mock_get_http_error():
    httpretty.register_uri(
        httpretty.GET,
        'https://dev.azure.com/myawsscalingorg/_apis/distributedtask/pools/10/jobrequests?api-version=6.0',
        status=403
    )