# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os

import pytest
import httpretty
from botocore.stub import Stubber

os.environ['region'] = 'us-east-1'

from ado_deregister_agents_function import helpers

# Botocore Stubs
@pytest.fixture(scope='function')
def secretsmanager_stub():
    with Stubber(helpers.secretsmanager_client) as stubber:
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
        'https://dev.azure.com/myawsscalingorg/_apis/distributedtask/pools/10/agents?agentName=ip-172-31-15-112.ec2.internal&api-version=6.1-preview.1',
        body='{"count":1, "value":[{"id": 12}]}'
    )

@pytest.fixture()
def http_mock_get_single_queue_no_result():
    httpretty.register_uri(
        httpretty.GET,
        'https://dev.azure.com/myawsscalingorg/_apis/distributedtask/pools/10/agents?agentName=ip-173-24-25-211.ec2.internal&api-version=6.1-preview.1',
        body='{"count":0, "value":[]}'
    )

@pytest.fixture()
def http_mock_delete():
    httpretty.register_uri(
        httpretty.DELETE,
        'https://dev.azure.com/myawsscalingorg/_apis/distributedtask/pools/10/agents/12?api-version=6.1-preview.1',
        status=204
    )

@pytest.fixture()
def http_mock_get_http_error():
    httpretty.register_uri(
        httpretty.GET,
        'https://dev.azure.com/myawsscalingorg/_apis/distributedtask/pools/10/agents?agentName=ip-172-31-15-112.ec2.internal&api-version=6.1-preview.1',
        status=403
    )

@pytest.fixture()
def http_mock_delete_http_error():
    httpretty.register_uri(
        httpretty.DELETE,
        'https://dev.azure.com/myawsscalingorg/_apis/distributedtask/pools/10/agents/12?api-version=6.1-preview.1',
        status=403
    )
