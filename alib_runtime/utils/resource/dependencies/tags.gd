## Built-in `#!` tag handlers. Nothing here runs unless the caller registers it, so a plain
## scan treats every tag as an ordinary comment.
##
## A handler is a Callable taking one context dict:
##   {"file_path", "line", "line_no", "tag", "value", "raws"}
## `value` is the text after the tag, `raws` the path-looking string literals on the line.
## Return a Dictionary to emit one TAG edge per entry in `raws` carrying it as edge.meta,
## or null to emit nothing. A returned "paths" key replaces `raws` as the edge targets and
## is stripped from the metadata.

const DepGraph = preload("res://addons/addon_lib/brohd/alib_runtime/utils/resource/dependencies/dep_graph.gd")


## `#! dependency [dir]` - marks a path on the line as a dependency and optionally names the
## directory it should land in. Reproduces the plugin_exporter tag, where "current" means
## "beside the dependent".
static func dependency_dir() -> Callable:
	return func(ctx:Dictionary) -> Variant:
		if ctx.raws.is_empty():
			return null
		var value:String = ctx.value
		# The path may sit after the tag (`#! dependency "res://x.png" assets`) - drop it,
		# it is already in raws, and keep what follows as the directory.
		if value.begins_with('"') or value.begins_with("'"):
			var end = value.find(value[0], 1)
			value = value.substr(end + 1) if end > -1 else ""
		value = value.strip_edges()
		if value == "":
			return {}
		return {DepGraph.KEY_DEPENDENCY_DIR: value}


## Emits an edge for every path-looking literal on a tagged line, with no extra metadata.
## Useful for one-off project tags: add_tag_handler("asset", Tags.plain())
static func plain() -> Callable:
	return func(ctx:Dictionary) -> Variant:
		if ctx.raws.is_empty():
			return null
		return {}
