#!/bin/sh
set -e -o pipefail

LOGTIME=$(date "+%Y-%m-%d")
TMP_CHINADNS_FILENAME=/tmp/log/chnroute.list.$LOGTIME
wget -4 --spider --quiet --tries=1 --timeout=15 http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest
if [ "$?" == "0" ]; then
	echo '['$LOGTIME'] updating china_chnroute.list from apnic.'
	wget -O- 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > $TMP_CHINADNS_FILENAME
	cp $TMP_CHINADNS_FILENAME /etc/shadowsocks/chnroute.list
	echo '['$LOGTIME'] reload shadowsocks rules.'
	if pidof ss-redir>/dev/null; then
		/etc/init.d/shadowsocks rules
	fi
fi

