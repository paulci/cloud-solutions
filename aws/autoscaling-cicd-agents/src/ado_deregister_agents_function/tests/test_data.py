# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from datetime import datetime

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

private_ado_agent_hostname = '59cb4b3fa1944cc0ba07d0b7e07d9651-125038134'
private_ip_event_task_data = {
    'describe_input': {
        'Tasks':[
            {
                'Containers': [
                    {
                        'RuntimeId': private_ado_agent_hostname
                    }

                ]
            }
        ]
    },
    'pool_id': 10
}

public_ado_agent_hostname = 'ip-172-31-15-112.ec2.internal'
public_ip_event_task_data = {
    'describe_input': {
        'Tasks':[
            {
                'Attachments': [
                    {
                        'Details': [
                            {
                                'Name': 'privateDnsName',
                                'Value': public_ado_agent_hostname
                            }
                        ]
                    }

                ]
            }
        ]
    },
    'pool_id': 10
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
