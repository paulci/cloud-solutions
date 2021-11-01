# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

import os
from unittest.mock import patch

from ado_deregister_agents_function import helpers
from ado_deregister_agents_function.tests import test_data as tdata


class TestGetContainerHostName:
    def test_public_subnet(self):
        assert helpers.get_container_host_name(tdata.public_ip_event_task_data, 'privateDnsName', 2) == tdata.public_ado_agent_hostname

    def test_private_subnet(self):
        assert helpers.get_container_host_name(tdata.private_ip_event_task_data, 'RuntimeId', 1) == tdata.private_ado_agent_hostname

    def test_no_matching_data(self):
        assert helpers.get_container_host_name({}, None, 1) == None
