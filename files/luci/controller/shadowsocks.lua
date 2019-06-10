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
	entry({"admin", "services", "shadowsocks", "check"}, call("check_status")).leaf = true
	entry({"admin", "services", "shadowsocks", "refresh"}, call("refresh_data"))
	entry({"admin", "services", "shadowsocks", "checkport"}, call("check_port"))

end

function check_status()
	local ret = luci.sys.call("/usr/bin/ss-check http://www.%s.com" % luci.http.formvalue("set"))
	luci.http.prepare_content("application/json")
	luci.http.write_json({ ret = ret })
end

function refresh_data()
	local set = luci.http.formvalue("set")
	local retstring = "-1"
	if set == "gfw_data" then
		local ret = luci.sys.call("/usr/bin/update_gfwlist.sh >> /var/log/update_gfwlist.log 2>&1")
		if ret == 0 then
			retstring = luci.sys.exec("cat /etc/dnsmasq.d/gfwlist.conf | wc -l")
		else
			retstring ="-1"
		end
	elseif set == "ip_data" then
		local ret = luci.sys.call("/usr/bin/update_chnroute.sh >> /var/log/update_chnroute.log 2>&1")
		if ret == 0 then
			retstring = luci.sys.exec("cat /etc/shadowsocks/chnroute.list | wc -l")
		else
			retstring = "-1"
		end
	end	
	luci.http.prepare_content("application/json")
	luci.http.write_json({ ret = retstring })
end


function check_port()
	local retstring="<br/><br/>"
	local uci = luci.model.uci.cursor()
	uci:foreach("shadowsocks", "servers", function(s)
		local server_name = s.alias
		if not server_name and s.server and s.server_port then
			server_name = "%s:%s" % {s.server, s.server_port}
		end
		socket = nixio.socket("inet", "stream")
		socket:setopt("socket", "rcvtimeo", 3)
		socket:setopt("socket", "sndtimeo", 3)
		ret = socket:connect(s.server, s.server_port)
		if  tostring(ret) == "true" then
			socket:close()
			retstring = retstring .. "<font color='green'>[" .. server_name .. "] OK.</font><br/>"
		else
			retstring = retstring .. "<font color='red'>[" .. server_name .. "] Error.</font><br/>"
		end	
	end)

	luci.http.prepare_content("application/json")
	luci.http.write_json({ ret = retstring })
end

local function server_is_running(port)
	local ret = luci.sys.exec("ps -w | grep ss-redir | grep -v grep | grep %s | wc -l" % port)
	return tonumber(ret)
end

function action_status()
	local proxy_list = {}
	local uci = luci.model.uci.cursor()
	uci:foreach("shadowsocks", "transparent_proxy_list", function(s)
		proxy_list[s.tpl_local_port] = server_is_running(s.tpl_local_port)
	end)
	luci.http.prepare_content("application/json")
	luci.http.write_json(proxy_list)
end

