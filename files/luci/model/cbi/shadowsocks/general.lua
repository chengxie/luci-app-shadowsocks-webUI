-- Copyright (C) 2019 chengxie <chengxie@me.com>
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
s = m:section(TypedSection, "general", translate("Global Settings"))
s.anonymous = true

o = s:option(Value, "startup_delay", translate("Startup Delay"))
o:value(0, translate("Not enabled"))
for _, v in ipairs({5, 10, 15, 25, 40}) do
	o:value(v, translatef("%u seconds", v))
end
o.datatype = "uinteger"
o.default = 10
o.rmempty = false

-- [[ dns-forwarder ]] --
s = m:section(TypedSection, "dns-forwarder", translate("DNS Forwarder"))
s.anonymous   = true

o = s:option(Flag, "enable", translate("Enable"))
o.rmempty     = false

o = s:option(Value, "dns_servers", translate("DNS Server"))
o.placeholder = "8.8.8.8:53"
o.default     = "8.8.8.8:53"
o.rmempty     = false


if has_redir then

	-- [[ Server List ]]--
	s = m:section(TypedSection, "transparent_proxy_list", 
			translate("Proxy List"), translate("The first record is the default proxy"))
	s.template = "cbi/tblsection"
	s.addremove = true
	s.anonymous = true

	o = s:option(Value, "alias", translate("Name"))
	o.rmempty = false

	o = s:option(ListValue, "tpl_server", translate("Server"))
	o:value("nil", translate("Disable"))
	for _, v in ipairs(servers) do o:value(v.name, v.alias) end
	o.default = "nil"
	o.rmempty = false

	o_port = s:option(Value, "tpl_local_port", translate("Local Port"))
	o_port.datatype = "port"
	o_port.default = 1234
	o_port.rmempty = false

	o = s:option(Value, "tpl_mtu", translate("Override MTU"))
	o.datatype = "range(296,9200)"
	o.default = 1492
	o.rmempty = false

	o = s:option(DummyValue, "tpl_server_status", translate("Status"))
	function o.cfgvalue(self, section)	
	    -- alternatively:
	    --local v= m:get(section, 'tpl_local_port')
	    local v = o_port:cfgvalue(section)
	    return "<span id=\"_redir_status_%s\"></span>" % (v or '?')
	end
    o.rawhtml = true

end





return m
