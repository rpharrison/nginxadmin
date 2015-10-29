<?php
######################################################################################
#  Copyright (C) 2015 NginxCP.com. All rights reserved.
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

header("Content-Type: text/html\n\n");

// *** Common variables ***
$cpAppName = 'Nginx Admin';
$cpAppVersion = '5.1 Mainline';
$NGINX_VERSION= str_replace('nginx version: nginx/','',shell_exec('nginx -v 2>&1'));

$user = getenv('REMOTE_USER');
if($user != "root") { echo "You do not have the proper permissions to access Nginx Admin..."; exit; }
function ejecutar($act) {
if($act == "restart") {
$var = shell_exec("/etc/init.d/httpd restart");
if(empty($var)) { echo "<p>Nginx Restarted Successfully.</p>"; } else { echo "<p>{$var}</p>"; }
} elseif($act == "rebuild") {
$var = shell_exec("/scripts/rebuildvhosts");
if(empty($var)) { echo "<p>Command running in background.</p>"; } else { echo "<p>{$var}</p>"; }
} elseif($act == "cleanup") {
		$var = shell_exec("rm -rvf /tmp/nginx_client/*");
		if(empty($var)) { echo "<p>No output generated. The folder /tmp/nginx_client is either empty or too full to be deleted using the \"rm\" command. Verify by checking the disk usage of the /tmp partition in WHM. If /tmp is over 70-80% used, you may want to try the following commands via SSH:<br /><br /># cd /tmp/nginx_client/<br /># find . -name '*' | xargs rm</p>"; } else { echo "<p>".nl2br($var)."</p>"; }
}
}
?>
<!DOCTYPE html>
<html>
<head>
<title><?php echo $cpAppName; ?></title>
<meta name="description" content="WHM Plug-in of Nginx for cPanel servers" />
<link rel='stylesheet' type='text/css' href='/themes/x/style_optimized.css' />
<script type="text/javascript">
function okay() {
if(confirm('Are you sure of save configuration?')) {
document.getElementById('okay').submit();
}
return false;
}
function clog() {
document.getElementById('log').submit();
}
</script>
<style>
div#wrap {
margin: 0 auto;
width: 700px;
}
</style>
</head>
<body class="yui-skin-sam">
<div id="pageheader">
        <div id="breadcrumbs">
                <p>&nbsp;<a href="/scripts/command?PFILE=main">Main</a> &gt;&gt; <a href="nginx.php" class="active"><?php echo 
$cpAppName; ?></a></p>
        </div>
<div id="doctitle"><h1><?php echo $cpAppName; ?> (v<?php echo $cpAppVersion; ?>) </h1><h4><span>(Nginx Version: (<?php echo $NGINX_VERSION; ?>)</span></h4>
</div>
<div id="wrap">
<table cellpadding="0" cellspacing="0">
<tr align="center">
<td width="180"><img src="restartservices.gif" alt="Restart Nginx" /></td>
<td width="180"><img src="config.png" alt="Nginx Configuration Editor" /></td>
<td width="180"><img src="rebuild.png" alt="Rebuild VHosts" /></td>
<td width="180"><img src="log.png" alt="View Nginx Log" /></td>
<td width="180"><img src="cleanup.gif" alt="cleanup" /></td>
</tr>
<tr align="center">
<td><a href="nginx.php?op=restart">Restart Nginx</a></td>
<td><a href="nginx.php?op=edit">Configuration Editor</a></td>
<td><a href="nginx.php?op=rebuild">Rebuild Vhosts</a></td>
<td><form action="nginx.php?op=logs" method="post" id="log">View the last?<br /><input type="text" name="l" value="25" autocomplete="off" /><br /><a href="nginx.php?op=logs" onClick="clog();return false;">View Log</a></form></td>
<td><a href="nginx.php?op=cleanup">Cleanup</a></td>
</tr>
</table><br />
<?php
$op = &$_GET['op'];
switch($op) {
case "restart": echo "<p style=\"color: #009\"><b>Restarting Nginx...</b></p>"; ejecutar("restart"); echo "<p style=\"color: #009\"><b>Done...</b></p>"; break;
case "edit":
if(isset($_POST['conf'])) {
$conf = $_POST['conf'];
file_put_contents("/etc/nginx/nginx.conf", $conf);
echo "<p><b>Configuration has been updated.</b></p>";
if(isset($_POST['c'])) { ejecutar("restart"); }
}
?>
<form action="nginx.php?op=edit" method="post" id="okay"><textarea name="conf" cols="80" rows="20"><?=shell_exec("cat /etc/nginx/nginx.conf")?></textarea><br />Restart Nginx? <input type="checkbox" name="c" /><br /><br /><input type="submit" value="Update!" onClick="okay();return false;" /></form>
<?
break;
case "rebuild": ejecutar("rebuild"); break;
case "logs":
if(empty($_POST['l'])) {
$var = shell_exec("cat /var/log/nginx/error.log");
$l = null;
} else {
$l = ereg_replace("/[0-9]/","",$_POST['l']);
$var = shell_exec("tail -{$l} /var/log/nginx/error.log");
}
echo "<p style=\"color: #009\"><b>Log Viewer - Showing Last {$l} Lines</b></p>";
echo "<pre>{$var}</pre>";
break;
case "cleanup": 
echo "<p style=\"color: #009\"><b>Temporary Files Cleanup:</b></p>";
ejecutar("cleanup"); break;
default:
$run = "Down";
$var = shell_exec("ps -A");
if(strstr($var,"nginx")) { $run = "UP"; }
echo "Nginx Service Status: <font style=\"color: #0c0\"><b>{$run}</b></font>";
?>
<p style="color: #0c0">To automate /tmp cleanup add below cron <br><b>0 */1 * * * /usr/sbin/tmpwatch -am 1 /tmp/nginx_client</b><br> via crontab -e command</p>
<p style="color: #03F"><b>About Nginx Admin</b></p>
<p>Nginx Admin is a WHM interface of Nginx installer for cPanel server. This plugin will increase your server performance and decrease the server Apache Load. So you can host more websites in a cPanel server than usual. <br>Nginx is known for its high performance, stability, rich feature set, simple configuration, and low resource consumption. <br> Unlike traditional servers, Nginx doesn't rely on threads to handle requests. Instead it uses a much more scalable event-driven architecture. This architecture uses small, but more importantly, predictable amounts of memory under load. <br></p>
<p>For Support Visit <a href="http://www.nginxcp.com/forums" target='_blank'>http://www.nginxcp.com/forums</a></p>
<? } ?>

<!-- Begin PayPal Donations by http://johansteen.se/ -->
<form action="https://www.paypal.com/cgi-bin/webscr" method="post" target="_blank">
    <div class="paypal-donations">
        <input type="hidden" name="cmd" value="_donations" />
        <input type="hidden" name="business" value="9xlinux@live.com" />
        <input type="hidden" name="item_name" value="Nginx-Admin Open Source Project" />
        <input type="hidden" name="rm" value="0" />
        <input type="hidden" name="currency_code" value="USD" />
        <input type="image" src="https://www.paypal.com/en_US/i/btn/btn_donateCC_LG.gif" name="submit" alt="PayPal - The safer, easier way to pay online." />
        <img alt="" src="https://www.paypal.com/en_US/i/scr/pixel.gif" width="1" height="1" />
    </div>
</form>
<!-- End PayPal Donations -->

<p>Nginx Admin: v<?php echo $cpAppVersion; ?> <br>Nginx version: (<?php echo $NGINX_VERSION; ?>)</p><p>©2006-2015, <a href="http://www.nginxcp.com" 
target='_blank'>NginxCP.com</a></p>
</div>
</body>
</html>
