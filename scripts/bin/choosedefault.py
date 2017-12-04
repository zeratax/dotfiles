#!/usr/bin/env python
import json
import re
import subprocess
import sys

import gi
gi.require_version('Notify', '0.7')
from gi.repository import Notify

if not len(sys.argv) == 2:
    print("please give a url parameter")
else:
    url = sys.argv[1]
    Notify.init("choosedefault")

    with open('~/bin/choosedefault.json') as data_file:
        defaults = json.load(data_file)

    for rule in defaults["rules"]:
        match = re.search(rule["pattern"], url)
        if match:
            application = rule["application"]
            arguments = ""
            for argument in rule["arguments"]:
                arguments += argument.replace("{{url}}", url)

            if rule["notification"]:
                notification=Notify.Notification.new("Opening with " +application, url, "system-run")
                Notify.Notification.set_timeout(notification, 2)
                notification.show()
            subprocess.call([application, arguments])
            break
