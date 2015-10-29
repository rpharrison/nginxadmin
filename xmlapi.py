import urllib2
import sys
import re
import base64
from urlparse import urlparse
import os
import getopt

def api(arg):
	theurl = 'http://127.0.0.1:2086/xml-api/' + arg

        if os.path.exists('/root/.accesshash'):
                hash = open("/root/.accesshash", 'r')
                hashstring = hash.read()
                hashstring = hashstring.replace('\n', '')
        else:
                print "Access key doesn't exist, Please Generate it in WHM"
                sys.exit(1)

	auth = 'WHM root:' + hashstring

	req = urllib2.Request(theurl)

	req.add_header("Authorization", auth)
	try:
		handle = urllib2.urlopen(req)
	except IOError, e:
		print "The Access key was found, but it looks like login's not working, Please regenerate it in WHM."
		sys.exit(1)
	thepage = handle.read()
	return thepage
