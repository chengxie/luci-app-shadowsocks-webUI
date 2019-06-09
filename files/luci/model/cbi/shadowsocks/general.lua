-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Licensed to the public under the GNU General Public License v3.

local m, s, o
local shadowsocks = "shadowsocks"
local uci = luci.model.uci.cursor()
local servers = {}

uci:foreach(shadowsocks, "servers", function(s)
	if s.server and s.server_port then
		servers[#servers+1] = {name = s[".name"], alias = s.alias or "%s:%s" %{s.server, s.server_port}}
	end
end)

local function has_bin(name)
	return luci.sys.call("command -v %s >/dev/null" %{name}) == 0
end

local function has_udp_relay()
	return luci.sys.call("lsmod | grep -q TPROXY && command -v ip >/dev/null") == 0
end

local has_redir = has_bin("ss-redir")
local has_dnsforwarder = has_bin("dns-forwarder")

if not has_redir then
	return Map(shadowsocks, "%s - %s" % 
		{ translate("Shadowsocks"), translate("General Settings") }, 
		'<b style="color:red">shadowsocks-libev binary file not found.</b>')
end

m = Map(shadowsocks, "%s - %s" % { translate("Shadowsocks"), translate("General Settings") })
m.template = "shadowsocks/general"


-- [[ Global Setting ]]--
s = m:section(TypedSection, "transparent_proxy", translate("Global Settings"))
s.anonymous = true

o = s:option(Value, "startup_delay", translate("Startup Delay"))
o:value(0, translate("Not enabled"))
for _, v in ipairs({5, 10, 15, 25, 40}) do
	o:value(v, translatef("%u seconds", v))
end
o.datatype = "uinteger"
o.default = 10
o.rmempty = false


-- [[ DNS forwarder Setting ]]--
if has_dnsforwarder then
	s = m:section(TypedSection, "dns-forwarder", translate("General Setting"))
	s.anonymous   = true

	o = s:option(Flag, "enable", translate("Enable"))
	o.rmempty     = false

	o = s:option(Value, "listen_port", translate("Listen Port"))
	o.placeholder = 5353
	o.default     = 5353
	o.datatype    = "port"
	o.rmempty     = false

	o = s:option(Value, "listen_addr", translate("Listen Address"))
	o.placeholder = "0.0.0.0"
	o.default     = "0.0.0.0"
	o.datatype    = "ipaddr"
	o.rmempty     = false

	o = s:option(Value, "dns_servers", translate("DNS Server"))
	o.placeholder = "8.8.8.8:53"
	o.default     = "8.8.8.8:53"
	o.rmempty     = false
end




if has_redir then

	-- [[ Server List ]]--
	s = m:section(TypedSection, "transparent_proxy_list", 
		"%s - %s" % {
			translate("Transparent Proxy List"), translate("First server is default proxy.")
		})
	s.template = "cbi/tblsection"
	s.addremove = true
	s.anonymous = true

	o = s:option(Value, "alias", translate("Name"))
	o.rmempty = false

	o_server = s:option(ListValue, "tpl_server", translate("Server"))
	o_server:value("nil", translate("Disable"))
	for _, s in ipairs(servers) do o_server:value(s.name, s.alias) end
	o_server.default = "nil"
	o_server.rmempty = false

	o = s:option(Value, "tpl_local_port", translate("Local Port"))
	o.datatype = "port"
	o.default = 1234
	o.rmempty = false

	o = s:option(Value, "tpl_mtu", translate("Override MTU"))
	o.datatype = "range(296,9200)"
	o.default = 1492
	o.rmempty = false

	o = s:option(DummyValue, "tpl_server_status", translate("Status"))
	function o.cfgvalue(self, section)	
	    -- alternatively:
	    --local v= m:get(section, 'server')
	    local v = o_server:cfgvalue(section)
	    return "<span id=\"_redir_status_%s\"></span>" % (v or '?')
	end
    o.rawhtml = true

end





return m
