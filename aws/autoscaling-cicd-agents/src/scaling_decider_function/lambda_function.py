# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


def lambda_handler(event, context) -> tuple:
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
