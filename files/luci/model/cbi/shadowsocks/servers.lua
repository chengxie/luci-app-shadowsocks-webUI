-- Copyright (C) 2019 chengxie <chengxie@me.com>
-- Licensed to the public under the GNU General Public License v3.

local m, s, o
local shadowsocks = "shadowsocks"

m = Map(shadowsocks, "%s - %s" %{translate("Shadowsocks"), translate("Servers Manage")})

-- [[ Servers Manage ]]--
s = m:section(TypedSection, "servers")
s.anonymous = true
s.addremove = true
s.sortable = true
s.template = "cbi/tblsection"
s.extedit = luci.dispatcher.build_url("admin/services/shadowsocks/servers/%s")
	
function s.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(s.extedit % sid)
		return
	end
end 

o = s:option(DummyValue, "alias", translate("Alias"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o = s:option(DummyValue, "server", translate("Server"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = s:option(DummyValue, "server_port", translate("Port"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = s:option(DummyValue, "encrypt_method", translate("Encrypt Method"))
function o.cfgvalue(...)
	local v = Value.cfgvalue(...)
	return v and v:upper() or "?"
end     

o = s:option(DummyValue, "plugin", translate("Plugin"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

return m

