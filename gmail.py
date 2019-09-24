#!/usr/bin/python

import sys
import re
import email

count = 0; flist = []
msg = email.message_from_file(sys.stdin)

if msg.is_multipart():
    for part in msg.walk():
        ctype = part.get_content_type()
        if re.match("application/.*excel", ctype):
            fname = part.get_filename(); flist.append(fname); count += 1
            fd = open(fname, "w")
            fd.write(part.get_payload(decode=True))
            fd.close()

print msg["From"]
print '\n'.join(flist)
