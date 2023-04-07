#!/bin/bash

ID=$(id -u)
if [ "$ID" != "0" ] ; then
	echo "This script has to be run as root. Exiting."
	exit 1
fi

hmport=$1
nrport=$2
if [ -z $1 ] || [ -z $2 ]; then
	echo "Usage: $0 [HOMEMATIC WEBUI PORT] [NODE RED WEBUI PORT]"
	exit 1;
fi

/bin/sed -i "s#^server\.port\(\s*\)=\(.*\\)\$#server\.port\1= $hmport#" /etc/lighttpd/lighttpd.conf
/bin/sed -i "s#^var\.debmatic_webui_http_port\(\s*\)=\(.*\)\$#var\.debmatic_webui_http_port\1= $hmport#" /etc/debmatic/webui.conf
/bin/sed -i "s#^\(\s*\)uiPort:\(.*\)\$#\1uiPort: process\.env\.PORT \|\| $nrport,#" /mnt/dietpi_userdata/node-red/settings.js
