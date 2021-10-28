# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os
from unittest.mock import patch

import pytest
from botocore.stub import Stubber

from service_metrics_function.tests import test_data as tdata


with patch.dict(os.environ, tdata.cw_environment_variables):
    from service_metrics_function import lambda_function

@pytest.fixture(scope='function')
def cloudwatch_stub():
    with Stubber(lambda_function.cloudwatch_client) as stubber:
        yield stubber
        stubber.assert_no_pending_responses()
