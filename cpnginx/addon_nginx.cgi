#!/bin/sh
eval 'if [ -x /usr/local/cpanel/3rdparty/bin/perl ]; then exec /usr/local/cpanel/3rdparty/bin/perl -x -- $0 ${1+"$@"}; else exec /usr/bin/perl -x $0 ${1+"$@"}; fi;'
if 0;

#!/usr/bin/perl
#WHMADDON:nginx:Nginx Admin 
######################################################################################
#  Copyright (C) 2015 nginxcp.com. All rights reserved.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
######################################################################################

use lib '/usr/local/cpanel';
use Cpanel::cPanelFunctions ();
use Cpanel::Form            ();
use Cpanel::Config          ();
use Whostmgr::HTMLInterface ();
use Whostmgr::ACLS          ();

print "Content-type: text/html\r\n\r\n";
BEGIN {
   push(@INC,"/usr/local/cpanel");
   push(@INC,"/usr/local/cpanel/whostmgr/docroot/cgi");
}

use whmlib;
require 'parseform.pl';

Whostmgr::ACLS::init_acls();
if ( !Whostmgr::ACLS::hasroot() ) {
print "You do not have the proper permissions to access Nginx Admin...\n";
exit();
}
print "<meta http-equiv=\"refresh\" content=\"0;url=nginx.php\">";
1;
