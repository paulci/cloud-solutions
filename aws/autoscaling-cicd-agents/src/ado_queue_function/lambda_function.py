# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os
import json

import helpers

def lambda_handler(event, context) -> dict:
    config_path = 'config/'
    config_files = os.listdir(config_path)
    for file in config_files:
        file_name = '{}{}'.format(config_path, file)
        with open(file_name, 'r') as f:
            queue_config = json.loads(f.read())
        helpers.QueueConfig(**queue_config)
        ado_access_token = helpers.get_secret()
        queue_config['MetricData'][0]['Value'] = float(helpers.get_ado_queue_count(pool_id=queue_config['ado_pool_id'], access_token=ado_access_token))
        queue_config['MetricData'][1]['Value'] = float(helpers.get_ado_idle_count(pool_id=queue_config['ado_pool_id'], access_token=ado_access_token))
        if event.get('source', False) == 'aws.events':
            helpers.put_cw_metric(queue_config)
    return queue_config

# exception handling (sns/logging) for ADO and CW methods