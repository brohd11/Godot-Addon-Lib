#! namespace ALibRuntime.Utils class UOS

const LINUX = "Linux"
const MAC = "macOS"
const WIN = "Windows"

static func get_user():
	var system = OS.get_name()
	if system == LINUX:
		return OS.get_environment("USER")
	elif system == WIN:
		return OS.get_environment("USERNAME")
	elif system == MAC:
		return OS.get_environment("USER")

static func get_hostname():
	var system = OS.get_name()
	if system == LINUX:
		var hostname = OS.get_environment("HOSTNAME")
		hostname = hostname.strip_edges()
		if hostname == "":
			var output = []
			var exit = OS.execute("hostname",[], output)
			hostname = output[0].strip_edges()
			if hostname == "":
				hostname = "linux-pc"
		return hostname
	elif system == WIN:
		return OS.get_environment("COMPUTERNAME")
	elif system == MAC:
		var hostname = OS.get_environment("HOSTNAME")
		hostname = hostname.strip_edges()
		if hostname == "":
			var output = []
			var exit = OS.execute("hostname",[], output)
			hostname = output[0].strip_edges()
			if hostname == "":
				hostname = "mac"
		return hostname


static func get_home_dir():
	var system = OS.get_name()
	if system == LINUX:
		var home = OS.get_environment("HOME")
		return home
	elif system == MAC:
		var home = OS.get_environment("HOME")
		return home
	elif system == WIN:
		var home = OS.get_environment("USERPROFILE")
		return home
