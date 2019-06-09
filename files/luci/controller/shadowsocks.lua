-- Copyright (C) 2017 yushi studio <ywb94@qq.com>
-- Licensed to the public under the GNU General Public License v3.

module("luci.controller.shadowsocks", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/shadowsocks") then
		return
	end

	entry({"admin", "services", "shadowsocks"}, 
		alias("admin", "services", "shadowsocks", "general"), 
		_("ShadowSocks"), 10).dependent = true

	entry({"admin", "services", "shadowsocks", "general"}, 
		cbi("shadowsocks/general"), 
		_("General Settings"), 10).leaf = true

 	entry({"admin", "services", "shadowsocks", "access-control"},
		cbi("shadowsocks/access-control"),
		_("Access Control"), 20).leaf = true

	entry({"admin", "services", "shadowsocks", "servers"},
			arcombine(cbi("shadowsocks/servers"), cbi("shadowsocks/servers-details")),
			_("Servers Manage"), 30).leaf = true
 
	entry({"admin", "services", "shadowsocks", "tools"},
		cbi("shadowsocks/tools"),
		_("Tools"), 40).leaf = true


	entry({"admin", "services", "shadowsocks", "status"}, call("action_status")).leaf = true
	entry({"admin", "services", "shadowsocks", "check"}, call("check_status"))
	entry({"admin", "services", "shadowsocks", "refresh"}, call("refresh_data"))
	entry({"admin", "services", "shadowsocks", "checkport"}, call("check_port"))

end

function check_status()
	local set ="/usr/bin/ss-check www." .. luci.http.formvalue("set") .. ".com 80 3 1"
	sret=luci.sys.call(set)
	if sret== 0 then
		retstring ="0"
	else
		retstring ="1"
	end	
	luci.http.prepare_content("application/json")
	luci.http.write_json({ ret=retstring })
end

function refresh_data()
	local set =luci.http.formvalue("set")
	local icount =0
	if set == "gfw_data" then
		refresh_cmd="/usr/bin/update_gfwlist.sh >> /var/log/update_gfwlist.log"
		sret = luci.sys.call(refresh_cmd .. " 2>/dev/null")
		if sret == 0 then
			icount = luci.sys.exec("cat /etc/dnsmasq.d/gfwlist.conf | wc -l")
			retstring = tostring(tonumber(icount))
		else
			retstring ="-1"
		end
	elseif set == "ip_data" then
		refresh_cmd="/usr/bin/update_chnroute.sh >> /var/log/update_chnroute.log"
		sret = luci.sys.call(refresh_cmd .. " 2>/dev/null")
		icount = luci.sys.exec("cat /etc/shadowsocks/chnroute.list | wc -l")
		if sret == 0 then
			retstring = tostring(tonumber(icount))
		else
			retstring ="-1"
		end
	end	
	luci.http.prepare_content("application/json")
	luci.http.write_json({ ret=retstring ,retcount=icount})
end


function check_port()
	local set=""
	local retstring="<br /><br />"
	local s
	local server_name = ""
	local shadowsocks = "shadowsocks"
	local uci = luci.model.uci.cursor()
	local iret=1

	uci:foreach(shadowsocks, "servers", function(s)

		if s.alias then
			server_name = s.alias
		elseif s.server and s.server_port then
			server_name = "%s:%s" %{s.server, s.server_port}
		end
		--iret = luci.sys.call(" ipset add ss_spec_wan_ac " .. s.server .. " 2>/dev/null")
		socket = nixio.socket("inet", "stream")
		socket:setopt("socket", "rcvtimeo", 3)
		socket:setopt("socket", "sndtimeo", 3)
		ret=socket:connect(s.server,s.server_port)
		if  tostring(ret) == "true" then
			socket:close()
			retstring =retstring .. "<font color='green'>[" .. server_name .. "] OK.</font><br />"
		else
			retstring =retstring .. "<font color='red'>[" .. server_name .. "] Error.</font><br />"
		end	
		--if iret == 0 then
			--luci.sys.call(" ipset del ss_spec_wan_ac " .. s.server)
		--end
	end)

	luci.http.prepare_content("application/json")
	luci.http.write_json({ ret=retstring })
end

local function server_is_running(name)
	local ret = luci.sys.exec("ps | grep ssr-redir | grep -v grep | grep %s | wc -l" % name)
	return tonumber(ret)
end

function action_status()

	local proxy_list = {}
	uci:foreach(shadowsocks, "transparent_proxy_list", function(s)
		proxy_list[s.server] = server_is_running(s.server) 
	end)

	luci.http.prepare_content("application/json")
	luci.http.write_json(proxy_list)
end

