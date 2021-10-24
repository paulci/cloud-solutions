# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os
from datetime import datetime

from botocore.exceptions import ClientError
import pytest

from ado_queue_function import helpers
from ado_queue_function.tests import test_data as tdata


class TestGetSecret:
    def test_recover_secret(self, secretsmanager_stub):
        secretsmanager_stub.add_response('get_secret_value', tdata.secrets_response, tdata.secrets_expected_params)
        assert helpers.get_secret() == tdata.secret

    @pytest.mark.parametrize('service_error_code', (
        'DecryptionFailureException','InternalServiceErrorException', 
        'InvalidParameterException', 'InvalidRequestException', 'ResourceNotFoundException')
    )
    def test_client_error(self, secretsmanager_stub, service_error_code):
        secretsmanager_stub.add_client_error(
            "get_secret_value",
            expected_params = tdata.secrets_expected_params,
            service_error_code=service_error_code
        )
        with pytest.raises(ClientError) as excinfo:
            assert helpers.get_secret() == 'string'
        assert service_error_code in str(excinfo.value)
