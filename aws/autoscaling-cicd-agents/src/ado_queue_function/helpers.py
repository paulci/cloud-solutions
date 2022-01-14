# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os
from typing import List

import boto3
from botocore.exceptions import ClientError
import requests
from requests import RequestException
from pydantic import BaseModel, validator

region_name = os.environ.get('region')

# Create Service Clients
session = boto3.session.Session()
secretsmanager_client = session.client(
    service_name='secretsmanager',
    region_name=region_name
)
cloudwatch_client = session.client(
    service_name='cloudwatch',
    region_name=region_name
)


# Config Validation
class MetricData(BaseModel):
    MetricName: str
    Value: float = 0
    Unit: str = 'Count'

class QueueConfig(BaseModel):
    ado_pool_id: str
    Namespace: str
    MetricData: List[MetricData]

    @validator('*', pre=True)
    def not_set(cls, v):
        if v not in ['', None, 0]:
            return v
        else:
            raise ValueError('Value is unset')


def get_secret() -> str:
    '''
    Retrieve base64encoded PAT from Secrets Manager
    '''
    secret_name = os.environ.get('ado_secret_arn')
    try:
        get_secret_value_response = secretsmanager_client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            raise e
    else:
        return get_secret_value_response.get('SecretString', 'nosecret')


def get_ado_queue_count(pool_id: int, access_token: str) -> int:
    '''
    Retrieve the count of unassigned jobs in the given Azure DevOps queue

    Parameters:
        pool_id (int):      Azure DevOps Pool ID
        access_token (str): base64encoded PAT
    Returns:
        Count of waiting jobs
    '''
    org_name = os.environ.get('ado_org_name')
    headers = {'Authorization': 'Basic {}'.format(access_token)}
    url = 'https://dev.azure.com/{}/_apis/distributedtask/pools/{}/jobrequests?api-version=6.0'.format(org_name, pool_id)
    try:
        response = requests.get(url=url, headers=headers)
        response.raise_for_status()
    except RequestException as e:
        raise e
    waiting_jobs = [x for x in response.json()['value'] if not x.get('assignTime')]
    return len(waiting_jobs)


def get_ado_idle_count(pool_id: int, access_token: str) -> int:
    '''
    Retrieve the count of idle Azure DevOps agents in the given pool

    Parameters:
        pool_id (int):      Azure DevOps Pool ID
        access_token (str): base64encoded PAT
    Returns:
        Count of idle agents
    '''
    org_name = os.environ.get('ado_org_name')
    headers = {'Authorization': 'Basic {}'.format(access_token)}
    url = 'https://dev.azure.com/{}/_apis/distributedtask/pools/{}/agents?includeAssignedRequest=true&api-version=6.1-preview.1'.format(org_name, pool_id)
    try:
        response = requests.get(url=url, headers=headers)
        response.raise_for_status()
    except RequestException as e:
        raise e
    idle_agents = [x for x in response.json()['value'] if not x.get('assignedRequest') and x['status'] == 'online']
    return len(idle_agents)


def put_cw_metric(metric_data: dict):
    '''
    Write the waiting jobs count and idle agents count for the given pool to Cloudwatch

    Parameters:
        metric_data (dict): Cloudwatch payload with updated agent/job counts
    Returns:
        None
    '''
    try:
        cloudwatch_client.put_metric_data(
            Namespace=metric_data['Namespace'],
            MetricData=metric_data['MetricData']
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
