

static func get_window_global_position(window:Window):
	var id = window.get_window_id()
	return DisplayServer.window_get_position(id)
