#! namespace ALibRuntime.NodeUtils.NUItemList

const AltColor = preload("res://addons/addon_lib/brohd/alib_runtime/node_utils/item_list/alternate_color.gd")


static func replace_panel_stylebox_margin(item_list:ItemList, margin:int=0, only_right:=true):
	var sb = item_list.get_theme_stylebox(&"panel").duplicate()
	if only_right:
		sb.content_margin_right = margin
	else:
		sb.set_content_margin_all(margin)
	item_list.add_theme_stylebox_override(&"panel", sb)
