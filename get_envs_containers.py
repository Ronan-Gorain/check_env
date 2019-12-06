#!/bin/env python3

import sys
import json
sys.path.append('/usr/local/lib')
from pylastic import Jelastic

PASSWORD = sys.argv[1]
ENV = "app." + sys.argv[3]
ACCOUNT = sys.argv[4]

jel_session = Jelastic(hostname=ENV,
                       login=ACCOUNT,
                       password=PASSWORD)
jel_session.signIn()

ids = ""
res = jel_session.envControlGetEnvInfo(sys.argv[2])
for node in res['nodes']:
    ids = ids + " " + str(node['nodeGroup'][:2]) + str(node['id'])

jel_session.signOut()
print(ids)

