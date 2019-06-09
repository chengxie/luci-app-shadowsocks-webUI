-- Copyright (C) 2017 yushi studio <ywb94@qq.com>
-- Licensed to the public under the GNU General Public License v3.

local IPK_Version="1.2.1"
local m, s, o
local gfw_count=0
local ip_count=0
local gfwmode=0

if nixio.fs.access("/etc/dnsmasq.d/gfwlist.conf") then
	gfwmode=1	
end

local shadowsocks = "shadowsocks"
-- html constants
font_blue = [[<font color="blue">]]
font_off = [[</font>]]
bold_on  = [[<strong>]]
bold_off = [[</strong>]]

local fs = require "nixio.fs"
local sys = require "luci.sys"

if gfwmode == 1 then 
 	gfw_count = tonumber(sys.exec("cat /etc/dnsmasq.d/gfwlist.conf | wc -l"))
end
 
if nixio.fs.access("/etc/shadowsocks/chnroute.list") then 
 	ip_count = sys.exec("cat /etc/shadowsocks/chnroute.list | wc -l")
end


m = SimpleForm("Version", "%s - %s" %{translate("ShadowSocks"), translate("Tools")})
m.reset = false
m.submit = false


s=m:field(DummyValue,"google",translate("Google Connectivity"))
s.value = translate("No Check") 
s.template = "shadowsocks/check"

s=m:field(DummyValue,"baidu",translate("Baidu Connectivity")) 
s.value = translate("No Check") 
s.template = "shadowsocks/check"

if gfwmode==1 then 
	s=m:field(DummyValue,"gfw_data",translate("GFW List Data")) 
	s.rawhtml  = true
	s.template = "shadowsocks/refresh"
	s.value =tostring(math.ceil(gfw_count)) .. " " .. translate("Records")
end

s=m:field(DummyValue,"ip_data",translate("China IP Data")) 
s.rawhtml  = true
s.template = "shadowsocks/refresh"
s.value =ip_count .. " " .. translate("Records")

s=m:field(DummyValue,"check_port",translate("Check Server Port"))
s.template = "shadowsocks/checkport"
s.value =translate("No Check")

s=m:field(DummyValue,"version",translate("IPK Version")) 
s.rawhtml  = true
s.value =IPK_Version

s=m:field(DummyValue,"project",translate("Project")) 
s.rawhtml  = true
s.value =bold_on .. [[<a href="]] .. "https://github.com/chengxie/luci-app-shadowsocks-webUI" .. [[" >]]
	.. "https://github.com/chengxie/luci-app-shadowsocks-webUI" .. [[</a>]] .. bold_off
	
return m
