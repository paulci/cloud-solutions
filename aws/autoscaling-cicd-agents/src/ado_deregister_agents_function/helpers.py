# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os
from re import search

import boto3
from botocore.exceptions import ClientError
import requests
from requests.exceptions import RequestException

region_name = os.environ.get('region')

# Create Service Client
session = boto3.session.Session()
secretsmanager_client = session.client(
    service_name='secretsmanager',
    region_name=region_name
)


def get_secret() -> str:
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


def get_ado_agent_id(pool_id: int, agent_name: str, access_token: str) -> int:
    org_name = os.environ.get('ado_org_name')
    headers = {'Authorization': 'Basic {}'.format(access_token)}
    url = 'https://dev.azure.com/{}/_apis/distributedtask/pools/{}/agents?agentName={}&api-version=6.1-preview.1'.format(org_name, pool_id, agent_name)
    try:
        response = requests.get(url=url, headers=headers)
        response.raise_for_status()
        response_count = response.json()['count']
        response_values = response.json()['value']
    except RequestException as e:
        raise e
    if not response_count == 1:
        raise ValueError('Expecting 1 result, got {}'.format(response_count))
    return response_values[0]['id']


def delete_ado_agent(pool_id: int, agent_id: int, access_token: str) -> int:
    org_name = os.environ.get('ado_org_name')
    headers = {'Authorization': 'Basic {}'.format(access_token)}
    url = 'https://dev.azure.com/{}/_apis/distributedtask/pools/{}/agents/{}?api-version=6.1-preview.1'.format(org_name, pool_id, agent_id)
    try:
        response = requests.delete(url=url, headers=headers)
        response.raise_for_status()
    except RequestException as e:
        raise e
    return response.status_code


def get_container_host_name(task_data: dict, hostname_key: str, search_type: int) -> str:
    '''
    Recurse through event, searching for container hostname registerd with ADO.

    Type1 - Private IP only (e.g. behind NAT Gateway), pattern is {'Key': 'Value'}
    Type2 - Public IP, pattern is {'Name': 'Key', 'Value': 'Value'}
    
    '''
    if isinstance(task_data, dict):
        if hostname_key in task_data and search_type == 1:
            return task_data[hostname_key]
        if hostname_key in task_data.values() and search_type == 2:
            return task_data['Value']
        for k in task_data:
            item = get_container_host_name(task_data[k], hostname_key, search_type)
            if item is not None:
                return item
    elif isinstance(task_data, list):
        for element in task_data:
            item = get_container_host_name(element, hostname_key, search_type)
            if item is not None:
                return item
    return None
