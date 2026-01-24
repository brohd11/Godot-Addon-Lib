#! namespace ALibRuntime.NodeUtils.UTree class AltColor

const _HL_COLOR_VAL = 0.45
const _HL_COLOR = Color(_HL_COLOR_VAL,_HL_COLOR_VAL,_HL_COLOR_VAL,0.05)

static func draw_lines(tree:Tree):
	var item = tree.get_root()
	if not is_instance_valid(item):
		return
	if tree.hide_root:
		item = item.get_next_visible() # move off the root, is invisible
	var index = 1
	var highlight_color = _HL_COLOR
	while item:
		if index % 2 == 1:
			
			# 1. Get the rect for the specific item
			# The -1 gets the rect for the whole row, not just the text column
			var rect = tree.get_item_area_rect(item, -1)
			# 2. Fix the width
			# get_item_area_rect often returns a width specific to the content.
			# If you want the highlight to span the full control width:
			rect.position.x = 0
			rect.size.x = tree.size.x
			tree.draw_rect(rect, highlight_color)
		
		item = item.get_next_visible()
		index += 1
