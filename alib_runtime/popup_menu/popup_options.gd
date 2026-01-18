#! namespace ALibRuntime.Popups class Options
const PopupHelper = preload("res://addons/addon_lib/brohd/alib_runtime/popup_menu/popup_menu_path_helper.gd")
const Params = PopupHelper.ParamKeys

const SELF = preload("res://addons/addon_lib/brohd/alib_runtime/popup_menu/popup_options.gd")

var _dict:= {}

func get_options():
	return _dict

func add_option(menu_path:String, callable, icon_array=null, metadata:={}):
	var data = {}
	if callable != null:
		data[Params.CALLABLE] = callable
	if icon_array != null:
		data[Params.ICON] = icon_array
	if not metadata.is_empty():
		data[Params.METADATA] = metadata
	var count = 1
	var original_path = menu_path
	while _dict.has(menu_path):
		menu_path = "%s (%s)" % [original_path, count]
		count += 1
	_dict[menu_path] = data
	return _dict[menu_path]

func add_radio_option(menu_path:String, callable, is_checked:bool=false, icon_array=null):
	var data = add_option(menu_path, callable, icon_array)
	data[Params.RADIO] = true
	data[Params.RADIO_IS_CHECKED] = is_checked
	return data

func add_option_data(menu_path:String, icon_color=null, metadata:={}):
	if not _dict.has(menu_path):
		printerr("Trying to add data to non-existent option: %s" % menu_path)
		return
	var data = _dict[menu_path]
	if icon_color:
		data[Params.ICON_COLOR] = icon_color

func add_separator(text:=""):
	Params.add_separator(_dict, text)

func merge(options:SELF, overwrite:=false):
	_dict.merge(options.get_options(), overwrite)
