# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os

import helpers


def lambda_handler(event, context) -> int:
    '''
    Depending on whether the container is assigned a Public IP, the
    source of the name will be different.

    Retrieve the agent details and deregister the agent from Azure DevOps, once 
    executing jobs are complete.

    This results in container termination in ECS.  As there is no service, the
    container will not relaunch.

    Parameters:
        event, context : Lambda specific
    Returns:
        HTTP Status code from Azure DevOps de-registration
    '''
    container_public_ip = os.environ.get('assign_public_ip', 'UNSET')
    hostname_lookup = {
        'DISABLED': 'RuntimeId',
        'ENABLED': 'privateDnsName',
        'UNSET': None
    }
    search_type_lookup = {
        'DISABLED': 1,
        'ENABLED': 2,
        'UNSET': 1
    }
    hostname_key = hostname_lookup[container_public_ip]
    search_type = search_type_lookup[container_public_ip]
    ado_access_token = helpers.get_secret()
    agent_name = helpers.get_container_host_name(event, hostname_key, search_type)
    pool_id = event['pool_id']
    agent_id = helpers.get_ado_agent_id(pool_id, agent_name, ado_access_token)
    status_code =  helpers.delete_ado_agent(pool_id, agent_id, ado_access_token)
    return status_code
