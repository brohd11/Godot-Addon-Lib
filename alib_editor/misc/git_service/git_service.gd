class_name GitService
extends SingletonRefCount
const SingletonRefCount = Singletons.RefCount

## Headless git data provider, shared across consumers (the git panel, the diff gutter, and — later —
## the file tree and a standalone line-diff plugin).
##
## Owns the repo list, the current selection, the per-file status dict and the commit log. Every git
## call runs off the main thread and is published through `status_updated` / `commits_updated` /
## `repos_updated`. This node holds no UI: it wraps the static GitUtil library and is the piece
## destined to migrate into addon_lib once the API settles.


#region SingletonAPI

const PE_STRIP_CAST_SCRIPT = preload("res://addons/addon_lib/brohd//alib_editor/misc/git_service/git_service.gd")

static func get_singleton_name() -> String:
	return "GitService"

static func get_instance() -> PE_STRIP_CAST_SCRIPT:
	return _get_instance(PE_STRIP_CAST_SCRIPT)

static func instance_valid() -> bool:
	return _instance_valid(PE_STRIP_CAST_SCRIPT)

static func register_node(node:Node):
	return _register_node(PE_STRIP_CAST_SCRIPT, node)

static func unregister_node(node:Node):
	_unregister_node(PE_STRIP_CAST_SCRIPT, node)

static func call_on_ready(callable, print_err:bool=true):
	_call_on_ready(PE_STRIP_CAST_SCRIPT, callable, print_err)

func _init(_node):
	pass

func _all_unregistered_callback():
	_join_thread()

func _get_ready_bool() -> bool:
	return is_node_ready()

#endregion


const GitUtil = preload("res://addons/addon_lib/brohd//alib_editor/misc/git_service/git_util.gd")
const GitDiff = preload("res://addons/addon_lib/brohd//alib_editor/misc/git_service/git_diff.gd")
const GlyphIcons = preload("res://addons/addon_lib/brohd//alib_editor/misc/git_service/glyph_icons.gd")

const MAIN_REPO = "res://"
const REFRESH_DEBOUNCE = 1.0


signal status_updated(repo_dir:String)
signal commits_updated(repo_dir:String)
signal repos_updated

## res:// paths of every repo found under the project
var repos:Array[String] = []
var current_repo:String = MAIN_REPO
## the last GitUtil.get_status() result for current_repo
var status:Dictionary = {}
## the last GitUtil.get_log() result for current_repo, newest first
var commits:Array[Dictionary] = []

var _thread:Thread
var _refresh_queued:bool = false
var _debounce_timer:Timer

# commands waiting for the worker thread, as [command, paths] — see run_command()
var _pending_commands:Array = []


func _ready() -> void:
	_debounce_timer = Timer.new()
	_debounce_timer.one_shot = true
	_debounce_timer.wait_time = REFRESH_DEBOUNCE
	_debounce_timer.timeout.connect(refresh_status)
	add_child(_debounce_timer)

	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed, 1)

	# Baking the status letters costs one rendered frame, so it starts here — the earliest point there
	# is a tree to render in, and a long way ahead of the first `git status`, which is a process spawn
	# on a worker thread. Nothing blocks on it: a row built before the bake lands draws its letter as
	# a string and is rebuilt when GlyphIcons reports in.
	_get_glyph_icons_node().warm(GitUtil.get_letter_set())

	refresh_repos()
	# fall back to the main repo if current_repo has gone away, then pull a first status
	if not current_repo in repos:
		current_repo = MAIN_REPO
	refresh_status()


func refresh_repos() -> void:
	repos = GitUtil.find_repos()
	repos_updated.emit()


func set_repo(repo_dir:String) -> void:
	if current_repo == repo_dir:
		return
	current_repo = repo_dir
	status = {}
	commits = []
	# a command queued against the old repo must not drain against the new one: its paths are res://
	# paths under the *old* root, so they would not even resolve here
	_pending_commands.clear()
	refresh_status()


func get_file_status(file_path:String) -> Dictionary:
	return status.get(GitUtil.Keys.FILES, {}).get(file_path, {})


func get_branch() -> Dictionary:
	return status.get(GitUtil.Keys.BRANCH, {})


func get_branch_oid() -> String:
	return get_branch().get(GitUtil.Keys.BRANCH_OID, "")


# Shared status-letter icons, baked once and read by the git panel's Changes list. Owned here as a
# child node — a git resource, kept with the git data provider.
static func get_glyph_icons_node():
	return get_instance()._get_glyph_icons_node()

func _get_glyph_icons_node():
	var glyph_node = get_node_or_null(NodePath(GlyphIcons.NODE_NAME))
	if not is_instance_valid(glyph_node):
		glyph_node = GlyphIcons.new()
		glyph_node.name = GlyphIcons.NODE_NAME
		add_child(glyph_node)
	return glyph_node


## Runs git off the main thread: a cold repo can take long enough to drop frames.
func refresh_status() -> void:
	_start_work()


## Queues a write for the worker thread, which then re-reads the repo in the same pass. Not run
## inline: a status that read the repo before an interleaved write would land after it and repaint
## stale rows, with nothing scheduled to correct them.
func run_command(command:GitUtil.Command, paths:Array) -> void:
	if paths.is_empty():
		return

	# resolved against the status in hand, not on the worker: by the time the thread runs, `status`
	# may already be the *next* repo's
	var expanded = GitUtil.expand_paths(command, paths, status.get(GitUtil.Keys.FILES, {}))
	_pending_commands.append([command, expanded])
	_start_work()


func _start_work() -> void:
	if is_instance_valid(_thread) and _thread.is_alive():
		# coalesce rather than pile up threads — re-run once the in flight call lands. Queued commands
		# keep their place in _pending_commands and go out with that run.
		_refresh_queued = true
		return

	_join_thread()

	var queued = _pending_commands
	_pending_commands = []

	_thread = Thread.new()
	_thread.start(_status_task.bind(current_repo, queued, _is_initial()))


# Whether the repo has no commits yet, which changes how a file is unstaged — see GitUtil.
func _is_initial() -> bool:
	return get_branch().get(GitUtil.Keys.BRANCH_INITIAL, false)


func _status_task(repo_dir:String, queued:Array, initial:bool) -> void:
	# the writes go first and the read that follows is therefore never stale with respect to them
	var errors:Array = []
	var wrote_worktree = false

	for entry in queued:
		var command:GitUtil.Command = entry[0]
		var result = GitUtil.run_command(repo_dir, command, entry[1], initial)

		if result[GitUtil.Keys.EXIT] != 0:
			errors.append("git %s failed (%s): %s" % [
				GitUtil.COMMANDS[command][GitUtil.Keys.CMD_LABEL],
				result[GitUtil.Keys.EXIT],
				"\n".join(result[GitUtil.Keys.OUTPUT]).strip_edges(),
			])
		elif GitUtil.COMMANDS[command][GitUtil.Keys.CMD_WORKTREE]:
			wrote_worktree = true

	# every git call shares the one thread, so the coalescing and stale-repo guard cover them for free
	var status_result = GitUtil.get_status(repo_dir)
	# merged in on the worker thread, so the handoff below keeps its shape and a row click costs no git
	GitUtil.attach_diffs(repo_dir, status_result)
	var log_result = GitUtil.get_log(repo_dir)
	_on_status_ready.call_deferred(repo_dir, status_result, log_result, errors, wrote_worktree)


func _on_status_ready(repo_dir:String, status_result:Dictionary, log_result:Array, errors:Array,
		wrote_worktree:bool) -> void:
	_join_thread()

	# a failed command otherwise looks exactly like one that worked, because the list simply repaints
	# the rows it already had
	for error:String in errors:
		push_error(error)

	if repo_dir == current_repo: # a repo switch mid flight leaves this result stale
		status = status_result
		commits.assign(log_result)
		status_updated.emit(repo_dir)
		commits_updated.emit(repo_dir)

	# discard and delete rewrite files behind the editor's back and nothing else will tell it: a script
	# still open on the old contents would write them straight back on the next save
	if wrote_worktree:
		EditorInterface.get_resource_filesystem().scan()

	if _refresh_queued or not _pending_commands.is_empty():
		_refresh_queued = false
		_start_work()


func _join_thread() -> void:
	if not is_instance_valid(_thread):
		return
	_thread.wait_to_finish()
	_thread = null


func _on_filesystem_changed() -> void:
	_debounce_timer.start()
