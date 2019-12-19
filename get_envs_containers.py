#!/bin/env python3

import sys
import json
sys.path.append('/usr/local/lib')
from pylastic import Jelastic

PASSWORD = sys.argv[1]
ENV = "app." + sys.argv[3]
ACCOUNT = sys.argv[4]
USER = sys.argv[5] if len(sys.argv) > 5 else None

jel_session = Jelastic(hostname=ENV,
                       login=ACCOUNT,
                       password=PASSWORD)
jel_session.signIn()
if USER:
    user_token = jel_session.sysAdminSignAsUser(USER)
    user_session = Jelastic(hostname=ENV, login=USER,
                            session=user_token)
    res = user_session.envControlGetEnvInfo(sys.argv[2])
    user_session.signOut()
else:
    res = jel_session.envControlGetEnvInfo(sys.argv[2])
jel_session.signOut()

ids = ""
for node in res['nodes']:
    ids = ids + " " + str(node['nodeGroup'][:2]) + str(node['id'])
print(ids)
