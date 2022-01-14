# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from copy import deepcopy

from scaling_decider_function import lambda_function
from scaling_decider_function.tests import test_data as tdata


class TestLambdaHandler:
    def test_scale_out(self):
        scale_out_values = deepcopy(tdata.test_values)
        scale_out_values['ado_waiting_jobs'] = 5
        assert lambda_function.lambda_handler(scale_out_values, tdata.MockContext()) == {'decision': 'scale-out', 'delta': 5}

    def test_scale_in(self):
        scale_in_values = deepcopy(tdata.test_values)
        scale_in_values['ado_unassigned_agents'] = 2
        assert lambda_function.lambda_handler(scale_in_values, tdata.MockContext()) == {'decision': 'scale-in', 'delta': 2}

    def test_do_nothing(self):
        no_action_values = deepcopy(tdata.test_values)
        assert lambda_function.lambda_handler(no_action_values, tdata.MockContext()) == {'decision': 'no-action', 'delta': 0}
