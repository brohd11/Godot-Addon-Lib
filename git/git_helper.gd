class_name Git

const OPEN_IN_TERM_SH = "res://tools/git_submodule/open_in_term.sh"
const GET_SUBMODULES_SH = "res://tools/git_submodule/get_submodules_bundled.sh"

static func list_submodules_sh(arg:=""):
	var args = []
	args.append("--raw")
	if arg != "":
		args.append(arg)
	
	var sh_path = ProjectSettings.globalize_path(GET_SUBMODULES_SH)
	
	var output = []
	var exit_code = OS.execute(sh_path, args, output)
	if exit_code == -1:
		printerr("Could not get submodules.")
		return
	
	print("CODE::", exit_code, "::", output)
	
	pass

static func list_submodules(only_dirty:=false):
	var args = ["submodule", "status"]
	var output = []
	var exit_code = OS.execute("git", args, output)
	if exit_code == -1:
		printerr("Could not get submodules.")
		return
	var submod_str = output[0] as String
	var submodules_strings = submod_str.strip_edges().split("\n", false)
	var submodule_paths = []
	for string in submodules_strings:
		var path = string.strip_edges().split(" ")[1]
		if not path.is_empty():
			submodule_paths.append(path)
	
	var to_show = []
	if only_dirty:
		print("=== Dirty Submodules ===")
		for path in submodule_paths:
			if get_git_status(path):
				to_show.append(path)
	else:
		print("=== All Submodules ===")
		to_show = submodule_paths
	
	
	if to_show.is_empty():
		print("(None to show)")
	else:
		for p in to_show:
			print(" - ", p)


static func get_git_status(dir):
	var args = [
		"-C",
		dir.replace("res://", ""),
		"diff",
		"--quiet",
		"--exit-code"
	]
	var output = []
	var exit_code = OS.execute("git", args, output)
	if exit_code == -1:
		printerr("Error getting git status: %s" % dir)
		return
	
	if exit_code == 0:
		return false
	elif exit_code == 1: #dirty
		return true


static func open_submodules_in_term(only_dirty:=false):
	if not FileAccess.file_exists(OPEN_IN_TERM_SH):
		print("No open in term script present.")
		return
	
	var args = []
	if only_dirty:
		args.append("-d")
	
	var sh_path = ProjectSettings.globalize_path(OPEN_IN_TERM_SH)
	
	var output = []
	var exit_code = OS.execute(sh_path, args, output)
	if exit_code == -1:
		printerr("Could not run script.")
		return
	print(exit_code)
