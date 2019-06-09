-- Copyright (C) 2016-2017 Jian Chang <aa65535@live.com>
-- Licensed to the public under the GNU General Public License v3.

local m, s, o
local shadowsocks = "shadowsocks"
local uci = luci.model.uci.cursor()
local nwm = require("luci.model.network").init()
local lan_ifaces = {}
local proxy_list = {}
uci:foreach(shadowsocks, "transparent_proxy_list", function(s)
	proxy_list[#proxy_list+1] = { name = s.tpl_server, alias = s.alias }
end)

for _, net in ipairs(nwm:get_networks()) do
	if net:name() ~= "loopback" and string.find(net:name(), "wan") ~= 1 then
		net = nwm:get_network(net:name())
		local device = net and net:get_interface()
		if device then
			lan_ifaces[device:name()] = device:get_i18n()
		end
	end
end

m = Map(shadowsocks, "%s - %s" %{translate("Shadowsocks"), translate("Access Control")})

-- [[ Zone WAN ]]--
s = m:section(TypedSection, "access_control", translate("Zone WAN"))
s.anonymous = true

o = s:option(Value, "wan_bp_list", translate("Bypassed IP List"))
o:value("/dev/null", translate("NULL - As Global Proxy"))
o.datatype = "or(file, '/dev/null')"
o.default = "/dev/null"
o.rmempty = false

o = s:option(DynamicList, "wan_bp_ips", translate("Bypassed IP"))
o.datatype = "ip4addr"
o.rmempty = true

o = s:option(Value, "wan_fw_list", translate("Forwarded IP List"))
o.datatype = "or(file, '/dev/null')"
o.rmempty = true

o = s:option(DynamicList, "wan_fw_ips", translate("Forwarded IP"))
o.datatype = "ip4addr"
o.rmempty = true

-- [[ Zone LAN ]]--
s = m:section(TypedSection, "access_control", translate("Zone LAN"))
s.anonymous = true

o = s:option(MultiValue, "lan_ifaces", translate("Interface"))
function o.cfgvalue(...)
	local v = MultiValue.cfgvalue(...)
	if v then
		return v
	else
		local names = {}
		for name, _ in pairs(lan_ifaces) do
			names[#names+1] = name
		end
		return table.concat(names, " ")
	end
end
for name, i18n in pairs(lan_ifaces) do
	o:value(name, i18n)
end

o = s:option(ListValue, "lan_target", translate("Proxy Type"))
o:value("SS_SPEC_WAN_AC", translate("Normal"))
o:value("RETURN", translate("Direct"))
o:value("SS_SPEC_WAN_FW", translate("Global"))
o.rmempty = false

o = s:option(ListValue, "self_proxy", translate("Self Proxy"))
o:value("1", translate("Normal"))
o:value("0", translate("Direct"))
o:value("2", translate("Global"))
o.rmempty = false

o = s:option(Value, "ipt_ext", translate("Extra arguments"),
	translate("Passes additional arguments to iptables. Use with care!"))
o:value("", translate("None"))
o:value("--dport 22:1023", translatef("Proxy port numbers %s only", "22~1023"))
o:value("-m multiport --dports 53,80,443", translatef("Proxy port numbers %s only", "53,80,443"))

-- [[ LAN Hosts ]]--
s = m:section(TypedSection, "lan_hosts", translate("LAN Hosts"))
s.template = "cbi/tblsection"
s.addremove = true
s.anonymous = true

o = s:option(Value, "macaddr", translate("MAC-Address"))
luci.sys.net.mac_hints(function(mac, name)
	o:value(mac, "%s (%s)" %{mac, name})
end)
o.datatype = "macaddr"
o.rmempty = false

o = s:option(ListValue, "type", translate("Proxy Type"))
o:value("b", translate("Direct"))
o:value("g", translate("Global"))
o:value("n", translate("Normal"))
o.rmempty = false

o = s:option(ListValue, "server", translate("Proxy Server"))
o:value("nil", translate("Disable"))
for _, s in ipairs(proxy_list) do o:value(s.name, s.alias) end
o.rmempty = false

return m
