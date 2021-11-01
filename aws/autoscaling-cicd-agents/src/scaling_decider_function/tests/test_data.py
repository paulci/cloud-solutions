# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

test_values = {
    'ado_waiting_jobs': 0,
    'ado_unassigned_agents': 0
}


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
