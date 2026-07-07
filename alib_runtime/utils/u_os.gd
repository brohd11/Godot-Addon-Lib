#! namespace ALibRuntime.Utils class UOs

const LINUX = "Linux"
const MAC = "macOS"
const WIN = "Windows"

enum OSType {
	UNKNOWN,
	LINUX,
	MAC,
	WINDOWS
}

static func get_os() -> OSType:
	var system = OS.get_name()
	match system:
		"Windows": return OSType.WINDOWS
		"Linux": return OSType.LINUX
		"macOS": return OSType.MAC
		_: return OSType.UNKNOWN

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

static func launch_term(commands:String, dir:String="res://"):
	var os:= get_os()
	dir = ProjectSettings.globalize_path(dir)
	var command_tail = ""
	if commands != "":
		command_tail = " && " + commands
	match os:
		OSType.WINDOWS:
			# Windows - /K runs the command and Keeps the window open. cd /d
			# switches drive+dir, then run commands (if any) in that folder.
			var command_string = 'cd /d "%s"%s' % [dir, command_tail]
			var exec:String = "cmd.exe"
			var args:Array = ["/K", command_string]
			OS.create_process(exec, args)
			
			# Alternative for PowerShell:
			# OS.create_process("powershell.exe", ["-NoExit", "-Command", "echo 'Hello from Godot'"])
		OSType.LINUX:
			# TODO Linux - have to call a specific terminal emulator. 
			var command_string = "cd %s%s" % [dir, command_tail]
			command_string += "; exec bash"
			
			var exec:String = "gnome-terminal"
			var args:Array = ["--", "bash", "-c", command_string]
			OS.create_process(exec, args)
		
		OSType.MAC:
			var command_string = "cd %s%s" % [dir, command_tail]
			var exec:String = "osascript"
			var do_script:String = 'tell application "Terminal" to do script "%s"' % command_string
			var activate:String = 'tell application "Terminal" to activate'
			var args:Array = ["-e", do_script, "-e", activate]
			OS.create_process(exec, args)
