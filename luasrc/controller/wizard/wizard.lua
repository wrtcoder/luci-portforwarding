module("luci.controller.wizard.wizard", package.seeall)

local wizard = require "luci.model.cbi.wizard.portforwarding"
local sys = require "luci.sys"

function index()
	local page
	local uci = require("luci.model.uci").cursor()

	entry({"admin", "wizard"}, firstchild(), "Wizard", 30).dependent=false

	page = entry({"admin", "wizard", "forward"}, template("wizard/forward"), "Port forwarding", 20)
	page.target = template("wizard/forward")

	page = node("admin", "wizard", "devices")
	page.target = cbi("wizard/devices")
	page.title = _("Devices")
	page.order = 10

	page = entry({"admin", "wizard", "get_fwdrules"}, call("get_fwdrules"), nil)
	page.leaf = true
	page = entry({"admin", "wizard", "apply_fwdrules"}, call("apply_fwdrules"), nil)
	page.leaf = true

	-- print connected units
	page = entry({"admin", "wizard", "connected"}, call("connected"), nil)
	page.leaf = true
	-- scan target ip
	page = entry({"admin", "wizard", "scan_ip"}, call("scan_ip"), nil)
	page.leaf = true
end

function scan_ip(target)
	sys.exec("echo scanning: %s > /dev/console" %target)
	--wizard:setip(target);
	luci.http.write(sys.exec("id_service.sh %s" %target))
	sys.exec("echo scanned: %s > /dev/console" %target)
end

function get_fwdrules(devname)
	wizard:construct_table(devname)
	local str = wizard:export_rules(devname)
	loctable = wizard:get_table()
	sys.exec("echo %s > /dev/console" %str)

	luci.http.prepare_content("text/plain")
	luci.http.write(str)
end

function apply_fwdrules(str)
	local args = {}
	for a in string.gmatch(str, "([^%,]+)") do
		args[#args+1] = a
		sys.exec("echo split:  %s > /dev/console" %args[#args])
	end
	devname = args[1]
	target_ip  = args[2]

	wizard:construct_table(devname, target_ip)
	loctable = wizard:get_table()
	sys.exec("echo controller/apply_fwdrules:  description %s > /dev/console" %loctable.description)
	sys.exec("echo controller/apply_fwdrules:  target_ip   %s > /dev/console" %target_ip)
	wizard:apply_rules()
	--redirect to the same page!
	luci.http.redirect(luci.dispatcher.build_url("admin/wizard/forward"))
	--luci.http.redirect(luci.dispatcher.build_url("admin/network/network"))
end

