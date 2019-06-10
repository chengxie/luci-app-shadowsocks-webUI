#!/bin/sh
set -e -o pipefail
LOGTIME=$(date "+%Y-%m-%d")
URL=https://github.com/gfwlist/gfwlist/raw/master/gfwlist.txt
TMP_DNSMASQREDIR_FILENAME=/tmp/log/gfwlist.conf.$LOGTIME

/usr/bin/ss-check $URL
if [ "$?" == "0" ]; then
	echo '['$LOGTIME'] updating gfwlist.conf from gfwlist.'
	/usr/bin/gfwlist2dnsmasq.sh -o $TMP_DNSMASQREDIR_FILENAME
	if [ "$?" == "0" ]; then
		cp $TMP_DNSMASQREDIR_FILENAME /etc/dnsmasq.d/gfwlist.conf
		echo '['$LOGTIME'] restarting dnsmasq.'
		/etc/init.d/dnsmasq restart
	else
		echo '['$LOGTIME'] updating failed.'
	fi
fi
