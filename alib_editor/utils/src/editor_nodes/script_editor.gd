class_name UEdScriptEditor
extends RefCounted

static func get_popup():
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.SCRIPT_EDITOR_CODE_POPUP)

static func get_script_list_popup():
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.SCRIPT_EDITOR_POPUP)

static func get_menu_bar():
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.SCRIPT_EDITOR_MENU_BAR)

static func get_syntax_hl_popup() -> PopupMenu:
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.SCRIPT_EDITOR_SYNTAX_POPUP)
