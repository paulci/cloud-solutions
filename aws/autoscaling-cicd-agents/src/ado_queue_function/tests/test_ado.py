# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os
from unittest.mock import patch

import httpretty
import pytest
from requests.exceptions import HTTPError

from ado_queue_function import helpers


@patch.dict(os.environ, {'ado_org_name': 'myawsscalingorg'})
class TestGetAdoQueueCount:
    def test_successful_retrieval(self, http_mock_get_single_queue):
        httpretty.enable()
        expected_waiting = 1
        actual_waiting = helpers.get_ado_queue_count(pool_id=10, access_token='12345')
        assert actual_waiting == expected_waiting, 'Expected {} Waiting Jobs, Got {}'.format(expected_waiting, actual_waiting)

    def test_failed_api_call(self, http_mock_get_http_error):
        with pytest.raises(HTTPError) as excinfo:
            helpers.get_ado_queue_count(pool_id=10, access_token='12345')
        assert '403 Client Error' in str(excinfo.value)


@patch.dict(os.environ, {'ado_org_name': 'myawsscalingorg'})
class TestGetIdleAgents:
    def test_successful_retrieval(self, http_mock_get_single_queue):
        expected_waiting = 1
        actual_waiting = helpers.get_ado_idle_count(pool_id=10, access_token='12345')
        assert actual_waiting == expected_waiting, 'Expected {} Waiting Jobs, Got {}'.format(expected_waiting, actual_waiting)

    def test_failed_api_call(self, http_mock_get_http_error):
        with pytest.raises(HTTPError) as excinfo:
            helpers.get_ado_idle_count(pool_id=10, access_token='12345')
        assert '403 Client Error' in str(excinfo.value)
