#! namespace ALibRuntime.NodeUtils class NUMarginContainer

const MARGIN_CONSTANTS = ["margin_left", "margin_right", "margin_top", "margin_bottom"]

static func set_margins(margin_container:MarginContainer, val:int):
	for constant in MARGIN_CONSTANTS:
		margin_container.add_theme_constant_override(constant, val)
	
