# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from datetime import datetime, timezone, timedelta

cw_environment_variables = {
    "cw_namespace": "ECS", 
    'cw_metric': 'AgentServiceCount', 
    'region':'us-east-1'
}
cw_window_end = datetime(2012, 1, 1, 10, 0, tzinfo=timezone.utc)
cw_window_start = cw_window_end - timedelta(minutes=10)
cw_freeze_time = cw_window_end.strftime('%Y-%m-%d %H:%M:%S')
cw_stats_expected_params = {
    'Namespace': 'ECS', 
    'MetricName': 'AgentServiceCount', 
    'StartTime': cw_window_start,
    'EndTime': cw_window_end, 
    'Period': 360, 
    'Statistics': [
        'Maximum'
        ]
}
cw_stats_response = {
    'Label': 'string',
    'Datapoints': [
        {
            'Timestamp': cw_window_end - timedelta(minutes=5),
            'SampleCount': 123.0,
            'Average': 123.0,
            'Sum': 123.0,
            'Minimum': 123.0,
            'Maximum': 123.0,
            'Unit': 'Count',
            'ExtendedStatistics': {
                'string': 123.0
            }
        },
    ]
}
