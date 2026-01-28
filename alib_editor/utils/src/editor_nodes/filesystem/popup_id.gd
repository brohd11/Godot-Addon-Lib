
static func add_to_favorites():
	var minor = _get_minor_version()
	if minor <= 6:
		return 4

static func remove_from_favorites():
	var minor = _get_minor_version()
	if minor <= 6:
		return 5

static func rename():
	var minor = _get_minor_version()
	if minor <= 6:
		return 10

static func expand_folder():
	var minor = _get_minor_version()
	if minor <= 6:
		return 0

static func expand_hierarchy():
	var minor = _get_minor_version()
	if minor <= 6:
		return 21

static func collapse_hierarchy():
	var minor = _get_minor_version()
	if minor <= 6:
		return 22



static func _get_minor_version():
	return ALibRuntime.Utils.UVersion.get_minor_version()
