#!/usr/bin/env python
import datetime
import os.path
import pyperclip
import requests
import sys

import gi
gi.require_version('Notify', '0.7')
from gi.repository import Notify
from gi.repository import GdkPixbuf

if len(sys.argv) == 3:
    filename=sys.argv[1]
    url=sys.argv[2]
elif len(sys.argv) == 2:
    filename=sys.argv[1]
    print("enter a url:")
    url = input()
else:
    print("enter a file you want to upload")
    filename = input()
    print("enter a url:")
    url = input()
Notify.init("upload")

if os.path.isfile(filename):
    files = {
        'file': open(filename, 'rb')
    }

    r = requests.post(url, files=files)

    notification=Notify.Notification.new("Screenshot uploaded!",r.text, "mail-send")
    if filename.lower().endswith((".jpg", ".jpeg", ".png")):
        pixbuf = GdkPixbuf.Pixbuf.new_from_file(filename)
        Notify.Notification.set_image_from_pixbuf(notification, pixbuf)
    notification.show()
    print(r.text)
    pyperclip.copy(r.text)
