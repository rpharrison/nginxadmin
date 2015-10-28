#!/usr/bin/env python
# Nginx Admin Installer
# Website: www.nginxcp.com
#
# Copyright (C) NGINXCP.COM.
#
import yaml
import os
from xml.dom import minidom
import sys
sys.path.append('/scripts/')
import xmlapi


def wildcard_safe(domain):
        return domain.replace('*', '_wildcard_')


def writeconfded(user, domain, docroot, passedip, alias):
	user = user
        domain = domain
        passedip = passedip
        dedipvhost = """server {
          error_log /var/log/nginx/vhost-error_log warn;
          listen %s:80;
          listen [::]:80;
	  server_name %s %s %s;
          access_log /usr/local/apache/domlogs/%s bytes_log;
          access_log /usr/local/apache/domlogs/%s combined;
          root %s;
          #location / {
          location ~*.*\.(3gp|gif|jpg|jpeg|png|ico|wmv|avi|asf|asx|mpg|mpeg|mp4|pls|mp3|mid|wav|swf|flv|html|htm|txt|js|css|exe|zip|tar|rar|gz|tgz|bz2|uha|7z|doc|docx|xls|xlsx|pdf|iso)$ {
          expires 1M;
          try_files $uri @backend;
          }
          location / {
	  error_page 405 = @backend;
          add_header X-Cache "HIT from Backend";
          proxy_pass http://%s:8081;
          include proxy.inc;
	  include microcache.inc;          
	  }
          location @backend {
          internal;
          proxy_pass http://%s:8081;
          include proxy.inc;
	  include microcache.inc;
          }
          location ~ .*\.(php|jsp|cgi|pl|py)?$ {
          proxy_pass http://%s:8081;
          include proxy.inc;
          include microcache.inc;
	  }
          location ~ /\.ht {
          deny all;
          }
        }""" % (passedip, domain, alias, passedip, wildcard_safe(domain) + "-bytes_log", wildcard_safe(domain), docroot, passedip, passedip, passedip)
        if not os.path.exists( '/etc/nginx/vhosts'):
                os.makedirs('/etc/nginx/vhosts')
        if os.path.exists( '/etc/nginx/staticvhosts/' + domain):
                pass
        else:
                domainvhost = open ('/etc/nginx/vhosts/' + domain, 'w')
                domainvhost.writelines( dedipvhost )
                domainvhost.close()

def writeconfshared(user,domain,docroot,passedip, alias):
        sharedipvhost = """server {
          error_log /var/log/nginx/vhost-error_log warn;
          listen %s:80;
          listen [::]:80;
	  server_name %s %s;
          access_log /usr/local/apache/domlogs/%s bytes_log;
          access_log /usr/local/apache/domlogs/%s combined;
          root %s;
          #location / {
          location ~*.*\.(3gp|gif|jpg|jpeg|png|ico|wmv|avi|asf|asx|mpg|mpeg|mp4|pls|mp3|mid|wav|swf|flv|html|htm|txt|js|css|exe|zip|tar|rar|gz|tgz|bz2|uha|7z|doc|docx|xls|xlsx|pdf|iso)$ {
          expires 1M;
          try_files $uri @backend;
          }
          location / {
	  error_page 405 = @backend;
          add_header X-Cache "HIT from Backend";
          proxy_pass http://%s:8081;
          include proxy.inc;
	  include microcache.inc;
          }
          location @backend {
          internal;
          proxy_pass http://%s:8081;
          include proxy.inc;
	  include microcache.inc;
          }
          location ~ .*\.(php|jsp|cgi|pl|py)?$ {
          proxy_pass http://%s:8081;
          include proxy.inc;
	  include microcache.inc;
          }
          location ~ /\.ht {
          deny all;
          }
        }""" % (passedip, domain, alias, wildcard_safe(domain) + "-bytes_log", wildcard_safe(domain), docroot, passedip, passedip, passedip)
        if not os.path.exists( '/etc/nginx/vhosts'):
                os.makedirs('/etc/nginx/vhosts')
        if os.path.exists( '/etc/nginx/staticvhosts/' + domain):
                pass
        else:
                domainvhost = open ('/etc/nginx/vhosts/' + domain, 'w')
                domainvhost.writelines( sharedipvhost )
                domainvhost.close()

#def redirectfunc():



def getmainip():
        ipDOC = xmlapi.api("listips")
        parsedipDOC = minidom.parseString(ipDOC)
        iptaglist = parsedipDOC.getElementsByTagName('ip')
        serverip = iptaglist[0].childNodes[0].toxml()
        return serverip

def getipliststring():
        ipDOC = xmlapi.api("listips")
        parsedipDOC = minidom.parseString(ipDOC)
        iptaglist = parsedipDOC.getElementsByTagName('ip')
        iplist =[]

        q = 0
        while q < len(iptaglist):
                iplist.append(str(iptaglist[q].childNodes[0].toxml()))
                q = q + 1
        ipliststring = ' '.join(iplist)

        return ipliststring



def getvars(ydomain):
        DOC = xmlapi.api("domainuserdata?domain=" + ydomain)
        parsedDOC = minidom.parseString(DOC)
        docroottaglist = parsedDOC.getElementsByTagName('documentroot')
        yiptaglist = parsedDOC.getElementsByTagName('ip')
        aliastaglist=[]
        aliastaglist = parsedDOC.getElementsByTagName('serveralias')
        aliaslist =[]
        a = 0
        while a < len(aliastaglist):
                newalias = str(aliastaglist[a].childNodes[0].toxml())
                if not newalias.startswith("www.*."):
                        aliaslist.append(newalias)
                a = a + 1
        alias = ''.join(aliaslist)
        docroot=""
        yip=""
        try:
                docroot = docroottaglist[0].childNodes[0].toxml()
                yip = yiptaglist[0].childNodes[0].toxml()

        except IndexError:
                errf=open('/root/failedcreation.txt', 'a')
                import time
                from time import strftime
                t=strftime("%Y-%m-%d %H:%M:%S")
                errortxt="%s Failed to create vhost for %s\n" % (t, ydomain)
                errf.write(errortxt)
                errf.close()

        return docroot, yip, alias

if __name__ == '__main__':
        DOC = xmlapi.api("listaccts")
        parsedDOC = minidom.parseString(DOC)
        usertaglist = parsedDOC.getElementsByTagName('user')
        userlist = []
        numusers = 0
        while numusers < len(usertaglist):
                userlist.append(str(usertaglist[numusers].childNodes[0].toxml()))
                numusers = numusers + 1
        for i in userlist:
                f = open('/var/cpanel/userdata/' + i + '/main')
                ydata = yaml.load(f)
                f.close()
                sublist = ydata['sub_domains']
                addondict = ydata['addon_domains']
                parkedlist = ydata['parked_domains']
                mainlist = ydata['main_domain']
                serverip = getmainip()
                if len(sublist) != 0:
                        slcont = 0
                        while slcont < len(sublist):
                                domain = sublist[slcont]
                                docroot, yip, alias = getvars(sublist[slcont])
                                if docroot == "":
                                        slcont = slcont + 1
                                else:
                                        if yip == serverip:
                                                writeconfshared(i, domain, docroot, yip, alias)
                                        else:
                                                writeconfded(i, domain, docroot, yip, alias)
                                        slcont = slcont + 1


                DOC = xmlapi.api("accountsummary?user=" + i)
                parsedDOC = minidom.parseString(DOC)
                domaintaglist = parsedDOC.getElementsByTagName('domain')
                domain = domaintaglist[0].childNodes[0].toxml()
                docroot, yip, alias = getvars(domain)
                if yip == serverip:
                       writeconfshared(i, domain, docroot, yip, alias)
                else:
                       writeconfded(i, domain, docroot, yip, alias)

