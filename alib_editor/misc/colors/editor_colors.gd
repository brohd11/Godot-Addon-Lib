#! namespace ALibEditor class Colors

enum SyntaxColor {
	ENGINE_TYPE,
	SYMBOL,
	KEYWORD,
	CONTROL_FLOW_KEYWORD,
	BASE_TYPE,
	USER_TYPE,
	NUMBER,
	FUNCTION,
	MEMBER_VARIABLE,
	STRING,
	STRING_PLACEHOLDER,
	FUNCTION_DEFINITION,
	GLOBAL_FUNCTION,
	NODE_PATH,
	NODE_REFERENCE,
	ANNOTATION,
	STRING_NAME,
	COMMENT,
	DOC_COMMENT,
}

static func get_syntax_color(color:SyntaxColor):
	var ed_settings = EditorInterface.get_editor_settings()
	var setting = ""
	match color:
		SyntaxColor.ENGINE_TYPE: setting = &"text_editor/theme/highlighting/engine_type_color"
		SyntaxColor.SYMBOL: setting = &"text_editor/theme/highlighting/symbol_color"
		SyntaxColor.KEYWORD: setting = &"text_editor/theme/highlighting/keyword_color"
		SyntaxColor.CONTROL_FLOW_KEYWORD: setting = &"text_editor/theme/highlighting/control_flow_keyword_color"
		SyntaxColor.BASE_TYPE: setting = &"text_editor/theme/highlighting/base_type_color"
		SyntaxColor.USER_TYPE: setting = &"text_editor/theme/highlighting/user_type_color"
		SyntaxColor.NUMBER: setting = &"text_editor/theme/highlighting/number_color"
		SyntaxColor.FUNCTION: setting = &"text_editor/theme/highlighting/function_color"
		SyntaxColor.MEMBER_VARIABLE: setting = &"text_editor/theme/highlighting/member_variable_color"
		SyntaxColor.STRING: setting = &"text_editor/theme/highlighting/string_color"
		SyntaxColor.STRING_PLACEHOLDER: setting = &"text_editor/theme/highlighting/string_placeholder_color"
		SyntaxColor.FUNCTION_DEFINITION: setting = &"text_editor/theme/highlighting/gdscript/function_definition_color"
		SyntaxColor.GLOBAL_FUNCTION: setting = &"text_editor/theme/highlighting/gdscript/global_function_color"
		SyntaxColor.NODE_PATH: setting = &"text_editor/theme/highlighting/gdscript/node_path_color"
		SyntaxColor.NODE_REFERENCE: setting = &"text_editor/theme/highlighting/gdscript/node_reference_color"
		SyntaxColor.ANNOTATION: setting = &"text_editor/theme/highlighting/gdscript/annotation_color"
		SyntaxColor.STRING_NAME: setting = &"text_editor/theme/highlighting/gdscript/string_name_color"
		SyntaxColor.COMMENT: setting = &"text_editor/theme/highlighting/comment_color"
		SyntaxColor.DOC_COMMENT: setting = &"text_editor/theme/highlighting/doc_comment_color"
	if setting == "":
		return null
	return ed_settings.get_setting(setting)


enum ThemeColor{
	BASE,
	ACCENT,
	
	MONO,
	DARK_1,
	DARK_2,
	DARK_3,
	CONTRAST_1,
	CONTRAST_2,
	HIGHLIGHT,
	HIGHLIGHT_DISABLED,
	DISABLED_HIGHLIGHT, #?? seems to be 2 entries
	
	SUCCESS,
	SUCCESS_DARK_BG,
	WARNING,
	WARNING_DARK_BG,
	ERROR,
	ERROR_DARK_BG,
	
	RULER,
	EXTRA_BORDER_1,
	EXTRA_BORDER_2,
	
	READONLY,
	ICON_NORMAL,
	ICON_FOCUS,
	ICON_HOVER,
	ICON_PRESSED,
	ICON_DISABLED,
	ICON_SATURATION,
	
	SELECTION,
	DISABLED_BORDER,
	DISABLED_BG,
	SEPARATOR,
	BOX_SELECTION_FILL,
	BOX_SELECTION_STROKE,
	
	AXIS_X,
	AXIS_Y,
	AXIS_Z,
	AXIS_W,
	
	PROPERTY_X,
	PROPERTY_Y,
	PROPERTY_Z,
	PROPERTY_W,
	
	FORWARD_PLUS,
	MOBILE,
	GL_COMPATIBILITY,
	
	BACKGROUND,
	PROP_SUBSECTION_STYLEBOX,
	PROP_SUBSECTION,
	PROPERTY,
	
	FONT,
	FONT_FOCUS,
	FONT_HOVER,
	FONT_PRESSED,
	FONT_HOVER_PRESSED,
	FONT_DISABLED,
	FONT_READONLY,
	FONT_PLACEHOLDER,
	FONT_OUTLINE,
	FONT_DARK_BG,
	FONT_DARK_BG_FOCUS,
	FONT_DARK_BG_HOVER,
	FONT_DARK_BG_PRESSED,
	FONT_DARK_BG_HOVER_PRESSED,
	READONLY_FONT,
	DISABLED_FONT,
	HIGHLIGHTED_FONT,
}

static func get_theme_color(color:ThemeColor):
	var thm = EditorInterface.get_editor_theme()
	match color:
		ThemeColor.BASE: return thm.get_color("base_color", &"Editor")
		ThemeColor.ACCENT: return thm.get_color("accent_color", &"Editor")
		ThemeColor.MONO: return thm.get_color("mono_color", &"Editor")
		ThemeColor.DARK_1: return thm.get_color("dark_color_1", &"Editor")
		ThemeColor.DARK_2: return thm.get_color("dark_color_2", &"Editor")
		ThemeColor.DARK_3: return thm.get_color("dark_color_3", &"Editor")
		ThemeColor.CONTRAST_1: return thm.get_color("contrast_color_1", &"Editor")
		ThemeColor.CONTRAST_2: return thm.get_color("contrast_color_2", &"Editor")
		ThemeColor.HIGHLIGHT: return thm.get_color("highlight_color", &"Editor")
		ThemeColor.HIGHLIGHT_DISABLED: return thm.get_color("highlight_disabled_color", &"Editor")
		ThemeColor.DISABLED_HIGHLIGHT: return thm.get_color("disabled_highlight_color", &"Editor") #?? seems to be 2 entries
		ThemeColor.SUCCESS: return thm.get_color("success_color", &"Editor")
		ThemeColor.SUCCESS_DARK_BG: return thm.get_color("success_color_dark_background", &"Editor")
		ThemeColor.WARNING: return thm.get_color("warning_color", &"Editor")
		ThemeColor.WARNING_DARK_BG: return thm.get_color("warning_color_dark_background", &"Editor")
		ThemeColor.ERROR: return thm.get_color("error_color", &"Editor")
		ThemeColor.ERROR_DARK_BG: return thm.get_color("error_color_dark_background", &"Editor")
		ThemeColor.RULER: return thm.get_color("ruler_color", &"Editor")
		ThemeColor.EXTRA_BORDER_1: return thm.get_color("extra_border_color_1", &"Editor")
		ThemeColor.EXTRA_BORDER_2: return thm.get_color("extra_border_color_2", &"Editor")
		ThemeColor.READONLY: return thm.get_color("readonly_color", &"Editor")
		ThemeColor.ICON_NORMAL: return thm.get_color("icon_normal_color", &"Editor")
		ThemeColor.ICON_FOCUS: return thm.get_color("icon_focus_color", &"Editor")
		ThemeColor.ICON_HOVER: return thm.get_color("icon_hover_color", &"Editor")
		ThemeColor.ICON_PRESSED: return thm.get_color("icon_pressed_color", &"Editor")
		ThemeColor.ICON_DISABLED: return thm.get_color("icon_disabled_color", &"Editor")
		ThemeColor.ICON_SATURATION: return thm.get_color("icon_saturation", &"Editor")
		ThemeColor.SELECTION: return thm.get_color("selection_color", &"Editor")
		ThemeColor.DISABLED_BORDER: return thm.get_color("disabled_border_color", &"Editor")
		ThemeColor.DISABLED_BG: return thm.get_color("disabled_bg_color", &"Editor")
		ThemeColor.SEPARATOR: return thm.get_color("separator_color", &"Editor")
		ThemeColor.BOX_SELECTION_FILL: return thm.get_color("box_selection_fill_color", &"Editor")
		ThemeColor.BOX_SELECTION_STROKE: return thm.get_color("box_selection_stroke_color", &"Editor")
		ThemeColor.AXIS_X: return thm.get_color("axis_x_color", &"Editor")
		ThemeColor.AXIS_Y: return thm.get_color("axis_y_color", &"Editor")
		ThemeColor.AXIS_Z: return thm.get_color("axis_z_color", &"Editor")
		ThemeColor.AXIS_W: return thm.get_color("axis_w_color", &"Editor")
		ThemeColor.PROPERTY_X: return thm.get_color("property_color_x", &"Editor")
		ThemeColor.PROPERTY_Y: return thm.get_color("property_color_y", &"Editor")
		ThemeColor.PROPERTY_Z: return thm.get_color("property_color_z", &"Editor")
		ThemeColor.PROPERTY_W: return thm.get_color("property_color_w", &"Editor")
		ThemeColor.FORWARD_PLUS: return thm.get_color("forward_plus_color", &"Editor")
		ThemeColor.MOBILE: return thm.get_color("mobile_color", &"Editor")
		ThemeColor.GL_COMPATIBILITY: return thm.get_color("gl_compatibility_color", &"Editor")
		ThemeColor.BACKGROUND: return thm.get_color("background", &"Editor")
		ThemeColor.PROP_SUBSECTION_STYLEBOX: return thm.get_color("prop_subsection_stylebox_color", &"Editor")
		ThemeColor.PROP_SUBSECTION: return thm.get_color("prop_subsection", &"Editor")
		ThemeColor.PROPERTY: return thm.get_color("property_color", &"Editor")
		
		ThemeColor.FONT: return thm.get_color("font_color", &"Editor")
		ThemeColor.FONT_FOCUS: return thm.get_color("font_focus_color", &"Editor")
		ThemeColor.FONT_HOVER: return thm.get_color("font_hover_color", &"Editor")
		ThemeColor.FONT_PRESSED: return thm.get_color("font_pressed_color", &"Editor")
		ThemeColor.FONT_HOVER_PRESSED: return thm.get_color("font_hover_pressed_color", &"Editor")
		ThemeColor.FONT_DISABLED: return thm.get_color("font_disabled_color", &"Editor")
		ThemeColor.FONT_READONLY: return thm.get_color("font_readonly_color", &"Editor")
		ThemeColor.FONT_PLACEHOLDER: return thm.get_color("font_placeholder_color", &"Editor")
		ThemeColor.FONT_OUTLINE: return thm.get_color("font_outline_color", &"Editor")
		ThemeColor.FONT_DARK_BG: return thm.get_color("font_dark_background_color", &"Editor")
		ThemeColor.FONT_DARK_BG_FOCUS: return thm.get_color("font_dark_background_focus_color", &"Editor")
		ThemeColor.FONT_DARK_BG_HOVER: return thm.get_color("font_dark_background_hover_color", &"Editor")
		ThemeColor.FONT_DARK_BG_PRESSED: return thm.get_color("font_dark_background_pressed_color", &"Editor")
		ThemeColor.FONT_DARK_BG_HOVER_PRESSED: return thm.get_color("font_dark_background_hover_pressed_color", &"Editor")
		ThemeColor.READONLY_FONT: return thm.get_color("readonly_font_color", &"Editor")
		ThemeColor.DISABLED_FONT: return thm.get_color("disabled_font_color", &"Editor")
		ThemeColor.HIGHLIGHTED_FONT: return thm.get_color("highlighted_font_color", &"Editor")
