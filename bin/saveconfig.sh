#!/bin/bash

ID=$(id -u)
if [ "$ID" != "0" ] ; then
	echo "This script has to be run as root. Exiting."
	exit 1
fi

hmport=$1
nrport=$2
ccujport=$3
ccujmqtt=$4
ccujmqtttls=$5
hbrfethenable=$6
hbrfethip=$7

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] || [ -z $4 ] || [ -z $5 ]; then
	echo "Usage: $0 [HOMEMATIC WEBUI PORT] [NODE RED WEBUI PORT] [CCUJACK WEBUI PORT] [CCUJACK MQTT PORT] [CCUJACK MQTT TLS PORT] [ENABLE HBRFETH] [IP ADRESS HBRFETH"
	exit 1;
fi

# Homematic/Debmatic
/bin/sed -i "s#^server\.port\(\s*\)=\(.*\\)\$#server\.port\1= $hmport#" /etc/lighttpd/lighttpd.conf
/bin/sed -i "s#^var\.debmatic_webui_http_port\(\s*\)=\(.*\)\$#var\.debmatic_webui_http_port\1= $hmport#" /etc/debmatic/webui.conf
/bin/sed -i "s#^\(\s*\)uiPort:\(.*\)\$#\1uiPort: process\.env\.PORT \|\| $nrport,#" /mnt/dietpi_userdata/node-red/settings.js

# Hbrf
if [ "$hbrfethenable" = "false" ]; then
	echo "HB_RF_ETH_ADDRESS=\"\"" > /etc/default/hb_rf_eth
else
	if [ -z $hbrfethip ]; then
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
		echo "HB_RF_ETH_ADDRESS=\"$hbrfethip\"" > /etc/default/hb_rf_eth
	fi
fi

# CCU-Jack
systemctl stop ccu-jack
brokerhost=`jq -r ".Mqtt.Brokerhost" $LBSCONFIG/general.json`
brokeruser=`jq -r ".Mqtt.Brokeruser" $LBSCONFIG/general.json`
brokerpass=`jq -r ".Mqtt.Brokerpass" $LBSCONFIG/general.json`
brokerport=`jq -r ".Mqtt.Brokerport" $LBSCONFIG/general.json`
hostname=`hostname`
jq ".HTTP.Port = $ccujport" /etc/config/addons/ccu-jack.cfg > /tmp/ccu-jack.cfg 
mv /tmp/ccu-jack.cfg /etc/config/addons/ccu-jack.cfg
jq ".MQTT.Port = $ccujmqtt" /etc/config/addons/ccu-jack.cfg > /tmp/ccu-jack.cfg 
mv /tmp/ccu-jack.cfg /etc/config/addons/ccu-jack.cfg
jq ".MQTT.PortTLS = $ccujmqtttls" /etc/config/addons/ccu-jack.cfg > /tmp/ccu-jack.cfg 
mv /tmp/ccu-jack.cfg /etc/config/addons/ccu-jack.cfg
jq ".MQTT.Bridge.Address = \"$brokerhost\"" /etc/config/addons/ccu-jack.cfg > /tmp/ccu-jack.cfg 
mv /tmp/ccu-jack.cfg /etc/config/addons/ccu-jack.cfg
jq ".MQTT.Bridge.Port = $brokerport" /etc/config/addons/ccu-jack.cfg > /tmp/ccu-jack.cfg 
mv /tmp/ccu-jack.cfg /etc/config/addons/ccu-jack.cfg
jq ".MQTT.Bridge.Username = \"$brokeruser\"" /etc/config/addons/ccu-jack.cfg > /tmp/ccu-jack.cfg 
mv /tmp/ccu-jack.cfg /etc/config/addons/ccu-jack.cfg
jq ".MQTT.Bridge.Password = \"$brokerpass\"" /etc/config/addons/ccu-jack.cfg > /tmp/ccu-jack.cfg 
mv /tmp/ccu-jack.cfg /etc/config/addons/ccu-jack.cfg
jq ".MQTT.Bridge.ClientID = \"$hostname\"" /etc/config/addons/ccu-jack.cfg > /tmp/ccu-jack.cfg 
mv /tmp/ccu-jack.cfg /etc/config/addons/ccu-jack.cfg
systemctl start ccu-jack

exit 0
