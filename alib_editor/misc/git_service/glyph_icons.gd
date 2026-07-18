extends Node

## Rasterizes single characters into square textures, so a glyph can be positioned as a square rather
## than as a string. A string is placed by its advance width, which differs per glyph, and there is no
## way to ask draw_string to centre a glyph on its ink — baked into a square, every letter draws at
## one x on every row. It is also the only way to put a letter on a Tree, which takes a Texture2D.
##
## The textures are white; colour is the caller's draw-time modulate, so the cache holds one texture
## per character rather than one per character per colour.
##
## Rasterizing goes through a SubViewport, not the TextServer glyph atlas: the atlas holds real pixels
## only for an ordinary bitmap-cached font, where an MSDF face stores a distance field and a
## FontVariation or fallback files the glyph under a different RID. The editor's font may be any of
## those. A viewport is the real draw path, and Image.get_used_rect() then gives the exact ink box.
## The cost is one rendered frame, once, for the whole set — see warm().

const NODE_NAME = &"GlyphIcons"

## unscaled px of clear space around the ink on every side
const PAD = 1
## unscaled px the square will not go below, so a narrow set of glyphs still yields a usable icon
const MIN_SIDE = 12

# character (String) -> ImageTexture, white on transparent, ink centred
var _cache:Dictionary = {}
# the square's side in px, shared by every texture in _cache
var _side:int = 0

signal generated

# what _cache was baked against; a mismatch means the editor's font or scale moved under us
var _key:String = ""
var _chars:String = ""
var _warming:bool = false

## The cached texture for a character, or null if the cache has not been baked yet. Null is a normal
## return: warm() takes a frame, and a caller landing inside it should draw the character as a string.
## Connect to `generated` to pick the texture up once it exists.
func get_letter(letter:String) -> Texture2D:
	return _cache.get(letter)

## The side of every square in the cache, in px. 0 until the first bake lands.
func get_side() -> int:
	return _side

func _ready() -> void:
	# font size and editor scale both live in the editor settings, and both change the square
	EditorInterface.get_editor_settings().settings_changed.connect(_on_editor_settings_changed)

## Bake `chars` into the cache. Costs one rendered frame, for the whole set at once. Call it as early
## as there is a tree to sit in, though nothing depends on winning that race — until it lands,
## get_letter() returns null and callers fall back to drawing the character as a string.
func warm(chars:String) -> void:
	if _warming or chars.is_empty():
		return

	_chars = chars
	var font = EditorInterface.get_editor_theme().get_font(&"main", &"EditorFonts")
	var font_size = EditorInterface.get_editor_theme().get_font_size(&"main_size", &"EditorFonts")
	if font == null or font_size <= 0:
		return

	var key = _make_key(font, font_size)
	if key == _key and not _cache.is_empty():
		return

	_warming = true
	var baked = await _rasterize(chars, font, font_size)
	_warming = false

	if baked.is_empty():
		return # a failed bake leaves the old cache up rather than blanking every row

	_cache = baked[&"textures"]
	_side = baked[&"side"]
	_key = key
	generated.emit()


# Draw the whole set into one viewport, one glyph per cell, then cut it up. One pass, one frame.
# Where each glyph lands in its cell does not matter — the ink box is recovered from the pixels
# afterwards, so the draw only has to be clear of the cell's edges.
func _rasterize(chars:String, font:Font, font_size:int) -> Dictionary:
	var cell = int(ceil(font.get_height(font_size) * 2.0))
	if cell <= 0:
		return {}

	var count = chars.length()

	var viewport = SubViewport.new()
	viewport.size = Vector2i(cell * count, cell)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

	var canvas = Control.new()
	canvas.size = viewport.size
	canvas.draw.connect(func():
		for i in count:
			canvas.draw_char(font, Vector2(i * cell + cell * 0.25, cell * 0.75), chars[i],
				font_size, Color.WHITE)
	)

	viewport.add_child(canvas)
	add_child(viewport)

	await RenderingServer.frame_post_draw

	var strip:Image = viewport.get_texture().get_image()
	viewport.queue_free()

	if strip == null:
		return {}
	if strip.is_compressed():
		strip.decompress()
	strip.convert(Image.FORMAT_RGBA8)

	# 1. cut the strip into cells and find each glyph's ink box. The square has to clear the largest
	# ink in the set, in both axes, or the widest letter would be the one that gets clipped.
	var cells:Array[Image] = []
	var inks:Array[Rect2i] = []
	var side = 0

	for i in count:
		var cell_image = strip.get_region(Rect2i(i * cell, 0, cell, cell))
		var ink = cell_image.get_used_rect()
		cells.append(cell_image)
		inks.append(ink)
		side = maxi(side, maxi(ink.size.x, ink.size.y))

	var scale = EditorInterface.get_editor_scale()
	side += int(2 * PAD * scale)
	side = maxi(side, int(MIN_SIDE * scale))

	# 2. centre each ink box in a square of that one side. Centring on the ink rather than a baseline
	# only holds for an all-cap-height set (the git letters, plus "?"); feed it a descender and it
	# would have to become baseline relative.
	var textures := {}
	for i in count:
		var ink:Rect2i = inks[i]
		if ink.size.x <= 0 or ink.size.y <= 0:
			continue # the font has no glyph for this character; leave it out and let the caller fall back

		var square = Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
		square.fill(Color(1, 1, 1, 0))
		square.blit_rect(cells[i], ink, Vector2i(
			int((side - ink.size.x) / 2.0),
			int((side - ink.size.y) / 2.0),
		))
		_force_white(square)
		textures[chars[i]] = ImageTexture.create_from_image(square)

	return {&"textures": textures, &"side": side}


# The viewport composites onto a transparent background, leaving the glyph's antialiased edge
# carrying the background's colour — a dark fringe once modulated to a light colour. Flattening RGB
# to white and keeping only the alpha removes it.
func _force_white(image:Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var alpha = image.get_pixel(x, y).a
			if alpha > 0.0:
				image.set_pixel(x, y, Color(1, 1, 1, alpha))


func _make_key(font:Font, font_size:int) -> String:
	return "%d|%d|%.2f" % [font.get_instance_id(), font_size, EditorInterface.get_editor_scale()]


func _on_editor_settings_changed() -> void:
	if _warming or _chars.is_empty():
		return

	var font = EditorInterface.get_editor_theme().get_font(&"main", &"EditorFonts")
	var font_size = EditorInterface.get_editor_theme().get_font_size(&"main_size", &"EditorFonts")
	if font == null or _make_key(font, font_size) == _key:
		return # the settings that moved were not ones the squares are baked against

	warm(_chars)
