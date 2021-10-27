# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from botocore.exceptions import ClientError
import pytest

from ado_queue_function import helpers
from ado_queue_function.tests import test_data as tdata

class TestPutMetric:
    def test_publish_ado_metric(self, cloudwatch_stub):
        cloudwatch_stub.add_response('put_metric_data', tdata.cw_response, tdata.cw_expected_params)
        helpers.put_cw_metric(metric_data=tdata.metric_data)

    @pytest.mark.parametrize('service_error_code', (
        'InvalidParameterValueException','MissingRequiredParameterException', 
        'InvalidParameterCombinationException', 'InternalServiceFault')
    )
    def test_client_error(self, cloudwatch_stub, service_error_code):
        cloudwatch_stub.add_client_error(
            "put_metric_data",
            expected_params = tdata.cw_expected_params,
            service_error_code=service_error_code
        )
        with pytest.raises(ClientError) as excinfo:
            helpers.put_cw_metric(metric_data=tdata.metric_data)
        assert service_error_code in str(excinfo.value)
