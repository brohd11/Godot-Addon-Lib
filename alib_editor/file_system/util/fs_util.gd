

const RightClickHandler = preload("res://addons/addon_lib/brohd/gui_click_handler/right_click_handler.gd")
const Options = RightClickHandler.Options

const EditorIcons = preload("res://addons/addon_lib/brohd/alib_editor/misc/icons/editor_icons.gd")
const CacheHelper = preload("res://addons/addon_lib/brohd/alib_runtime/cache_helper/cache_helper.gd")
const UWindow = preload("res://addons/addon_lib/brohd/alib_runtime/utils/u_window.gd")
const Dialog = preload("res://addons/addon_lib/brohd/alib_runtime/dialog/dialog.gd")
const LineSubmit = Dialog.Handlers.LineSubmit

const PopupID = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/filesystem/popup_id.gd")
const UEditorTheme = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/u_editor_theme.gd")
const ThemeColor = UEditorTheme.ThemeColor
const FileSystem = preload("res://addons/addon_lib/brohd/alib_editor/utils/src/editor_nodes/filesystem.gd")

const UVersion = preload("res://addons/addon_lib/brohd/alib_runtime/utils/u_version.gd")
const UFile = preload("res://addons/addon_lib/brohd/alib_runtime/utils/u_file.gd")
const UResource = preload("res://addons/addon_lib/brohd/alib_runtime/utils/u_resource.gd")
const UOs = preload("res://addons/addon_lib/brohd/alib_runtime/utils/u_os.gd")
const UTree = preload("res://addons/addon_lib/brohd/alib_runtime/utils/u_tree.gd")
const UString = preload("res://addons/addon_lib/brohd/alib_runtime/utils/u_string.gd")

const NUItemList = preload("res://addons/addon_lib/brohd/alib_runtime/node_utils/nu_item_list.gd")
const NUTree = preload("res://addons/addon_lib/brohd/alib_runtime/node_utils/nu_tree.gd")

const SettingHelperEditor = preload("res://addons/addon_lib/brohd/alib_editor/settings/setting_helper.gd")
const SettingHelperSingleton = preload("res://addons/addon_lib/brohd/alib_runtime/settings/components/setting_helper_singleton.gd")
const SettingHelperJson = SettingHelperSingleton.SettingHelperJson

const ColumnDragger = preload("res://addons/addon_lib/brohd/alib_runtime/ui/column/dragger.gd")


static func is_path_valid_res(path:String) -> bool:
	if not path.begins_with("res://"):
		return false
	return FileSystemSingleton.is_path_valid(path)

static func is_root_folder(path:String):
	if path.ends_with("://") or path == "/":
		return true
	return false

static func paths_have_same_root(path:String, path_2:String):
	if path.begins_with("res://"):
		if path_2.begins_with("res://"):
			return true
		return false
	elif path.begins_with("user://"):
		if path_2.begins_with("user://"):
			return true
		return false
	elif path.begins_with("/"):
		if path_2.begins_with("/"):
			return true
		return false
