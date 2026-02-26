#! namespace ALibRuntime.NodeUtils.NUTree

const UVersion = preload("uid://b4f7kxqukmbj2") # u_version.gd

const AltColor = preload("res://addons/addon_lib/brohd/alib_runtime/node_utils/tree/alternate_color.gd")

static func get_line_edit(tree:Tree):
	var version = UVersion.get_minor_version()
	if version < 6:
		return tree.get_child(1, true).get_child(0, true).get_child(0, true)
	elif version == 6:
		return tree.get_child(0, true).get_child(0, true).get_child(0, true)
