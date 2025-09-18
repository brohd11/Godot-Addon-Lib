
static func get_current_dock(control):
	var parent = control.get_parent()
	if not parent:
		#print("Parent is null. Get dock.")
		return
	var docks = get_all_docks()
	if parent in docks:
		var dock_slot = parent.name.get_slice("DockSlot", 1)
		match dock_slot:
			"LeftUL": return EditorPlugin.DockSlot.DOCK_SLOT_LEFT_UL
			"LeftBL": return EditorPlugin.DockSlot.DOCK_SLOT_LEFT_BL
			"LeftUR": return EditorPlugin.DockSlot.DOCK_SLOT_LEFT_UR
			"LeftBR": return EditorPlugin.DockSlot.DOCK_SLOT_LEFT_BR
			"RightUL": return EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_UL
			"RightBL": return EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_BL
			"RightUR": return EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_UR
			"RightBR": return EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_BR
		
	elif parent == EditorNodeRef.get_registered(EditorNodeRef.Nodes.BOTTOM_PANEL):
		return -2
	elif parent == EditorInterface.get_editor_main_screen():
		return -1
	else:
		return -3

static func get_current_dock_control(control):
	var parent = control.get_parent()
	if not parent:
		#print("Parent is null. Get control.")
		return
	if parent is TabContainer:
		return parent
	elif parent == EditorNodeRef.get_registered(EditorNodeRef.Nodes.BOTTOM_PANEL):
		return parent
	elif parent == EditorInterface.get_editor_main_screen():
		return parent

static func get_all_docks() -> Array:
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.DOCKS)
