# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os

import helpers

def lambda_handler(event, context) -> dict:
    '''
    Construct a cloudwatch payload and validate (using pydantic).

    Retrieve the waiting job and idle agents counts from the given 
    Azure DevOps queue, populating the Cloudwatch payload with the 
    results.

    Write the results to Cloudwatch.

    Parameters:
        event, context : Lambda specific
    Returns:
        Cloudwatch payload
    '''
    ado_pool_id = os.environ.get('ado_pool_id')
    cw_metric_prefix = os.environ.get('agent_cw_metric_prefix')
    queue_config = {
        'ado_pool_id': ado_pool_id,
        'Namespace': os.environ.get('cw_namespace'),
        'MetricData': [
            {
                'MetricName': '{}{}_waiting_jobs'.format(cw_metric_prefix, ado_pool_id)
            },
            {
                'MetricName': '{}{}_unassigned_agents'.format(cw_metric_prefix, ado_pool_id)
            }
        ]
    }
    helpers.QueueConfig(**queue_config)
    ado_access_token = helpers.get_secret()
    waiting_jobs = helpers.get_ado_queue_count(pool_id=queue_config['ado_pool_id'], access_token=ado_access_token)
    idle_agents = helpers.get_ado_idle_count(pool_id=queue_config['ado_pool_id'], access_token=ado_access_token)

    queue_config['MetricData'][0]['Value'] = float(waiting_jobs)
    queue_config['MetricData'][1]['Value'] = float(idle_agents)
    queue_config['waiting_jobs'] = waiting_jobs
    queue_config['idle_agents'] = idle_agents
    
    if event.get('source', False) == 'aws.events':
        helpers.put_cw_metric(queue_config)
    return queue_config

# exception handling (sns/logging) for ADO and CW methods
