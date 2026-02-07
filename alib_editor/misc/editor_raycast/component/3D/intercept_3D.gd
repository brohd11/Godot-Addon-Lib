extends "res://addons/addon_lib/brohd/alib_runtime/controller/viewport_raycast/component/base/intercept_base.gd"

func _get_viewport_manager():
	return ALibEditor.Singletons.EditorRaycast3D.get_instance()

func _get_current_tool():
	return _get_viewport_manager().current_tool
