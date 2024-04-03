#!/bin/bash

# To use important variables from command line use the following code:
COMMAND=$0    # Zero argument is shell command
PTEMPDIR=$1   # First argument is temp folder during install
PSHNAME=$2    # Second argument is Plugin-Name for scipts etc.
PDIR=$3       # Third argument is Plugin installation folder
PVERSION=$4   # Forth argument is Plugin version
#LBHOMEDIR=$5 # Comes from /etc/environment now. Fifth argument is
              # Base folder of LoxBerry
PTEMPPATH=$6  # Sixth argument is full temp path during install (see also $1)

# Combine them with /etc/environment
PCGI=$LBPCGI/$PDIR
PHTML=$LBPHTML/$PDIR
PTEMPL=$LBPTEMPL/$PDIR
PDATA=$LBPDATA/$PDIR
PLOG=$LBPLOG/$PDIR # Note! This is stored on a Ramdisk now!
PCONFIG=$LBPCONFIG/$PDIR
PSBIN=$LBPSBIN/$PDIR
PBIN=$LBPBIN/$PDIR

echo "<INFO> Installation as root user started."

echo "<INFO> Adding Debmatic Repository..."
curl -sL https://www.debmatic.de/debmatic/public.key | gpg --dearmor | tee /usr/share/keyrings/debmatic.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/debmatic.gpg] https://www.debmatic.de/debmatic stable main" | tee /etc/apt/sources.list.d/debmatic.list

echo "<INFO> Updating apt Databases..."
export APT_LISTCHANGES_FRONTEND=none
export DEBIAN_FRONTEND=noninteractive
export RUNLEVEL=1
/usr/bin/dpkg --configure -a --force-confdef
apt-get -y --allow-unauthenticated --fix-broken --reinstall --allow-downgrades --allow-remove-essential --allow-change-held-packages install
apt-get -y --allow-unauthenticated --fix-broken --reinstall --allow-downgrades --allow-remove-essential --allow-change-held-packages --purge autoremove
apt-get -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages --allow-releaseinfo-change update

echo "<INFO> Installing Kernel Modules for Debmatic..."
#apt-get --no-install-recommends -y --allow-unauthenticated --fix-broken --reinstall --allow-downgrades --allow-remove-essential --allow-change-held-packages install `dpkg --get-selections | grep 'linux-image-' | grep '\sinstall' | sed -e 's/linux-image-\([a-z0-9-]\+\).*/linux-headers-\1/'`
apt-get --no-install-recommends -y --allow-unauthenticated --fix-broken --reinstall --allow-downgrades --allow-remove-essential --allow-change-held-packages install linux-headers-$(uname -r)

apt-get --no-install-recommends -y --allow-unauthenticated --fix-broken --reinstall --allow-downgrades --allow-remove-essential --allow-change-held-packages install pivccu-modules-dkms hb-rf-eth

# Check on which hardware we are running
echo "<INFO> Reading Hardware information..."
if [ -e /boot/dietpi/.hw_model ]; then
	. /boot/dietpi/.hw_model
else
	echo "<FAIL> Cannot read your hardware details from /boot/dietpi/.hw_model"
	exit 2
fi

# We are on a Raspberry
if [ $G_HW_MODEL -lt 10 ]; then

	echo "<INFO> We are on a Raspberry. Add special options and packages for Raspberry..."

	echo "<INFO> Installing PIVCCU Modules..."
	apt-get --no-install-recommends -y --allow-unauthenticated --fix-broken --reinstall --allow-downgrades --allow-remove-essential --allow-change-held-packages install pivccu-modules-raspberrypi

	#
	#
	# Should this be pivccu-devicetree-raspberrypi ????
	#
	#

	echo "<INFO> Reconfigure Bluetooth"
	if ! cat /boot/config.txt | grep -qe "^dtoverlay=pi3-disable-bt" && ! cat /boot/config.txt | grep -qe "^dtoverlay=pi3-miniuart-bt"; then
		echo "<INFO> Adding dtoverlay=pi3-miniuart-bt to /boot/config.txt"
		echo "" >> /boot/config.txt
		echo "dtoverlay=pi3-miniuart-bt" >> /boot/config.txt
	else
		echo "<INFO> dtoverlay=pi3-miniuart-bt or dtoverlay=pi3-disable-bt already set in /boot/config.txt"
	fi
	if ! cat /boot/config.txt | grep -qe "^enable_uart="; then
		echo "<INFO> Adding enable_uart=1 to /boot/config.txt"
		echo "" >> /boot/config.txt
		echo "enable_uart=1" >> /boot/config.txt
	else
		echo "<INFO> Replacing enable_uart with enable_uart=1 in /boot/config.txt"
		/bin/sed -i 's#enable_uart=\(.*\)#enable_uart=1#g' /boot/config.txt
		/bin/sed -i 's#enable_uart="\(.*\)"#enable_uart=1#g' /boot/config.txt
	fi
	if ! cat /boot/config.txt | grep -qe "^force_turbo="; then
		echo "<INFO> Adding force_turbo=1 to /boot/config.txt"
		echo "" >> /boot/config.txt
		echo "force_turbo=1" >> /boot/config.txt
	else
		echo "<INFO> Replacing force_turbo= with force_turbo=1 in /boot/config.txt"
		/bin/sed -i 's#force_turbo=\(.*\)#force_turbo=1#g' /boot/config.txt
		/bin/sed -i 's#force_turbo="\(.*\)"#force_turbo=1#g' /boot/config.txt
	fi
	if ! cat /boot/config.txt | grep -qe "^core_freq="; then
		echo "<INFO> Adding core_freq=250 to /boot/config.txt"
		echo "" >> /boot/config.txt
		echo "core_freq=250" >> /boot/config.txt
	else
		echo "<INFO> Replacing core_freq= with core_freq=250 in /boot/config.txt"
		/bin/sed -i 's#core_freq=\(.*\)#core_freq=250#g' /boot/config.txt
		/bin/sed -i 's#core_freq="\(.*\)"#core_freq=250#g' /boot/config.txt
	fi

	echo "<INFO> Configuring serial interface..."
	if cat /boot/config.txt | grep -qe "^init_uart_clock="; then
		echo "<INFO> Removing init_uart_clock= from /boot/config.txt"
		/bin/sed -i 's|^init_uart_clock=|#init_uart_clock=|g' /boot/config.txt
	else
		echo "<INFO> init_uart_clock= not found in /boot/config.txt. That's OK."
	fi

	echo "<INFO> Configuring I2C interface..."
	if cat /boot/config.txt | grep -qe "^#dtparam=i2c_arm="; then
		echo "<INFO> Adding dtparam=i2c_arm=on to /boot/config.txt"
		/bin/sed -i 's|^#dtparam=i2c_arm=\(.*\)|dtparam=i2c_arm=on|g' /boot/config.txt
	elif cat /boot/config.txt | grep -qe "^dtparam=i2c_arm=off"; then
		echo "<INFO> Adding dtparam=i2c_arm=on to /boot/config.txt"
		/bin/sed -i 's|^dtparam=i2c_arm=\(.*\)|dtparam=i2c_arm=on|g' /boot/config.txt
	elif cat /boot/config.txt | grep -qe "^dtparam=i2c_arm="; then
		echo "<INFO> Adding dtparam=i2c_arm=on to /boot/config.txt"
		/bin/sed -i 's|^dtparam=i2c_arm=\(.*\)|dtparam=i2c_arm=on|g' /boot/config.txt
	elif ! cat /boot/config.txt | grep -qe "dtparam=i2c_arm"; then
		echo "<INFO> Adding dtparam=i2c_arm=on to /boot/config.txt"
		echo "" >> /boot/config.txt
		echo "dtparam=i2c_arm=on" >> /boot/config.txt
	else
		echo "<INFO> dtparam=i2c_arm=on already set in /boot/config.txt"
	fi

	echo "<INFO> Disabling serial console in /boot/cmdline.txt"
	/bin/sed -i /boot/cmdline.txt -e "s/console=ttyAMA0,[0-9]\+ //"
	/bin/sed -i /boot/cmdline.txt -e "s/console=serial0,[0-9]\+ //"

# We are on another Armbian System (no Raspberry)
else

	echo "<INFO> We are on a Non-Raspberry. Add special options and packages..."
	apt-get --no-install-recommends -y --allow-unauthenticated --fix-broken --reinstall --allow-downgrades --allow-remove-essential --allow-change-held-packages install pivccu-devicetree-armbian

fi

echo "<INFO> Installing Lighttpd..."
if [ -x "/usr/sbin/lighty-disable-mod" ]; then
	/usr/sbin/lighty-disable-mod debmatic
fi
apt-get --no-install-recommends -y --allow-unauthenticated --fix-broken --reinstall --allow-downgrades --allow-remove-essential --allow-change-held-packages install lighttpd
systemctl stop lighttpd

echo "<INFO> Changing Lighttpd Port to 8081"
/bin/sed -i 's#^server\.port\(\s*\)=\(.*\)$#server\.port\1= 8081#' /etc/lighttpd/lighttpd.conf

echo "<INFO> Installing Debmatic..."
apt-get --no-install-recommends -y --allow-unauthenticated --fix-broken --reinstall --allow-downgrades --allow-remove-essential --allow-change-held-packages install debmatic

echo "<INFO> Changing Homematic WebUI Port to 8081 (same as Lighttpd)"
/bin/sed -i 's#^var\.debmatic_webui_http_port\(\s*\)=\(.*\)$#var\.debmatic_webui_http_port\1= 8081#' /etc/debmatic/webui.conf

echo "<INFO> Disabling Debmatic SSDPD Service (LoxBerry has it's own service)..."
systemctl stop debmatic-ssdpd
systemctl disable debmatic-ssdpd

echo "<INFO> Installing AddOns..."
apt-get --no-install-recommends -y --allow-unauthenticated --fix-broken --reinstall --allow-downgrades --allow-remove-essential --allow-change-held-packages install cuxd xml-api
systemctl stop debmatic
systemctl stop lighttpd

echo "<INFO> Installing CCU-Jack..."
UPGRADE=0
if [ -e /etc/config/addons/ccu-jack.cfg ]; then # Upgrade!
	UPGRADE=1
fi

# Extracting sources - ADD GIT DOWNLOAD HERE AS SOON AS IT IS AVAILABLE
systemctl stop ccu-jack
tar -C / -x -v -z -f $PDATA/ccu-jack-debmatic-rp2+3.tar.gz

# Check arch
. /boot/dietpi/.hw_model
mv /usr/local/addons/ccu-jack/ccu-jack /usr/local/addons/ccu-jack/ccu-jack.orig
if [ $G_HW_ARCH -eq 1 ]; then # Pi0 und Pi1 or armv6l
	echo "<INFO> Installing CCU-Jack for armv6l."
	cp $PDATA/ccu-jack.pi1 /usr/local/addons/ccu-jack/ccu-jack
elif [ $G_HW_ARCH -eq 2 ]; then # Pi2+3 or armv7l
	echo "<INFO> Installing CCU-Jack for armv7l."
	cp $PDATA/ccu-jack.rp2 /usr/local/addons/ccu-jack/ccu-jack
elif [ $G_HW_ARCH -eq 3 ]; then # Pi4+5 or arm64
	echo "<INFO> Installing CCU-Jack for arm64."
	cp $PDATA/ccu-jack.rp4 /usr/local/addons/ccu-jack/ccu-jack
elif [ $G_HW_ARCH -eq 10 ]; then # x64
	echo "<INFO> Installing CCU-Jack for x64."
	cp $PDATA/ccu-jack.x64 /usr/local/addons/ccu-jack/ccu-jack
else
	echo "<ERROR> Your Architecture seems not to be supported by CCU-Jack. CCU Jack will not work."
fi
chmod +x /usr/local/addons/ccu-jack/ccu-jack

# CHange default config
brokerhost=`jq -r ".Mqtt.Brokerhost" $LBSCONFIG/general.json`
brokeruser=`jq -r ".Mqtt.Brokeruser" $LBSCONFIG/general.json`
brokerpass=`jq -r ".Mqtt.Brokerpass" $LBSCONFIG/general.json`
brokerport=`jq -r ".Mqtt.Brokerport" $LBSCONFIG/general.json`
hostname=`hostname`
rm /tmp/ccu-jack.cfg
jq ".MQTT.Bridge.Enable = true" /etc/config/addons/ccu-jack.cfg > /tmp/ccu-jack.cfg 
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
if [ UPGRADE -lt 1 ]; then
	jq '.Users.loxberry = {
		"Identifier": "loxberry",
		"Active": true,
		"Description": "",
		"Password": "",
		"EncryptedPassword": "$2a$04$vJdusYLi51FPdl07Q4ASLOAA0Y5CeH/psb92NU.aaWNKBJ5HgbzcO",
		"Permissions": {
			"all": {
				"Identifier": "all",
				"Description": "All permissions",
				"Endpoint": 3,
				"Kind": 7,
				"PVFilter": ""
			}
		}
	}' /etc/config/addons/ccu-jack.cfg > /tmp/ccu-jack.cfg
	mv /tmp/ccu-jack.cfg /etc/config/addons/ccu-jack.cfg
	jq '.MQTT.Bridge.Incoming = [
	{
		"Pattern": "+/set/#",
		"LocalPrefix": "",
		"RemotePrefix": "ccujack/",
		"QoS": 0
	},
	{
		"Pattern": "+/get/#",
		"LocalPrefix": "",
		"RemotePrefix": "ccujack/",
		"QoS": 0
	}
	]' /etc/config/addons/ccu-jack.cfg > /tmp/ccu-jack.cfg
	mv /tmp/ccu-jack.cfg /etc/config/addons/ccu-jack.cfg
	jq '.MQTT.Bridge.Outgoing = [
	{
		"Pattern": "+/status/#",
		"LocalPrefix": "",
		"RemotePrefix": "ccujack/",
		"QoS": 0
	}
	]' /etc/config/addons/ccu-jack.cfg > /tmp/ccu-jack.cfg
	mv /tmp/ccu-jack.cfg /etc/config/addons/ccu-jack.cfg
fi
systemctl daemon-reload
systemctl enable ccu-jack.service

exit 0
