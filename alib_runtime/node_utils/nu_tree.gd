#! namespace ALibRuntime.NodeUtils.NUTree

const AltColor = preload("res://addons/addon_lib/brohd/alib_runtime/node_utils/tree/alternate_color.gd")


static func get_line_edit(tree:Tree):
	var version = ALibRuntime.Utils.UVersion.get_minor_version()
	if version < 6:
		return tree.get_child(1, true).get_child(0, true).get_child(0, true)
	elif version == 6:
		return tree.get_child(0, true).get_child(0, true).get_child(0, true)
