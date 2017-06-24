#!/usr/bin/env python
import datetime
import os.path
import pyperclip
import requests
import subprocess
import sys

import gi
gi.require_version('Notify', '0.7')
from gi.repository import Notify
from gi.repository import GdkPixbuf
mode=""
if len(sys.argv) > 2:
    print("Please enter a mode. Eg: screenshot.py -s")
else:
    try:
        mode=sys.argv[1]
    except:
        pass
    now = datetime.datetime.now()
    filename = now.strftime("%Y-%m-%d")+ "_scrot.png"
    if mode:
        subprocess.call(["maim", filename, mode])
    else:
        subprocess.call(["maim", filename])
    url="http://0x0.st"
    if os.path.isfile(filename):
        try:
            Notify.init("upload")
            pixbuf = GdkPixbuf.Pixbuf.new_from_file(filename)
        except:
            pass
        files = {
            'name':'.png',
            'file': open(filename, 'rb')
        }

        r = requests.post(url, files=files)
        
        try:
            notification=Notify.Notification.new("Screenshot uploaded!","Uploaded to:\n"+r.text, "mail-send")
            Notify.Notification.set_image_from_pixbuf(notification, pixbuf)
            notification.show()
        except:
            pass
        print(r.text)
        pyperclip.copy(r.text)
        os.remove(filename)
