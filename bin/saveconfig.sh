#!/bin/bash

ID=$(id -u)
if [ "$ID" != "0" ] ; then
	echo "This script has to be run as root. Exiting."
	exit 1
fi

hmport=$1
nrport=$2
hbrfethenable=$3
hbrfethip=$4

if [ -z $1 ] || [ -z $2 ]; then
	echo "Usage: $0 [HOMEMATIC WEBUI PORT] [NODE RED WEBUI PORT]"
	exit 1;
fi

/bin/sed -i "s#^server\.port\(\s*\)=\(.*\\)\$#server\.port\1= $hmport#" /etc/lighttpd/lighttpd.conf
/bin/sed -i "s#^var\.debmatic_webui_http_port\(\s*\)=\(.*\)\$#var\.debmatic_webui_http_port\1= $hmport#" /etc/debmatic/webui.conf
/bin/sed -i "s#^\(\s*\)uiPort:\(.*\)\$#\1uiPort: process\.env\.PORT \|\| $nrport,#" /mnt/dietpi_userdata/node-red/settings.js

if [ "$3" = "false" ]; then
	echo "HB_RF_ETH_ADDRESS=\"\"" > /etc/default/hb_rf_eth
else
	if [ -z $4 ]; then
		IP=""
		CHOICES=""
		declare -A DEVICES=()
		DEVICESRAW=`avahi-browse -p -t -r -k _raw-uart._udp | grep -e "^=" | awk '{split($0,a,";"); print a[4],a[8]}'`
		IFS=$'\n'; for line in $DEVICESRAW; do
			DEVNAME=`echo "$line" | awk '{print $1}'`
			DEVIP=`echo "$line" | awk '{print $2}'`
			if [ ! -z "$CHOICES" ]; then
				CHOICES="$CHOICES, $DEVNAME ($DEVIP)"
			else
				CHOICES="$DEVNAME ($DEVIP)"
			fi
			DEVICES["$DEVNAME"]="$DEVIP"
		done
		COUNT="${#DEVICES[@]}"
		if [ $COUNT -eq 1 ]; then
			IP=${DEVICES[${!DEVICES[@]}]}
		elif [ $COUNT -ge 2 ]; then
			DEVNAME=`echo "$RET" | awk '{print $1}'`
			if [ ! -z "$DEVNAME" ]; then
				IP=${DEVICES["$DEVNAME"]}
			fi
		fi
		echo "HB_RF_ETH_ADDRESS=\"$IP\"" > /etc/default/hb_rf_eth
	else
		echo "HB_RF_ETH_ADDRESS=\"$4\"" > /etc/default/hb_rf_eth
	fi
fi

exit 0
