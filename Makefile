#
# Copyright (C) 2019 openwrt-ss
# Copyright (C) 2019 chengxie <chengxie@me.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-shadowsocks-webUI
PKG_VERSION:=1.2
PKG_RELEASE:=1

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=chengxie <chengxie@me.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-shadowsocks-webUI
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for shadowsocks-libev
	URL:=https://github.com/chengxie/openwrt-ss
	PKGARCH:=all
	DEPENDS:=+shadowsocks-libev-ss-redir +ipset +ip +iptables +iptables-mod-tproxy +coreutils +coreutils-base64 +haveged +curl +wget
endef

define Package/luci-app-shadowsocks-webUI/description
	LuCI Support for shadowsocks-libev.
endef

define Package/luci-app-shadowsocks-webUI/prerm/Default
#!/bin/sh
# check if we are on real system
if [ -z "$${IPKG_INSTROOT}" ]; then
    echo "Removing rc.d symlink for $(2)"
     /etc/init.d/$(2) disable
     /etc/init.d/$(2) stop
    echo "Removing firewall rule for $(2)"
	  uci -q batch <<-EOF >/dev/null
		delete firewall.$(2)
		commit firewall
EOF
fi
exit 0
endef
Package/luci-app-shadowsocks-webUI/prerm = $(call Package/luci-app-shadowsocks-webUI/prerm/Default, $(1), shadowsocks)

define Package/luci-app-shadowsocks-webUI/postinst/Default
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	uci -q batch <<-EOF >/dev/null
		delete firewall.$(2)
		set firewall.$(2)=include
		set firewall.$(2).type=script
		set firewall.$(2).path=/var/etc/$(2)/firewall.include
		set firewall.$(2).reload=0
		commit firewall
EOF
fi
if [ -z "$${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/luci-$(2) ) && rm -f /etc/uci-defaults/luci-$(2)
	chmod 755 /etc/init.d/$(2) >/dev/null 2>&1
	/etc/init.d/$(2) enable >/dev/null 2>&1
fi
exit 0
endef
Package/luci-app-shadowsocks-webUI/postinst = $(call Package/luci-app-shadowsocks-webUI/postinst/Default, $(1), shadowsocks)


define Package/luci-app-shadowsocks-webUI/install/Default
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/root/usr/bin/* $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/luci/controller/$(2).lua $(1)/usr/lib/lua/luci/controller/$(2).lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./files/luci/i18n/$(2).*.lmo $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/$(2)
	$(INSTALL_DATA) ./files/luci/model/cbi/$(2)/*.lua $(1)/usr/lib/lua/luci/model/cbi/$(2)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/$(2)
	$(INSTALL_DATA) ./files/luci/view/$(2)/*.htm $(1)/usr/lib/lua/luci/view/$(2)/
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) ./files/root/etc/dnsmasq.conf $(1)/etc/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/root/etc/config/* $(1)/etc/config/
	$(INSTALL_DIR) $(1)/etc/crontabs
	$(INSTALL_DATA) ./files/root/etc/crontabs/* $(1)/etc/crontabs/
	$(INSTALL_DIR) $(1)/etc/dnsmasq.d
	$(INSTALL_DATA) ./files/root/etc/dnsmasq.d/* $(1)/etc/dnsmasq.d/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/root/etc/init.d/* $(1)/etc/init.d/
	$(INSTALL_DIR) $(1)/etc/$(2)
	$(INSTALL_DATA) ./files/root/etc/$(2)/* $(1)/etc/$(2)/
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/root/etc/uci-defaults/* $(1)/etc/uci-defaults/
endef
Package/luci-app-shadowsocks-webUI/install = $(call Package/luci-app-shadowsocks-webUI/install/Default, $(1), shadowsocks)


define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/files/luci/i18n/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

$(eval $(call BuildPackage, luci-app-shadowsocks-webUI))

