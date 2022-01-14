# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os
from datetime import datetime
from copy import deepcopy

# ADO Data
waiting_jobs = 1
idle_agents = 1

# Secrets Manager Stub Data
secret_id = 'arn:aws:secretsmanager:us-east-1:123456789012:secret:MySecret'
secrets_expected_params = {'SecretId': secret_id}
secret = 'mysecretstring'
secrets_response = {
    'ARN': secret_id,
    'Name': 'MySecret',
    'VersionId': '123456789012-123456789012-123456789012',
    'SecretString': secret,
    'VersionStages': [
        'string',
    ],
    'CreatedDate': datetime(2015, 1, 1)
}

# Cloudwatch Stub Data
metric_data = {
    'Namespace': 'ADOAgentQueue',
    'MetricData': [{
        'MetricName': 'Queue10_waiting_jobs',
        'Value': float(waiting_jobs)
    },
    {
        'MetricName': 'Queue10_unassigned_agents',
        'Value': float(idle_agents)
    }]
}
cw_response = {}
cw_expected_params = metric_data

# Cloudwatch Payloads
valid_cw_data_structure = {
    'ado_pool_id': '10',
    'Namespace': 'ADOAgentQueue',
    'MetricData': [{
        'MetricName': 'Queue10_waiting_jobs',
    },
    {
        'MetricName': 'Queue10_unassigned_agents',
    }
    ]
}

invalid_cw_data_structure = deepcopy(valid_cw_data_structure)
invalid_cw_data_structure.pop('Namespace')

# ADO Data
valid_ado_return = deepcopy(valid_cw_data_structure)
valid_ado_return['MetricData'] = metric_data['MetricData']
valid_ado_return['waiting_jobs'] = waiting_jobs
valid_ado_return['idle_agents'] = idle_agents