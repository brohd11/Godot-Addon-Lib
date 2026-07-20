extends RefCounted

const NUTree = ALibRuntime.NodeUtils.NUTree

class GitItemHelper:
	var git_service:GitService
	var _item_list:ItemList
	
	func _init(item_list:ItemList) -> void:
		_item_list = item_list
	
	pass


class GitTreeHelper:
	
	const GitUtil = preload("res://addons/addon_lib/brohd/alib_editor/misc/git_service/git_util.gd")
	
	var git_service:GitService
	var _tree:Tree
	var _overlay:Control
	var _overlay_icons:= []
	
	var marker_icon:Texture2D
	
	func _init(tree) -> void:
		git_service = GitService.get_instance()
		
		_tree = tree
		_tree.draw.connect(_on_tree_draw)
		_overlay = Control.new()
		_tree.add_child(_overlay)
		_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay.draw.connect(_draw_icon_overlay)
		
		marker_icon = EditorInterface.get_editor_theme().get_icon(&"Breakpoint", &"EditorIcons")
	
	
	func process_tree_item(file_path:String, tree_item:TreeItem):
		var color = git_service.get_file_color(file_path)
		if color == null:
			return
		
		
		tree_item.set_custom_color(0, color)
		if file_path.ends_with("/") and git_service.is_repo(file_path):
			tree_item.set_meta(Keys.IS_REPO, true)
			
		# a row with its own git color (repo, ignored, itself a change) keeps it when a
		# descendant bubbles up — only an uncolored row takes a descendant's severity color
		tree_item.set_meta(Keys.OWN_COLOR, true)
		var icon = git_service.get_file_icon(file_path)
		if icon == null:
			return
		
		var severity = git_service.get_file_severity(file_path)
		_set_item_meta(tree_item, icon, color, severity)
		
		var par = tree_item.get_parent()
		while is_instance_valid(par):
			if _set_item_meta(par, marker_icon, color, severity):
				if not par.has_meta(Keys.OWN_COLOR):
					par.set_custom_color(0, color)
			
			if par.has_meta(Keys.IS_REPO):
				# once you break a repo barrier, this should continue up as a low severity
				# message. Any message in the parent repo, will beat this one
				color = git_service.colors.repo
				severity = GitUtil.Severity.NESTED
			
			par = par.get_parent()
	
	
	# first tree must calculate visible rects then queue the overlay to draw them
	func _on_tree_draw():
		_overlay_icons.clear()
		
		var root = _tree.get_root()
		if not is_instance_valid(root):
			return
		
		var tree_rect = _tree.get_rect()
		var icon_margin = _tree.get_theme_constant(&"icon_h_separation")
		
		var next_item = root.get_next_visible()
		while is_instance_valid(next_item):
			var current_item = next_item
			next_item = next_item.get_next_visible()
			
			if not current_item.has_meta(Keys.GIT_ICON):
				continue
			var current_rect = _tree.get_item_area_rect(current_item, 0)
			if current_rect.position.y < 0 - current_rect.size.y or current_rect.position.y > tree_rect.size.y:
				continue
			
			# anything not in view or with no icon is a no-op
			
			var meta = current_item.get_meta(Keys.GIT_ICON)
			var icon:Texture2D = meta.icon
			
			if NUTree.item_text_overflows(_tree, current_item, icon):
				continue
			
			current_rect.position.x += current_rect.size.x - icon.get_size().x - icon_margin
			# centre against the row height, not a fraction of the icon: the marker and the
			# glyph squares are different sizes, so one fixed fraction cannot centre both
			current_rect.position.y += (current_rect.size.y - icon.get_size().y) / 2.0
			current_rect.size = icon.get_size()
			_overlay_icons.append({
				Keys.RECT: current_rect,
				Keys.ICON: icon,
				Keys.COLOR: meta.color
			})
			
		_overlay.queue_redraw()

	# just draw the precalced textures
	func _draw_icon_overlay():
		for data in _overlay_icons:
			_overlay.draw_texture_rect(
				data.get(Keys.ICON), 
				data.get(Keys.RECT), 
				false, 
				data.get(Keys.COLOR))
	
	# a less severe descendant must not overwrite the marker a more severe one left.
	# returns whether the meta was (re)written, so the caller knows the row color may follow
	func _set_item_meta(tree_item:TreeItem, icon:Texture2D, color:Color, severity:int) -> bool:
		var existing:Dictionary = tree_item.get_meta(Keys.GIT_ICON, {})
		if int(existing.get(Keys.SEVERITY, GitUtil.Severity.NONE)) >= severity:
			return false
		tree_item.set_meta(Keys.GIT_ICON, {
			Keys.ICON: icon,
			Keys.COLOR: color,
			Keys.SEVERITY: severity,
		})
		return true

class Keys:
	const GIT_ICON = &"git_icon"
	const OWN_COLOR = &"own_color"
	const IS_REPO = &"repo"
	
	const RECT = &"rect"
	const ICON = &"icon"
	const COLOR = &"color"
	const SEVERITY = &"severity"
	
