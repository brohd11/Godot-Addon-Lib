#! namespace ALibRuntime.NodeUtils.UItemList class AltColor

const _HL_COLOR_VAL = 0.45
const _HL_COLOR = Color(_HL_COLOR_VAL,_HL_COLOR_VAL,_HL_COLOR_VAL,0.05)

static func draw_lines(item_list:ItemList, color=null):
	if color == null:
		color = _HL_COLOR
	var scroll_pos = item_list.get_v_scroll_bar().value
	for i in range(1, item_list.item_count, 2):
		var rect = item_list.get_item_rect(i, true)
		rect.position.y -= scroll_pos
		if rect.position.y < -rect.size.y:
			continue
		if rect.position.y > item_list.size.y:
			break
		item_list.draw_rect(rect, color)
