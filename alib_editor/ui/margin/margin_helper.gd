#! namespace ALibEditor.UIHelpers class Margin

static func new_plugin_margin_container():
	var margin_container = MarginContainer.new()
	var main_marg = 0
	var minor_version = ALibRuntime.Utils.UVersion.get_minor_version()
	if minor_version == 6:
		main_marg = -2 * EditorInterface.get_editor_scale()
	margin_container.add_theme_constant_override("margin_top", main_marg)
	margin_container.add_theme_constant_override("margin_left", main_marg)
	margin_container.add_theme_constant_override("margin_right", main_marg)
	margin_container.add_theme_constant_override("margin_bottom", main_marg)
	return margin_container
