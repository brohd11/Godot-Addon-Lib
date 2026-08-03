extends Control

#! import_p UControl

const UControl = ALibRuntime.Utils.UControl
const NUMargin = ALibRuntime.NodeUtils.NUMarginContainer
const PluginButton = preload("uid://cwiqk1fttu0sy").PluginButton #! resolve ALibEditor.UIHelpers.Buttons.PluginButton

const TextViewer = preload("res://addons/addon_lib/brohd/alib_editor/file_system/components/preview/viewers/text.gd")

const TEXT_FILE_TYPES = [
	"txt", "md", "cfg", "ini", "log", "json", "yml", "yaml", "toml", "xml", # std text types
	"gdsh", # editor console
	"gd", "cs", # script types too
	]

var _main_vbox:VBoxContainer
var _preview_vbox:VBoxContainer
var _details_vbox:DetailsPanel


# content specific
var _text_preview:TextViewer
var _packed_scene_preview_3d
var _texture_preview:TextureRect
var _audio_preview


func _ready() -> void:
	# for header
	
	clip_contents = true
	
	_main_vbox = VBoxContainer.new()
	add_child(_main_vbox)
	_main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	_preview_vbox = VBoxContainer.new()
	_main_vbox.add_child(_preview_vbox)
	UControl.expand(_preview_vbox)
	
	_details_vbox = DetailsPanel.new()
	_main_vbox.add_child(_details_vbox)
	
	_text_preview = TextViewer.new()
	UControl.expand(_text_preview)
	
	_texture_preview = TextureRect.new()
	UControl.expand(_texture_preview)
	
	var hide_margin = MarginContainer.new()
	hide_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	NUMargin.set_margins(hide_margin, 1 * EditorInterface.get_editor_scale())
	var hide_button = PluginButton.new("Close", func(): hide()).get_button()
	hide_button.flat = true
	
	hide_margin.add_child(hide_button)
	
	add_child(hide_margin)
	hide_margin.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_TOP_RIGHT)


func preview_file(path:String):
	
	_details_vbox.set_file(path)
	
	if _preview_vbox.get_child_count() > 0:
		_preview_vbox.remove_child(_preview_vbox.get_child(0))
	
	var viewer = _get_viewer(path)
	_preview_vbox.add_child(viewer)




func _get_viewer(path:String):
	var ext = path.get_extension()
	if ext in TEXT_FILE_TYPES:
		_text_preview.set_path(path)
		return _text_preview
	
	# icon maybe later, or overlay, will not be big enough though as is
	#var icon = FileSystemSingleton.get_instance().get_type_icon(path)
	_texture_preview.texture = EditorInterface.get_editor_theme().get_icon(&"FileBigThumb", &"EditorIcons")
	return _texture_preview

class DetailsPanel extends VBoxContainer:
	
	var title_label:= Label.new()
	
	func _ready() -> void:
		add_child(HSeparator.new())
		add_child(title_label)
	
	func set_file(path:String):
		title_label.text = path.get_file()
		
		pass
