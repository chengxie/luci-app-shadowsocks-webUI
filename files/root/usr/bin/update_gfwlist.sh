#!/bin/sh
set -e -o pipefail

LOGTIME=$(date "+%Y-%m-%d")
TMP_DNSMASQREDIR_FILENAME=/tmp/log/gfwlist.conf.$LOGTIME
wget -4 --spider --quiet --tries=1 --timeout=15 https://github.com/gfwlist/gfwlist/raw/master/gfwlist.txt
if [ "$?" == "0" ]; then
	echo '['$LOGTIME'] updating gfwlist.conf. from gfwlist.'
	#if [[ "$(ipset -n -L | grep gfwlist)" != "gfwlist" ]]; then	
		/usr/bin/gfwlist2dnsmasq.sh -o $TMP_DNSMASQREDIR_FILENAME
	#else
		#/etc/shadowsocks/gfwlist2dnsmasq.sh -s gfwlist -o $TMP_DNSMASQREDIR_FILENAME
	#fi
	cp $TMP_DNSMASQREDIR_FILENAME /etc/dnsmasq.d/gfwlist.conf
	echo '['$LOGTIME'] restarting dnsmasq.'
	/etc/init.d/dnsmasq restart
fi

