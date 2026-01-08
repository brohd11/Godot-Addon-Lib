class_name Git

static func check_addons_git():
	for folder in DirAccess.get_directories_at("res://addons"):
		var path = "res://addons".path_join(folder)
		var git_path = path.path_join(".git")
		if FileAccess.file_exists(git_path) or DirAccess.dir_exists_absolute(git_path):
			var dirty = get_git_status(path)
			if dirty:
				print("Uncommmited changes in: %s" % path)

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
