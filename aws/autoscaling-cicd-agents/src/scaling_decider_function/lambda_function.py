# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


def lambda_handler(event, context) -> dict:
    '''
    Given the waiting job count and idle agent count, make a decision on
    scaling.

    Step Functions depends on the result, so the values should not be updated
    without also updating the workflow definition.

    Parameters:
        event, context : Lambda specific
    Returns:
        Scaling decision
    '''
    waiting, available = event['ado_waiting_jobs'], event['ado_unassigned_agents']
    delta = waiting - available
    result = {
        'decision': 'no-action',
        'delta': abs(delta)
    }
    if delta > 0:
        result['decision'] = 'scale-out'
    if delta < 0:
        result['decision'] = 'scale-in'
    return result
