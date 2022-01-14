# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os
from datetime import datetime, timezone, timedelta

import boto3
from botocore.exceptions import ClientError

region_name = os.environ.get('region')

# Create Service Client
session = boto3.session.Session()
cloudwatch_client = session.client(
    service_name='cloudwatch',
    region_name=region_name
)


def lambda_handler(event, context):
    '''
    Retrieve the Cloudwatch-backed metrics representing the
    Azure DevOps waiting jobs and idle agents.

    Surplus to requirements.

    Parameters:
        event, context : Lambda specific
    Returns:
        Scaling decision
    '''
    cw_namespace = os.environ.get('cw_namespace')
    cw_metric = os.environ.get('cw_metric')
    end_time = datetime.now(timezone.utc)
    start_time = end_time - timedelta(minutes=10)
    try:
        get_service_metrics_response = cloudwatch_client.get_metric_statistics(
            Namespace=cw_namespace, 
            MetricName=cw_metric, 
            StartTime=start_time,
            EndTime=end_time, 
            Period=360, 
            Statistics=[
                'Maximum'
            ]
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidParameterValueException':
            raise e
        elif e.response['Error']['Code'] == 'MissingRequiredParameterException':
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterCombinationException':
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceFault':
            raise e
    else:
        return get_service_metrics_response['Datapoints'][0].get('Maximum', None)
