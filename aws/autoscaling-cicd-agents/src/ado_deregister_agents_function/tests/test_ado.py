# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os
from unittest.mock import patch

import httpretty
import pytest
from requests.exceptions import HTTPError

from ado_deregister_agents_function import helpers


@patch.dict(os.environ, {'ado_org_name': 'myawsscalingorg'})
class TestGetAdoAgentId:
    def test_successful_retrieval(self, http_mock_get_single_queue):
        httpretty.enable()
        expected_id = 12
        actual_id = helpers.get_ado_agent_id(pool_id=10, agent_name='ip-172-31-15-112.ec2.internal', access_token='12345')
        assert actual_id == expected_id, 'Expected Agent ID {}, Got Agent ID {}'.format(expected_id, actual_id)

    def test_successful_retrieval_no_results(self, http_mock_get_single_queue_no_result):
        with pytest.raises(ValueError) as excinfo:
            actual_id = helpers.get_ado_agent_id(pool_id=10, agent_name='ip-173-24-25-211.ec2.internal', access_token='12345')
        assert 'Expecting 1 result, got 0' in str(excinfo.value)

    def test_failed_api_call(self, http_mock_get_http_error):
        with pytest.raises(HTTPError) as excinfo:
            helpers.get_ado_agent_id(pool_id=10, agent_name='ip-172-31-15-112.ec2.internal', access_token='12345')
        assert '403 Client Error' in str(excinfo.value)


@patch.dict(os.environ, {'ado_org_name': 'myawsscalingorg'})
class TestDeleteAdoAgent:
    def test_successful_retrieval(self, http_mock_delete):
        httpretty.enable()
        expected_status = 204
        actual_status = helpers.delete_ado_agent(pool_id=10, agent_id=12, access_token='12345')
        assert actual_status == expected_status, 'Expected HTTP {}, Got HTTP {}'.format(expected_status, actual_status)

    def test_failed_api_call(self, http_mock_delete_http_error):
        with pytest.raises(HTTPError) as excinfo:
            helpers.delete_ado_agent(pool_id=10, agent_id=12, access_token='12345')
        assert '403 Client Error' in str(excinfo.value)
