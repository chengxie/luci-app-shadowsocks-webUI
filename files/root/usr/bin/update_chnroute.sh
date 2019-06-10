#!/bin/sh
set -e -o pipefail

LOGTIME=$(date "+%Y-%m-%d")
URL=http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest
TMP_CHINADNS_FILENAME=/tmp/log/chnroute.list.$LOGTIME

/usr/bin/ss-check $URL
if [ "$?" == "0" ]; then
	echo '['$LOGTIME'] updating china_chnroute.list from apnic.'
	curl -s $URL | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > $TMP_CHINADNS_FILENAME
	if [ "$?" == "0" ]; then
		cp $TMP_CHINADNS_FILENAME /etc/shadowsocks/chnroute.list
		echo '['$LOGTIME'] reload shadowsocks rules.'
		if pidof ss-redir>/dev/null; then
			/etc/init.d/shadowsocks rules
		fi
	else
		echo '['$LOGTIME'] updating failed.'
	fi
fi

